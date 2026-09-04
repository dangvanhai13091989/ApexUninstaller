// UninstallService.swift
// ApexUninstaller
//
// Hybrid approach: thử 2 phương pháp theo thứ tự ưu tiên:
// 1. NSWorkspace.recycle() — API chính thức Apple cho sandbox (batch tất cả files)
// 2. FileManager.trashItem() trong security scope — fallback cho ~/Library
//
// Kiểm tra app running, quit graceful trước khi xoá, better error messages

import Foundation
import AppKit

struct UninstallResult: Identifiable {
    let id = UUID()
    let originalPath: URL
    let trashPath: URL?
    let success: Bool
    let error: String?
    /// Loại lỗi để UI hiển thị hướng dẫn phù hợp
    let failureReason: FailureReason?
    
    init(originalPath: URL, trashPath: URL?, success: Bool, error: String?, failureReason: FailureReason? = nil) {
        self.originalPath = originalPath
        self.trashPath = trashPath
        self.success = success
        self.error = error
        self.failureReason = failureReason
    }
}

/// Lý do xoá thất bại — dùng để hiển thị hướng dẫn phù hợp cho user
enum FailureReason: Equatable {
    /// App đang chạy, không thể xoá
    case appIsRunning(appName: String)
    /// Không có quyền truy cập file/folder
    case permissionDenied
    /// Đường dẫn gốc/hệ thống bị chặn để tránh xoá nhầm
    case unsafePath
    /// File đang bị lock hoặc sử dụng bởi process khác
    case fileInUse
    /// Không tìm thấy file
    case fileNotFound
    /// Lỗi không xác định
    case unknown
    
    var userMessage: String {
        let lang = LocalizationManager.shared.currentLanguage
        switch self {
        case .appIsRunning(let name):
            return L10n.string("failure.appRunning", language: lang, name)
        case .permissionDenied:
            return L10n.string("failure.permissionDenied", language: lang)
        case .unsafePath:
            return L10n.string("failure.unsafePath", language: lang)
        case .fileInUse:
            return L10n.string("failure.fileInUse", language: lang)
        case .fileNotFound:
            return L10n.string("failure.fileNotFound", language: lang)
        case .unknown:
            return L10n.string("failure.unknown", language: lang)
        }
    }
    
    func localizedMessage(using localization: LocalizationManager) -> String {
        switch self {
        case .appIsRunning(let name):
            return localization.localized("failure.appRunning", name)
        case .permissionDenied:
            return localization.localized("failure.permissionDenied")
        case .unsafePath:
            return localization.localized("failure.unsafePath")
        case .fileInUse:
            return localization.localized("failure.fileInUse")
        case .fileNotFound:
            return localization.localized("failure.fileNotFound")
        case .unknown:
            return localization.localized("failure.unknown")
        }
    }
    
    var icon: String {
        switch self {
        case .appIsRunning: return "app.badge.fill"
        case .permissionDenied: return "lock.fill"
        case .unsafePath: return "shield.slash.fill"
        case .fileInUse: return "lock.rotation"
        case .fileNotFound: return "questionmark.folder"
        case .unknown: return "exclamationmark.triangle.fill"
        }
    }
}

enum UninstallError: LocalizedError {
    case noItemsSelected
    case appIsRunning(name: String)
    
    var errorDescription: String? {
        switch self {
        case .noItemsSelected: return "No items selected"
        case .appIsRunning(let name): return "\(name) is still running. Please quit it first."
        }
    }
}

final class UninstallService {
    
    /// Bookmark URL để access ~/Library (cho scan + fallback trashItem)
    var libraryBookmarkURL: URL?
    
    // MARK: - Kiểm tra app đang chạy
    
    /// Kiểm tra xem app có đang chạy không dựa trên bundle identifier
    func isAppRunning(bundleIdentifier: String) -> Bool {
        return NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleIdentifier
        }
    }
    
    /// Lấy running application instance
    private func runningApp(bundleIdentifier: String) -> NSRunningApplication? {
        return NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == bundleIdentifier
        }
    }
    
    /// Thử quit app một cách graceful, đợi tối đa timeout giây
    @MainActor
    func quitApp(bundleIdentifier: String, timeout: TimeInterval = 5.0) async -> Bool {
        guard let app = runningApp(bundleIdentifier: bundleIdentifier) else {
            return true // App không chạy → coi như quit thành công
        }
        
        // Thử terminate graceful
        app.terminate()
        
        // Đợi app quit
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            if !isAppRunning(bundleIdentifier: bundleIdentifier) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Uninstall chính
    
    func uninstall(app: AppInfo, includeApp: Bool, selectedLeftovers: [LeftoverFile]) async throws -> [UninstallResult] {
        if !includeApp && selectedLeftovers.isEmpty { throw UninstallError.noItemsSelected }
        
        // === Bước 1: Gom TẤT CẢ URLs (leftovers + app) vào 1 batch ===
        // Gọi NSWorkspace.recycle() 1 LẦN DUY NHẤT để tránh nhiều dialog xác nhận
        var allURLs: [URL] = selectedLeftovers.map { $0.path }
        if includeApp {
            allURLs.append(app.path)
        }
        
        let batchResults = await trashViaNSWorkspace(allURLs)
        
        // === Bước 2: Phân tách kết quả ===
        var results: [UninstallResult] = []
        
        // leftovers: index 0..<selectedLeftovers.count
        let leftoverResults = Array(batchResults.prefix(selectedLeftovers.count))
        for (index, result) in leftoverResults.enumerated() {
            if result.success {
                results.append(result)
            } else {
                // Retry bằng FileManager với security-scoped bookmark
                let (fmOK, fmErr) = trashViaFileManager(at: result.originalPath)
                let reason = classifyError(fmErr, path: result.originalPath)
                results.append(UninstallResult(
                    originalPath: selectedLeftovers[index].path, trashPath: nil,
                    success: fmOK, error: fmOK ? nil : reason.userMessage,
                    failureReason: fmOK ? nil : reason
                ))
            }
        }
        
        // app: index = selectedLeftovers.count (nếu includeApp)
        if includeApp {
            let appResult = batchResults[selectedLeftovers.count]
            if appResult.success {
                results.append(appResult)
            } else {
                // App fail → thử FileManager, nếu vẫn fail thì tạo kết quả lỗi với lý do cụ thể
                let (fmOK, _) = trashViaFileManager(at: app.path)
                if fmOK {
                    results.append(UninstallResult(originalPath: app.path, trashPath: nil, success: true, error: nil))
                } else {
                    let reason: FailureReason
                    if isAppRunning(bundleIdentifier: app.bundleIdentifier) {
                        reason = .appIsRunning(appName: app.name)
                    } else {
                        reason = .permissionDenied
                    }
                    
                    await MainActor.run {
                        NSWorkspace.shared.activateFileViewerSelecting([app.path])
                    }
                    
                    results.append(UninstallResult(
                        originalPath: app.path, trashPath: nil, success: false,
                        error: reason.userMessage,
                        failureReason: reason
                    ))
                }
            }
        }
        
        return results
    }
    
    // MARK: - Retry xoá 1 file
    
    /// Di chuyển một danh sách file vào Trash, dùng cho orphaned leftovers hoặc các module cleanup phụ.
    func trashFiles(_ urls: [URL]) async -> [UninstallResult] {
        guard !urls.isEmpty else { return [] }
        
        let batchResults = await trashViaNSWorkspace(urls)
        var results: [UninstallResult] = []
        
        for result in batchResults {
            if result.success {
                results.append(result)
            } else {
                let (fmOK, fmErr) = trashViaFileManager(at: result.originalPath)
                let reason = classifyError(fmErr, path: result.originalPath)
                results.append(UninstallResult(
                    originalPath: result.originalPath,
                    trashPath: nil,
                    success: fmOK,
                    error: fmOK ? nil : reason.userMessage,
                    failureReason: fmOK ? nil : reason
                ))
            }
        }
        
        return results
    }
    
    /// Retry xoá 1 file đã thất bại — gọi từ UI khi user nhấn "Retry"
    func retrySingleFile(at url: URL) async -> UninstallResult {
        if !FileManager.default.fileExists(atPath: url.path) {
            return alreadyRemovedResult(for: url)
        }
        
        // 1. NSWorkspace.recycle
        let batchResult = await trashViaNSWorkspace([url])
        if let first = batchResult.first, first.success {
            return first
        }
        
        // 2. FileManager
        let (fmOK, fmErr) = trashViaFileManager(at: url)
        if fmOK {
            return UninstallResult(originalPath: url, trashPath: nil, success: true, error: nil)
        }
        
        let reason = classifyError(fmErr, path: url)
        return UninstallResult(
            originalPath: url, trashPath: nil, success: false,
            error: reason.userMessage, failureReason: reason
        )
    }
    
    // MARK: - Phân loại lỗi
    
    private func classifyError(_ error: String?, path: URL) -> FailureReason {
        guard let error = error else { return .unknown }
        let lower = error.lowercased()

        if lower.contains("safety policy") {
            return .unsafePath
        }
        
        if lower.contains("permission") || lower.contains("not permitted") || lower.contains("operation not allowed") {
            return .permissionDenied
        }
        if lower.contains("in use") || lower.contains("busy") || lower.contains("locked") {
            return .fileInUse
        }
        if lower.contains("no such file") || lower.contains("not found") || lower.contains("doesn't exist") {
            return .fileNotFound
        }
        
        // Kiểm tra xem file có phải .app và đang chạy không
        if path.pathExtension == "app" {
            let appName = path.deletingPathExtension().lastPathComponent
            if let bundle = Bundle(url: path), let bid = bundle.bundleIdentifier,
               isAppRunning(bundleIdentifier: bid) {
                return .appIsRunning(appName: appName)
            }
        }
        
        return .permissionDenied // Default cho /Applications items
    }
    
    // MARK: - Phương pháp 1: NSWorkspace.recycle() (batch)
    
    /// Di chuyển tất cả URLs vào Trash bằng NSWorkspace.recycle
    /// PHẢI chạy trên main thread để hiện dialog xác nhận hệ thống
    @MainActor
    private func trashViaNSWorkspace(_ urls: [URL]) async -> [UninstallResult] {
        var immediateResults: [URL: UninstallResult] = [:]
        let existing = urls.filter { url in
            guard RemovalSafetyPolicy.canMoveToTrash(url) else {
                immediateResults[url] = UninstallResult(
                    originalPath: url,
                    trashPath: nil,
                    success: false,
                    error: RemovalSafetyPolicy.blockedMessage,
                    failureReason: .unsafePath
                )
                return false
            }

            guard FileManager.default.fileExists(atPath: url.path) else {
                immediateResults[url] = alreadyRemovedResult(for: url)
                return false
            }
            return true
        }
        
        guard !existing.isEmpty else {
            return urls.compactMap { immediateResults[$0] }
        }
        
        return await withCheckedContinuation { continuation in
            NSWorkspace.shared.recycle(existing) { newURLs, error in
                if let error = error {
                    let results = existing.map {
                        UninstallResult(originalPath: $0, trashPath: nil, success: false, error: error.localizedDescription)
                    }
                    var mapped = immediateResults
                    results.forEach { mapped[$0.originalPath] = $0 }
                    continuation.resume(returning: urls.compactMap { mapped[$0] })
                } else {
                    let results = existing.map { url in
                        UninstallResult(originalPath: url, trashPath: newURLs[url], success: true, error: nil)
                    }
                    var mapped = immediateResults
                    results.forEach { mapped[$0.originalPath] = $0 }
                    continuation.resume(returning: urls.compactMap { mapped[$0] })
                }
            }
        }
    }
    
    // MARK: - Phương pháp 2: FileManager.trashItem (security scope)
    
    /// Di chuyển file vào Trash bằng FileManager — cần security-scoped bookmark
    /// Hoạt động tốt nhất cho files trong ~/Library khi có bookmark
    private func trashViaFileManager(at url: URL) -> (success: Bool, error: String?) {
        guard RemovalSafetyPolicy.canMoveToTrash(url) else {
            return (false, RemovalSafetyPolicy.blockedMessage)
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            return (true, nil)
        }
        
        // Thử với security-scoped bookmark nếu có
        let accessStarted = libraryBookmarkURL?.startAccessingSecurityScopedResource() ?? false
        defer {
            if accessStarted { libraryBookmarkURL?.stopAccessingSecurityScopedResource() }
        }
        
        do {
            var resultURL: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &resultURL)
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    private func alreadyRemovedResult(for url: URL) -> UninstallResult {
        UninstallResult(originalPath: url, trashPath: nil, success: true, error: nil)
    }
}
