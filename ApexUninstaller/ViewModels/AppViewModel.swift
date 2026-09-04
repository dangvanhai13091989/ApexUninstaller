// AppViewModel.swift
// ApexUninstaller - IMPROVED: running app check, retry support, better error handling

import Foundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum CleanupOperation: String, Codable {
    case uninstall
    case reset
    case orphaned
    
    var localizationKey: String {
        switch self {
        case .uninstall: return "history.operation.uninstall"
        case .reset: return "history.operation.reset"
        case .orphaned: return "history.operation.orphaned"
        }
    }
}

struct CleanupHistoryEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let appName: String
    let bundleIdentifier: String
    let operation: CleanupOperation
    let removedItemCount: Int
    let failedItemCount: Int
    let reclaimedSize: UInt64
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        appName: String,
        bundleIdentifier: String,
        operation: CleanupOperation,
        removedItemCount: Int,
        failedItemCount: Int,
        reclaimedSize: UInt64
    ) {
        self.id = id
        self.date = date
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.operation = operation
        self.removedItemCount = removedItemCount
        self.failedItemCount = failedItemCount
        self.reclaimedSize = reclaimedSize
    }
}

private enum CleanupHistoryStore {
    private static let key = "ApexUninstaller.cleanupHistory"
    
    static func load() -> [CleanupHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([CleanupHistoryEntry].self, from: data) else {
            return []
        }
        return entries
    }
    
    static func save(_ entries: [CleanupHistoryEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

private enum IgnoredAppsStore {
    private static let key = "ApexUninstaller.ignoredBundleIDs"
    
    static func load() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }
    
    static func save(_ bundleIDs: Set<String>) {
        UserDefaults.standard.set(Array(bundleIDs).sorted(), forKey: key)
    }
}

enum PendingRemovalMode {
    case uninstall
    case reset
    
    var operation: CleanupOperation {
        switch self {
        case .uninstall: return .uninstall
        case .reset: return .reset
        }
    }
}

struct OrphanedLeftoverGroup: Identifiable, Hashable {
    let id: String
    let displayName: String
    var leftovers: [LeftoverFile]
    
    var totalSize: UInt64 {
        leftovers.reduce(0) { $0 + $1.size }
    }
    
    var selectedCount: Int {
        leftovers.filter(\.isSelected).count
    }
    
    var selectedSize: UInt64 {
        leftovers.filter(\.isSelected).reduce(0) { $0 + $1.size }
    }
}

@Observable @MainActor
final class AppViewModel {
    var apps: [AppInfo] = []
    var selectedAppID: UUID?
    var isScanning: Bool = false
    var scanProgress: Double = 0
    var scanningAppName: String = ""
    var isScanningLeftovers: Bool = false
    var isScanningAllLeftovers: Bool = false
    var leftoverScanCompletedCount: Int = 0
    var searchText: String = ""
    var sortOrder: AppSortOrder = .nameAsc
    var errorMessage: String?
    var errorMessageKey: String?
    var errorMessageArg: String?
    var showUninstallConfirmation: Bool = false
    var isUninstalling: Bool = false
    var uninstallResults: [UninstallResult]?
    var showUninstallResults: Bool = false
    var includeAppBundle: Bool = true
    var pendingRemovalMode: PendingRemovalMode = .uninstall
    var cleanupHistory: [CleanupHistoryEntry] = CleanupHistoryStore.load()
    var showCleanupHistory: Bool = false
    var showIgnoredApps: Bool = false
    var showSystemJunk: Bool = false
    var ignoredBundleIDs: Set<String> = IgnoredAppsStore.load()
    var orphanedGroups: [OrphanedLeftoverGroup] = []
    var isScanningOrphans: Bool = false
    var showOrphanedLeftovers: Bool = false
    
    /// Batch uninstall
    var isBatchSelectMode: Bool = false
    var batchSelectedAppIDs: Set<UUID> = []
    var showBatchUninstallConfirmation: Bool = false
    var batchUninstallProgress: String = ""
    
    /// Cảnh báo app đang chạy
    var showRunningAppWarning: Bool = false
    var runningAppName: String = ""
    
    var totalAppsSize: UInt64 { apps.reduce(0) { $0 + $1.appSize } }
    var ignoredAppCount: Int { ignoredBundleIDs.count }
    
    var totalReclaimableSize: UInt64 {
        let leftoverSize = apps.filter(\.hasScannedLeftovers).reduce(UInt64(0)) { total, app in
            total + app.leftovers.filter(\.confidence.isRecommended).reduce(0) { $0 + $1.size }
        }
        let orphanSize = orphanedGroups.reduce(UInt64(0)) { total, group in
            total + group.leftovers.filter(\.confidence.isRecommended).reduce(0) { $0 + $1.size }
        }
        return leftoverSize + orphanSize
    }
    
    var batchSelectedApps: [AppInfo] {
        apps.filter { batchSelectedAppIDs.contains($0.id) }
    }
    
    var batchUninstallTotalSize: UInt64 {
        batchSelectedApps.reduce(0) { total, app in
            let recommendedSize = app.leftovers.filter(\.confidence.isRecommended).reduce(0) { $0 + $1.size }
            return total + app.appSize + recommendedSize
        }
    }
    
    private func showError(_ key: String, arg: String? = nil) {
        errorMessageKey = key
        errorMessageArg = arg
        errorMessage = nil
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        errorMessageKey = nil
        errorMessageArg = nil
    }
    
    func resolvedErrorMessage(using localization: LocalizationManager) -> String {
        if let key = errorMessageKey {
            if let arg = errorMessageArg {
                return localization.localized(key, arg)
            }
            return localization.localized(key)
        }
        return errorMessage ?? ""
    }
    
    func clearError() {
        errorMessage = nil
        errorMessageKey = nil
        errorMessageArg = nil
    }
    
    private let scanner = ScannerService()
    let uninstaller = UninstallService()
    var bookmarkManager: BookmarkManager?
    @ObservationIgnored private var manualDeletionMonitorTask: Task<Void, Never>?
    @ObservationIgnored private var allLeftoverScanTask: Task<Void, Never>?
    
    var selectedApp: AppInfo? {
        guard let id = selectedAppID else { return nil }
        return apps.first { $0.id == id }
    }
    
    var filteredApps: [AppInfo] {
        var result = apps
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortOrder {
        case .nameAsc: result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc: result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .sizeDesc: result.sort { $0.totalSize > $1.totalSize }
        case .sizeAsc: result.sort { $0.totalSize < $1.totalSize }
        case .leftoverCount: result.sort { $0.leftovers.count > $1.leftovers.count }
        }
        return result
    }
    
    // MARK: - Scan apps
    
    func scanApplications() {
        guard !isScanning else { return }
        isScanning = true
        scanProgress = 0
        scanningAppName = ""
        apps = []
        selectedAppID = nil
        isBatchSelectMode = false
        batchSelectedAppIDs.removeAll()
        allLeftoverScanTask?.cancel()
        isScanningAllLeftovers = false
        leftoverScanCompletedCount = 0
        
        Task {
            let additionalLocations = await MainActor.run {
                self.bookmarkManager?.additionalAppLocationURLs ?? []
            }
            let result = await scanner.scanApplications(additionalLocations: additionalLocations) { [weak self] progress, name in
                Task { @MainActor in
                    self?.scanProgress = progress
                    self?.scanningAppName = name
                }
            }
            await MainActor.run {
                self.apps = result.filter { !self.ignoredBundleIDs.contains($0.bundleIdentifier) }
                self.isScanning = false
                self.scanProgress = 1.0
                self.refreshMenuBarStats()
                ScheduledScanManager.shared.markScanCompleted()
                self.scanAllLeftoversInBackground()
            }
        }
    }
    
    func importDroppedApplication(at url: URL) {
        guard url.pathExtension == "app" else {
            showError("error.dropNotApp")
            return
        }
        
        Task {
            let appInfo = await scanner.scanApplication(at: url)
            await MainActor.run {
                guard let appInfo else {
                    self.showError("error.readBundleFailed")
                    return
                }
                self.ignoredBundleIDs.remove(appInfo.bundleIdentifier)
                IgnoredAppsStore.save(self.ignoredBundleIDs)
                
                if let idx = self.apps.firstIndex(where: { $0.path == appInfo.path || $0.bundleIdentifier == appInfo.bundleIdentifier }) {
                    self.apps[idx] = appInfo
                    self.selectedAppID = appInfo.id
                } else {
                    self.apps.append(appInfo)
                    self.apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                    self.selectedAppID = appInfo.id
                }
            }
        }
    }
    
    // MARK: - Scan leftovers (gọi từ DetailView.task)
    
    func scanLeftoversIfNeeded() async {
        guard let appID = selectedAppID else { return }
        guard let idx = apps.firstIndex(where: { $0.id == appID }) else { return }
        guard !apps[idx].hasScannedLeftovers else { return }
        
        // Set trạng thái scanning
        await MainActor.run { self.isScanningLeftovers = true }
        
        let app = apps[idx]
        let libraryURL = bookmarkManager?.libraryURL
        let leftovers = await scanner.scanLeftovers(for: app, libraryURL: libraryURL)
        
        await MainActor.run {
            // Tìm lại index vì có thể đã thay đổi
            if let i = self.apps.firstIndex(where: { $0.id == appID }) {
                self.apps[i].leftovers = leftovers
                self.apps[i].hasScannedLeftovers = true
            }
            self.isScanningLeftovers = false
        }
    }
    
    func scanAllLeftoversInBackground(force: Bool = false) {
        guard !isScanningAllLeftovers else { return }
        guard let libraryURL = bookmarkManager?.libraryURL else { return }
        guard !apps.isEmpty else { return }
        
        allLeftoverScanTask?.cancel()
        isScanningAllLeftovers = true
        leftoverScanCompletedCount = 0
        
        let appIDs = apps.map(\.id)
        allLeftoverScanTask = Task { [weak self] in
            guard let self else { return }
            
            for appID in appIDs {
                if Task.isCancelled { break }
                
                guard let app = await MainActor.run(body: {
                    self.apps.first(where: { $0.id == appID })
                }) else { continue }
                
                if app.hasScannedLeftovers && !force {
                    await MainActor.run { self.leftoverScanCompletedCount += 1 }
                    continue
                }
                
                let leftovers = await self.scanner.scanLeftovers(for: app, libraryURL: libraryURL)
                
                await MainActor.run {
                    if let idx = self.apps.firstIndex(where: { $0.id == appID }) {
                        self.apps[idx].leftovers = leftovers
                        self.apps[idx].hasScannedLeftovers = true
                    }
                    self.leftoverScanCompletedCount += 1
                    self.refreshMenuBarStats()
                }
            }
            
            await MainActor.run {
                if !Task.isCancelled {
                    self.isScanningAllLeftovers = false
                    self.refreshMenuBarStats()
                    self.sendSmartCleanupNotificationsIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Leftover selection
    
    func toggleLeftover(_ leftoverID: UUID) {
        guard let appID = selectedAppID,
              let ai = apps.firstIndex(where: { $0.id == appID }),
              let li = apps[ai].leftovers.firstIndex(where: { $0.id == leftoverID }) else { return }
        apps[ai].leftovers[li].isSelected.toggle()
    }
    
    func selectAllLeftovers() {
        guard let appID = selectedAppID, let ai = apps.firstIndex(where: { $0.id == appID }) else { return }
        for i in apps[ai].leftovers.indices { apps[ai].leftovers[i].isSelected = true }
    }
    
    func selectRecommendedLeftovers() {
        guard let appID = selectedAppID, let ai = apps.firstIndex(where: { $0.id == appID }) else { return }
        for i in apps[ai].leftovers.indices {
            apps[ai].leftovers[i].isSelected = apps[ai].leftovers[i].confidence.isRecommended
        }
    }
    
    func deselectAllLeftovers() {
        guard let appID = selectedAppID, let ai = apps.firstIndex(where: { $0.id == appID }) else { return }
        for i in apps[ai].leftovers.indices { apps[ai].leftovers[i].isSelected = false }
    }
    
    // MARK: - Orphaned leftovers
    
    var selectedOrphanedCount: Int {
        orphanedGroups.reduce(0) { $0 + $1.selectedCount }
    }
    
    var selectedOrphanedSize: UInt64 {
        orphanedGroups.reduce(0) { $0 + $1.selectedSize }
    }
    
    func openOrphanedLeftovers() {
        showOrphanedLeftovers = true
        if orphanedGroups.isEmpty {
            scanOrphanedLeftovers()
        }
    }
    
    func scanOrphanedLeftovers() {
        guard !isScanningOrphans else { return }
        guard let libraryURL = bookmarkManager?.libraryURL else {
            showError("error.libraryRequired")
            return
        }
        
        isScanningOrphans = true
        Task {
            let groups = await scanner.scanOrphanedLeftovers(installedApps: apps, libraryURL: libraryURL)
            await MainActor.run {
                self.orphanedGroups = groups
                self.isScanningOrphans = false
                self.refreshMenuBarStats()
            }
        }
    }
    
    func toggleOrphanedLeftover(groupID: String, leftoverID: UUID) {
        guard let gi = orphanedGroups.firstIndex(where: { $0.id == groupID }),
              let li = orphanedGroups[gi].leftovers.firstIndex(where: { $0.id == leftoverID }) else { return }
        orphanedGroups[gi].leftovers[li].isSelected.toggle()
    }
    
    func selectRecommendedOrphans() {
        for gi in orphanedGroups.indices {
            for li in orphanedGroups[gi].leftovers.indices {
                orphanedGroups[gi].leftovers[li].isSelected = orphanedGroups[gi].leftovers[li].confidence.isRecommended
            }
        }
    }
    
    func selectAllOrphans() {
        for gi in orphanedGroups.indices {
            for li in orphanedGroups[gi].leftovers.indices {
                orphanedGroups[gi].leftovers[li].isSelected = true
            }
        }
    }
    
    func deselectAllOrphans() {
        for gi in orphanedGroups.indices {
            for li in orphanedGroups[gi].leftovers.indices {
                orphanedGroups[gi].leftovers[li].isSelected = false
            }
        }
    }
    
    func performOrphanedCleanup() {
        let selected = orphanedGroups.flatMap(\.leftovers).filter(\.isSelected)
        guard !selected.isEmpty else {
            showError("error.noOrphansSelected")
            return
        }
        
        isUninstalling = true
        uninstaller.libraryBookmarkURL = bookmarkManager?.libraryURL
        let sizeByPath = Dictionary(uniqueKeysWithValues: selected.map { ($0.path, $0.size) })
        
        Task {
            let results = await uninstaller.trashFiles(selected.map(\.path))
            await MainActor.run {
                let removed = Set(results.filter(\.success).map(\.originalPath))
                for gi in self.orphanedGroups.indices {
                    self.orphanedGroups[gi].leftovers.removeAll { removed.contains($0.path) }
                }
                self.orphanedGroups.removeAll { $0.leftovers.isEmpty }
                self.refreshMenuBarStats()
                self.recordCleanupHistory(
                    appName: "Orphaned Leftovers",
                    bundleIdentifier: "orphaned.leftovers",
                    operation: .orphaned,
                    results: results,
                    sizeByPath: sizeByPath
                )
                self.uninstallResults = results
                self.isUninstalling = false
                self.showOrphanedLeftovers = false
                self.showUninstallResults = true
            }
        }
    }
    
    // MARK: - Uninstall
    
    /// ID của app đã xoá thành công — dùng để cleanup sau khi dismiss results sheet
    var uninstalledAppIDs: Set<UUID> = []
    
    /// Kiểm tra app đang chạy trước khi xoá
    func checkAndUninstall() {
        guard let app = selectedApp else { return }
        pendingRemovalMode = .uninstall
        
        // Kiểm tra app đang chạy
        if includeAppBundle && uninstaller.isAppRunning(bundleIdentifier: app.bundleIdentifier) {
            runningAppName = app.name
            showRunningAppWarning = true
            return
        }
        
        // App không chạy → hỏi xác nhận
        showUninstallConfirmation = true
    }
    
    func checkAndReset() {
        guard selectedApp != nil else { return }
        pendingRemovalMode = .reset
        includeAppBundle = false
        selectRecommendedLeftovers()
        
        guard selectedApp?.selectedLeftoverCount ?? 0 > 0 else {
            showError("error.noResetSelected")
            return
        }
        
        showUninstallConfirmation = true
    }
    
    /// Quit app bằng yêu cầu graceful rồi tiếp tục xác nhận uninstall
    func quitAndConfirmUninstall() {
        guard let app = selectedApp else { return }
        
        Task {
            let didQuit = await uninstaller.quitApp(bundleIdentifier: app.bundleIdentifier)
            await MainActor.run {
                if didQuit {
                    self.showUninstallConfirmation = true
                } else {
                    self.showError("error.appDidNotQuit", arg: app.name)
                }
            }
        }
    }
    
    func performUninstall() {
        guard let app = selectedApp else { return }
        let selected = app.leftovers.filter { $0.isSelected }
        isUninstalling = true
        uninstaller.libraryBookmarkURL = bookmarkManager?.libraryURL
        let operation = pendingRemovalMode.operation
        let sizeByPath = Dictionary(uniqueKeysWithValues: selected.map { ($0.path, $0.size) } + [(app.path, app.appSize)])
        
        Task {
            do {
                let results = try await uninstaller.uninstall(
                    app: app, includeApp: includeAppBundle, selectedLeftovers: selected
                )
                await MainActor.run {
                    self.uninstallResults = results
                    self.isUninstalling = false
                    self.recordCleanupHistory(
                        appName: app.name,
                        bundleIdentifier: app.bundleIdentifier,
                        operation: operation,
                        results: results,
                        sizeByPath: sizeByPath
                    )
                    
                    // Nếu app bundle bị xoá thành công → đánh dấu để cleanup sau
                    if results.contains(where: { $0.originalPath == app.path && $0.success }) {
                        self.uninstalledAppIDs.insert(app.id)
                    } else if let i = self.apps.firstIndex(where: { $0.id == app.id }) {
                        // Chỉ xoá leftovers đã xoá thành công
                        let ok = Set(results.filter { $0.success }.map { $0.originalPath })
                        self.apps[i].leftovers.removeAll { ok.contains($0.path) }
                    }
                    self.startManualDeletionMonitor(for: app)
                    
                    // Hiện sheet kết quả NGAY (app vẫn còn trong list)
                    self.showUninstallResults = true
                }
            } catch {
                await MainActor.run {
                    if let uninstallError = error as? UninstallError {
                        switch uninstallError {
                        case .noItemsSelected:
                            self.showError("error.noItemsSelected")
                        case .appIsRunning(let name):
                            self.showError("error.appStillRunning", arg: name)
                        }
                    } else {
                        self.showErrorMessage(error.localizedDescription)
                    }
                    self.isUninstalling = false
                }
            }
        }
    }
    
    // MARK: - Retry failed item
    
    /// Retry xoá 1 file đã thất bại
    func retryFailedItem(at url: URL) {
        Task {
            let result = await uninstaller.retrySingleFile(at: url)
            await MainActor.run {
                guard var results = self.uninstallResults else { return }
                // Tìm và thay thế result cũ
                if let idx = results.firstIndex(where: { $0.originalPath == url }) {
                    results[idx] = result
                    self.uninstallResults = results
                    
                    // Nếu retry thành công và là app bundle → đánh dấu
                    if result.success, let app = self.selectedApp, result.originalPath == app.path {
                        self.uninstalledAppIDs.insert(app.id)
                    }
                    
                    // Nếu retry thành công leftover → remove khỏi list
                    if result.success, let appID = self.selectedAppID,
                       let ai = self.apps.firstIndex(where: { $0.id == appID }) {
                        self.apps[ai].leftovers.removeAll { $0.path == url }
                    }
                }
            }
        }
    }
    
    /// Gọi khi user dismiss results sheet — cleanup app đã xoá
    func cleanupAfterUninstall() {
        showUninstallResults = false
        manualDeletionMonitorTask?.cancel()
        manualDeletionMonitorTask = nil
        
        if uninstalledAppIDs.isEmpty, let app = selectedApp,
           !FileManager.default.fileExists(atPath: app.path.path) {
            uninstalledAppIDs.insert(app.id)
        }
        
        if !uninstalledAppIDs.isEmpty {
            apps.removeAll { uninstalledAppIDs.contains($0.id) }
            batchSelectedAppIDs.subtract(uninstalledAppIDs)
            if let selected = selectedAppID, uninstalledAppIDs.contains(selected) {
                selectedAppID = nil
            }
            uninstalledAppIDs.removeAll()
            if batchSelectedAppIDs.isEmpty {
                isBatchSelectMode = false
            }
            refreshMenuBarStats()
        }
    }
    
    // MARK: - Batch uninstall
    
    func toggleBatchSelectMode() {
        isBatchSelectMode.toggle()
        if !isBatchSelectMode {
            batchSelectedAppIDs.removeAll()
        }
    }
    
    func toggleBatchAppSelection(_ appID: UUID) {
        if batchSelectedAppIDs.contains(appID) {
            batchSelectedAppIDs.remove(appID)
        } else {
            batchSelectedAppIDs.insert(appID)
        }
    }
    
    func selectAllBatchApps() {
        batchSelectedAppIDs = Set(filteredApps.map(\.id))
    }
    
    func deselectAllBatchApps() {
        batchSelectedAppIDs.removeAll()
    }
    
    func checkAndBatchUninstall() {
        guard !batchSelectedAppIDs.isEmpty else {
            showError("error.batch.noneSelected")
            return
        }
        
        if isScanningAllLeftovers || batchSelectedApps.contains(where: { !$0.hasScannedLeftovers }) {
            showError("error.batch.notScanned")
            return
        }
        
        showBatchUninstallConfirmation = true
    }
    
    func performBatchUninstall() {
        let appsToUninstall = batchSelectedApps
        guard !appsToUninstall.isEmpty else { return }
        
        isUninstalling = true
        batchUninstallProgress = appsToUninstall[0].name
        uninstaller.libraryBookmarkURL = bookmarkManager?.libraryURL
        
        Task {
            var allResults: [UninstallResult] = []
            var removedAppIDs: Set<UUID> = []
            
            for app in appsToUninstall {
                await MainActor.run {
                    self.batchUninstallProgress = app.name
                }
                
                let selected = app.leftovers.filter(\.confidence.isRecommended)
                let sizeByPath = Dictionary(uniqueKeysWithValues: selected.map { ($0.path, $0.size) } + [(app.path, app.appSize)])
                
                do {
                    let results = try await uninstaller.uninstall(
                        app: app, includeApp: true, selectedLeftovers: selected
                    )
                    allResults.append(contentsOf: results)
                    
                    await MainActor.run {
                        self.recordCleanupHistory(
                            appName: app.name,
                            bundleIdentifier: app.bundleIdentifier,
                            operation: .uninstall,
                            results: results,
                            sizeByPath: sizeByPath
                        )
                    }
                    
                    if results.contains(where: { $0.originalPath == app.path && $0.success }) {
                        removedAppIDs.insert(app.id)
                    }
                } catch {
                    // Record failed app for user feedback
                    let errorResult = UninstallResult(
                        originalPath: app.path,
                        trashPath: nil,
                        success: false,
                        error: error.localizedDescription
                    )
                    allResults.append(errorResult)
                    continue
                }
            }
            
            await MainActor.run {
                self.uninstallResults = allResults
                self.uninstalledAppIDs = removedAppIDs
                self.isUninstalling = false
                self.batchUninstallProgress = ""
                self.showBatchUninstallConfirmation = false
                self.refreshMenuBarStats()
                self.showUninstallResults = true
            }
        }
    }
    
    func clearCleanupHistory() {
        cleanupHistory = []
        CleanupHistoryStore.clear()
    }
    
    // MARK: - Ignore list
    
    func ignoreSelectedApp() {
        guard let app = selectedApp else { return }
        ignoredBundleIDs.insert(app.bundleIdentifier)
        IgnoredAppsStore.save(ignoredBundleIDs)
        apps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
        selectedAppID = nil
    }
    
    func restoreIgnoredApp(bundleIdentifier: String) {
        ignoredBundleIDs.remove(bundleIdentifier)
        IgnoredAppsStore.save(ignoredBundleIDs)
        scanApplications()
    }
    
    func clearIgnoredApps() {
        ignoredBundleIDs.removeAll()
        IgnoredAppsStore.save(ignoredBundleIDs)
        scanApplications()
    }
    
    // MARK: - Export report
    
    @MainActor
    func exportSelectedAppReport(localization: LocalizationManager) {
        guard let app = selectedApp else { return }
        let panel = NSSavePanel()
        panel.title = localization.localized("export.panelTitle")
        panel.nameFieldStringValue = "ApexUninstaller-\(safeFilename(app.name))-Report.txt"
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        do {
            try appReport(for: app).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    /// Mở file trong Finder
    func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    private func safeFilename(_ value: String) -> String {
        value
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_")).inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
    
    private func appReport(for app: AppInfo) -> String {
        var lines: [String] = []
        lines.append("ApexUninstaller Cleanup Report")
        lines.append("Generated: \(Date().formatted(date: .complete, time: .standard))")
        lines.append("")
        lines.append("Application")
        lines.append("Name: \(app.name)")
        lines.append("Bundle ID: \(app.bundleIdentifier)")
        lines.append("Path: \(app.path.path)")
        lines.append("Version: \(app.version)")
        if let buildVersion = app.buildVersion { lines.append("Build: \(buildVersion)") }
        if let minimumSystemVersion = app.minimumSystemVersion { lines.append("Minimum macOS: \(minimumSystemVersion)") }
        if let lastModified = app.lastModified {
            lines.append("Last Modified: \(lastModified.formatted(date: .complete, time: .standard))")
        }
        lines.append("Source: \(app.installSource == .appStore ? "Mac App Store" : "Outside App Store")")
        lines.append("App Size: \(app.appSize.formattedSize)")
        lines.append("")
        lines.append("Leftovers")
        lines.append("Total Items: \(app.leftovers.count)")
        lines.append("Recommended Items: \(app.recommendedLeftoverCount)")
        lines.append("Review Items: \(app.reviewRequiredLeftoverCount)")
        lines.append("Selected Items: \(app.selectedLeftoverCount)")
        lines.append("Selected Size: \(app.selectedLeftoverSize.formattedSize)")
        lines.append("")
        
        for category in LeftoverCategory.allCases {
            let items = app.leftovers.filter { $0.category == category }
            guard !items.isEmpty else { continue }
            lines.append("[\(category.rawValue)]")
            for item in items {
                lines.append("- \(item.isSelected ? "[x]" : "[ ]") \(item.displayName)")
                lines.append("  Path: \(item.path.path)")
                lines.append("  Size: \(item.size.formattedSize)")
                lines.append("  Confidence: \(item.confidence.rawValue)")
                if !item.matchReason.isEmpty { lines.append("  Match: \(item.matchReason)") }
            }
            lines.append("")
        }
        
        lines.append("Removal mode: items are moved to Trash, not permanently deleted.")
        return lines.joined(separator: "\n")
    }
    
    private func recordCleanupHistory(
        appName: String,
        bundleIdentifier: String,
        operation: CleanupOperation,
        results: [UninstallResult],
        sizeByPath: [URL: UInt64]
    ) {
        let removed = results.filter(\.success)
        guard !removed.isEmpty else { return }
        
        let reclaimedSize = removed.reduce(UInt64(0)) { total, result in
            total + (sizeByPath[result.originalPath] ?? 0)
        }
        
        let entry = CleanupHistoryEntry(
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            operation: operation,
            removedItemCount: removed.count,
            failedItemCount: results.filter { !$0.success }.count,
            reclaimedSize: reclaimedSize
        )
        
        cleanupHistory.insert(entry, at: 0)
        if cleanupHistory.count > 80 {
            cleanupHistory.removeLast(cleanupHistory.count - 80)
        }
        CleanupHistoryStore.save(cleanupHistory)
        refreshMenuBarStats()
    }
    
    private func startManualDeletionMonitor(for app: AppInfo) {
        manualDeletionMonitorTask?.cancel()
        
        guard includeAppBundle,
              uninstallResults?.contains(where: { $0.originalPath == app.path && !$0.success }) == true else {
            return
        }
        
        manualDeletionMonitorTask = Task { [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                let shouldContinue = await MainActor.run {
                    self.showUninstallResults && self.uninstalledAppIDs.isEmpty
                }
                guard shouldContinue else { return }
                
                guard !FileManager.default.fileExists(atPath: app.path.path) else { continue }
                
                await MainActor.run {
                    guard var results = self.uninstallResults,
                          let idx = results.firstIndex(where: { $0.originalPath == app.path }) else { return }
                    
                    results[idx] = UninstallResult(originalPath: app.path, trashPath: nil, success: true, error: nil)
                    self.uninstallResults = results
                    self.uninstalledAppIDs.insert(app.id)
                }
                return
            }
        }
    }

    private func refreshMenuBarStats() {
        UserDefaults.standard.set(clampedInt(totalReclaimableSize), forKey: "ApexUninstaller.lastReclaimableSize")
        let orphanCount = orphanedGroups.reduce(0) { $0 + $1.leftovers.count }
        UserDefaults.standard.set(orphanCount, forKey: "ApexUninstaller.lastOrphanCount")
    }

    private func sendSmartCleanupNotificationsIfNeeded() {
        let appsWithRecommendedLeftovers = apps.filter { app in
            app.leftovers.contains { $0.confidence.isRecommended }
        }
        SmartNotificationService.shared.sendJunkReminder(
            totalJunk: totalReclaimableSize,
            appCount: appsWithRecommendedLeftovers.count
        )

        for app in apps where app.leftoverSize >= 1024 * 1024 * 1024 {
            SmartNotificationService.shared.sendLargeLeftoverAlert(appName: app.name, size: app.leftoverSize)
        }
    }

    private func clampedInt(_ value: UInt64) -> Int {
        Int(min(value, UInt64(Int.max)))
    }
}
