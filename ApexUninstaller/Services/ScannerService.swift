// ScannerService.swift
// ApexUninstaller
// Service quét ứng dụng và tìm file rác. Tối ưu tốc độ scan.

import Foundation
import AppKit

actor ScannerService {
    private let fileManager = FileManager.default
    
    private struct AppMatchProfile {
        let bundleID: String
        let bundleIDLower: String
        let hasReliableBundleID: Bool
        let appName: String
        let normalizedAppName: String
        let normalizedFolderName: String
        let normalizedExecutableName: String?
        let vendorToken: String?
        let productToken: String?
    }
    
    private struct LeftoverMatch {
        let confidence: LeftoverConfidence
        let reason: String
    }
    
    private struct OrphanCandidate {
        let id: String
        let displayName: String
        let confidence: LeftoverConfidence
        let reason: String
    }

    private struct AppSearchRoot {
        let url: URL
        let maxDepth: Int
    }
    
    // MARK: - Quét ứng dụng
    func scanApplications(
        additionalLocations: [URL] = [],
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async -> [AppInfo] {
        var apps: [AppInfo] = []
        var allAppURLs: [URL] = []

        for root in appSearchRoots(additionalLocations: additionalLocations) {
            allAppURLs.append(contentsOf: findApps(in: root.url, maxDepth: root.maxDepth))
        }

        // Loại bỏ duplicate (cùng một app có thể xuất hiện qua symlink hoặc nhiều root search).
        allAppURLs = deduplicateAppURLs(allAppURLs)
        
        let total = allAppURLs.count
        guard total > 0 else { return [] }
        
        for (index, appURL) in allAppURLs.enumerated() {
            let progress = Double(index + 1) / Double(total)
            let name = appURL.deletingPathExtension().lastPathComponent
            await MainActor.run { progressHandler(progress, name) }
            if let appInfo = scanSingleApp(at: appURL) { apps.append(appInfo) }
        }
        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    /// Tìm tất cả .app trong một thư mục với giới hạn độ sâu.
    /// Vị trí ngoài chuẩn chỉ được quét sau khi user cấp quyền qua NSOpenPanel.
    private func findApps(in directory: URL, maxDepth: Int = 2, currentDepth: Int = 0) -> [URL] {
        var appURLs: [URL] = []
        
        guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return appURLs
        }
        
        for itemURL in contents {
            let itemName = itemURL.lastPathComponent
            
            // Skip hidden and system/build directories
            if shouldSkipAppSearchDirectory(named: itemName) {
                continue
            }
            
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDir) else { continue }
            
            if itemURL.pathExtension == "app" {
                // Trực tiếp là .app
                appURLs.append(itemURL)
            } else if isDir.boolValue, currentDepth < maxDepth {
                appURLs.append(contentsOf: findApps(in: itemURL, maxDepth: maxDepth, currentDepth: currentDepth + 1))
            }
        }
        
        return appURLs
    }

    private func appSearchRoots(additionalLocations: [URL]) -> [AppSearchRoot] {
        var roots: [AppSearchRoot] = []
        var seen: Set<String> = []

        func appendIfExists(_ url: URL, maxDepth: Int) {
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue,
                  fileManager.isReadableFile(atPath: url.path) else { return }
            let key = url.standardizedFileURL.resolvingSymlinksInPath().path
            guard seen.insert(key).inserted else { return }
            roots.append(AppSearchRoot(url: url, maxDepth: maxDepth))
        }

        appendIfExists(URL(fileURLWithPath: "/Applications", isDirectory: true), maxDepth: 3)
        appendIfExists(realUserHomeDirectory.appendingPathComponent("Applications", isDirectory: true), maxDepth: 3)

        for location in additionalLocations {
            appendIfExists(location, maxDepth: 8)
        }

        return roots
    }

    private func shouldSkipAppSearchDirectory(named name: String) -> Bool {
        if name.hasPrefix(".") { return true }
        let skipped = [
            "Utilities", "System", "Library", "Users", "Volumes",
            "node_modules", "DerivedData", "build", ".git"
        ]
        return skipped.contains(name)
    }

    private func deduplicateAppURLs(_ urls: [URL]) -> [URL] {
        var seenPaths: Set<String> = []
        return urls.filter { url in
            let key = url.standardizedFileURL.resolvingSymlinksInPath().path
            guard !seenPaths.contains(key) else { return false }
            seenPaths.insert(key)
            return true
        }
    }
    
    private func scanSingleApp(at url: URL) -> AppInfo? {
        guard let bundle = Bundle(url: url) else { return nil }
        let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? url.deletingPathExtension().lastPathComponent
        let bundleID = bundle.bundleIdentifier ?? "unknown.\(name.lowercased().replacingOccurrences(of: " ", with: "."))"
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        // Dùng lightweight size check - không recursive scan toàn bộ app
        let appSize = quickDirectorySize(at: url)
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "Unknown"
        let buildVersion = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let minimumSystemVersion = bundle.object(forInfoDictionaryKey: "LSMinimumSystemVersion") as? String
            ?? bundle.object(forInfoDictionaryKey: "MinimumOSVersion") as? String
        let lastModified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        let receiptURL = url.appendingPathComponent("Contents/_MASReceipt/receipt")
        let source: AppInstallSource = fileManager.fileExists(atPath: receiptURL.path) ? .appStore : .external
        
        return AppInfo(
            name: name,
            bundleIdentifier: bundleID,
            path: url,
            icon: icon,
            appSize: appSize,
            version: version,
            buildVersion: buildVersion,
            minimumSystemVersion: minimumSystemVersion,
            lastModified: lastModified,
            installSource: source
        )
    }
    
    func scanApplication(at url: URL) async -> AppInfo? {
        scanSingleApp(at: url)
    }
    
    // MARK: - Quét leftovers (NHANH)
    func scanLeftovers(for app: AppInfo, libraryURL: URL?) async -> [LeftoverFile] {
        var leftovers: [LeftoverFile] = []
        let libURL: URL
        if let granted = libraryURL {
            libURL = granted
        } else {
            libURL = realUserHomeDirectory.appendingPathComponent("Library", isDirectory: true)
        }
        
        let profile = buildMatchProfile(for: app)
        
        // Quét song song tất cả categories
        for category in LeftoverCategory.allCases {
            let categoryURL = libURL.appendingPathComponent(category.librarySubpath)
            
            // Skip nhanh nếu folder không tồn tại
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: categoryURL.path, isDirectory: &isDir), isDir.boolValue else { continue }
            
            // Chỉ list level 1 - KHÔNG recursive
            guard let contents = try? fileManager.contentsOfDirectory(at: categoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { continue }
            
            for itemURL in contents {
                let itemName = itemURL.lastPathComponent
                if isSystemFile(itemName) { continue }
                if let match = matchLeftover(itemName: itemName, category: category, profile: profile) {
                    // Quick size - chỉ tính level 1 items, không deep scan
                    let size = quickDirectorySize(at: itemURL)
                    leftovers.append(LeftoverFile(
                        path: itemURL,
                        size: size,
                        category: category,
                        confidence: match.confidence,
                        matchReason: match.reason
                    ))
                }
            }
        }
        return leftovers.sorted {
            if $0.confidence != $1.confidence {
                return confidenceSortValue($0.confidence) < confidenceSortValue($1.confidence)
            }
            return $0.size > $1.size
        }
    }
    
    // MARK: - Orphaned leftovers
    
    func scanOrphanedLeftovers(installedApps: [AppInfo], libraryURL: URL?) async -> [OrphanedLeftoverGroup] {
        var groups: [String: OrphanedLeftoverGroup] = [:]
        let libURL = libraryURL ?? realUserHomeDirectory.appendingPathComponent("Library", isDirectory: true)
        let installedBundleIDs = Set(installedApps.map { $0.bundleIdentifier.lowercased() })
        let installedNames = Set(installedApps.map { normalizeName($0.name) })
        
        for category in LeftoverCategory.allCases {
            let categoryURL = libURL.appendingPathComponent(category.librarySubpath)
            
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: categoryURL.path, isDirectory: &isDir), isDir.boolValue else { continue }
            guard let contents = try? fileManager.contentsOfDirectory(at: categoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { continue }
            
            for itemURL in contents {
                let itemName = itemURL.lastPathComponent
                if isSystemFile(itemName) { continue }
                guard let candidate = orphanCandidate(
                    itemName: itemName,
                    category: category,
                    installedBundleIDs: installedBundleIDs,
                    installedNames: installedNames
                ) else { continue }
                
                let size = quickDirectorySize(at: itemURL)
                let leftover = LeftoverFile(
                    path: itemURL,
                    size: size,
                    category: category,
                    confidence: candidate.confidence,
                    matchReason: candidate.reason
                )
                
                var group = groups[candidate.id] ?? OrphanedLeftoverGroup(
                    id: candidate.id,
                    displayName: candidate.displayName,
                    leftovers: []
                )
                group.leftovers.append(leftover)
                groups[candidate.id] = group
            }
        }
        
        return groups.values
            .map { group in
                var sorted = group
                sorted.leftovers.sort {
                    if $0.confidence != $1.confidence {
                        return confidenceSortValue($0.confidence) < confidenceSortValue($1.confidence)
                    }
                    return $0.size > $1.size
                }
                return sorted
            }
            .sorted { $0.totalSize > $1.totalSize }
    }
    
    private func buildMatchProfile(for app: AppInfo) -> AppMatchProfile {
        let bundleID = app.bundleIdentifier
        let bundleIDLower = bundleID.lowercased()
        let hasReliableBundleID = !bundleIDLower.hasPrefix("unknown.")
        let components = bundleID
            .split(separator: ".")
            .map { normalizeToken(String($0)) }
            .filter { !$0.isEmpty && !genericBundlePrefixes.contains($0) }
        
        let productToken = components.last.flatMap { isSpecificToken($0) ? $0 : nil }
        let vendorToken = components.dropLast().first(where: { isSpecificToken($0) })
        
        var executableName: String?
        if let bundle = Bundle(url: app.path),
           let execName = bundle.object(forInfoDictionaryKey: "CFBundleExecutable") as? String {
            executableName = normalizeName(execName)
        }
        
        return AppMatchProfile(
            bundleID: bundleID,
            bundleIDLower: bundleIDLower,
            hasReliableBundleID: hasReliableBundleID,
            appName: app.name,
            normalizedAppName: normalizeName(app.name),
            normalizedFolderName: normalizeName(app.path.deletingPathExtension().lastPathComponent),
            normalizedExecutableName: executableName,
            vendorToken: vendorToken,
            productToken: productToken
        )
    }
    
    private func matchLeftover(itemName: String, category: LeftoverCategory, profile: AppMatchProfile) -> LeftoverMatch? {
        let lowerName = itemName.lowercased()
        let stem = (itemName as NSString).deletingPathExtension
        let stemLower = stem.lowercased()
        let normalizedItem = normalizeName(stem)
        let normalizedFullName = normalizeName(itemName)
        
        if profile.hasReliableBundleID {
            if lowerName == profile.bundleIDLower || stemLower == profile.bundleIDLower {
                return LeftoverMatch(confidence: .high, reason: "Exact Bundle ID match")
            }
            if lowerName.hasPrefix(profile.bundleIDLower + ".") || stemLower.hasPrefix(profile.bundleIDLower + ".") {
                return LeftoverMatch(confidence: .high, reason: "Bundle ID prefix match")
            }
        }
        
        switch category {
        case .preferences:
            if profile.hasReliableBundleID && lowerName == "\(profile.bundleIDLower).plist" {
                return LeftoverMatch(confidence: .high, reason: "Preference file matches Bundle ID")
            }
        case .containers:
            if profile.hasReliableBundleID && lowerName == profile.bundleIDLower {
                return LeftoverMatch(confidence: .high, reason: "Container matches Bundle ID")
            }
        case .savedState:
            if profile.hasReliableBundleID,
               lowerName == "\(profile.bundleIDLower).savedstate" || stemLower == profile.bundleIDLower {
                return LeftoverMatch(confidence: .high, reason: "Saved state matches Bundle ID")
            }
        case .launchAgents:
            if profile.hasReliableBundleID,
               stemLower == profile.bundleIDLower || stemLower.hasPrefix(profile.bundleIDLower + ".") {
                return LeftoverMatch(confidence: .high, reason: "Launch agent matches Bundle ID")
            }
        case .applicationSupport, .caches, .logs:
            break
        }
        
        let exactNames = [
            profile.normalizedAppName,
            profile.normalizedFolderName,
            profile.normalizedExecutableName
        ].compactMap { $0 }.filter { $0.count >= 3 && isSpecificPhrase($0) }
        
        if exactNames.contains(normalizedItem) {
            let confidence: LeftoverConfidence = category == .logs ? .medium : .high
            return LeftoverMatch(confidence: confidence, reason: "Exact app name match")
        }
        
        if containsPhrase(normalizedFullName, phrase: profile.normalizedAppName),
           isSpecificPhrase(profile.normalizedAppName) {
            return LeftoverMatch(confidence: .medium, reason: "App name appears in item name")
        }
        
        if let executableName = profile.normalizedExecutableName,
           containsPhrase(normalizedFullName, phrase: executableName),
           isSpecificPhrase(executableName) {
            return LeftoverMatch(confidence: .medium, reason: "Executable name appears in item name")
        }
        
        if let productToken = profile.productToken,
           containsWord(normalizedFullName, word: productToken) {
            if let vendorToken = profile.vendorToken, containsWord(normalizedFullName, word: vendorToken) {
                return LeftoverMatch(confidence: .high, reason: "Vendor and product identifiers match")
            }
            return LeftoverMatch(confidence: .medium, reason: "Product identifier match")
        }
        
        if let productToken = profile.productToken,
           normalizedFullName.contains(productToken) {
            return LeftoverMatch(confidence: .review, reason: "Weak product name match")
        }
        
        return nil
    }
    
    private func isSystemFile(_ name: String) -> Bool {
        let prefixes = ["com.apple.", "Apple", ".com.apple.", "SystemUIServer", "loginwindow", "Dock", "Finder", "SystemPreferences"]
        for p in prefixes { if name.hasPrefix(p) || name == p { return true } }
        let critical = ["CloudDocs", "FrontBoard", "StatusKit", "Knowledge", "CoreDuet", "BiomeAgent", "CallHistoryDB", "AddressBook"]
        return critical.contains(name)
    }
    
    private func orphanCandidate(
        itemName: String,
        category: LeftoverCategory,
        installedBundleIDs: Set<String>,
        installedNames: Set<String>
    ) -> OrphanCandidate? {
        let stem = normalizedStem(for: itemName, category: category)
        let lowerStem = stem.lowercased()
        
        if let identifier = reverseDomainIdentifier(from: lowerStem),
           !isCoveredByInstalledApp(identifier: identifier, installedBundleIDs: installedBundleIDs) {
            return OrphanCandidate(
                id: "bundle:\(identifier)",
                displayName: readableBundleName(identifier),
                confidence: .medium,
                reason: "Bundle ID is not installed"
            )
        }
        
        // Folder-name orphan detection is intentionally conservative. These items
        // are never selected by default because app names are less precise than bundle IDs.
        guard category == .applicationSupport || category == .caches || category == .logs else {
            return nil
        }
        
        let normalizedName = normalizeName(stem)
        guard isSpecificPhrase(normalizedName),
              !installedNames.contains(normalizedName),
              !genericProductTokens.contains(normalizedName) else {
            return nil
        }
        
        return OrphanCandidate(
            id: "name:\(normalizedName)",
            displayName: stem,
            confidence: .review,
            reason: "No installed app with this name"
        )
    }
    
    private func normalizedStem(for itemName: String, category: LeftoverCategory) -> String {
        var stem = (itemName as NSString).deletingPathExtension
        if category == .savedState, itemName.lowercased().hasSuffix(".savedstate") {
            stem = String(itemName.dropLast(".savedState".count))
        }
        return stem
    }
    
    private func reverseDomainIdentifier(from value: String) -> String? {
        let components = value
            .split(separator: ".")
            .map { normalizeToken(String($0)) }
            .filter { !$0.isEmpty }
        
        guard components.count >= 3,
              let first = components.first,
              genericBundlePrefixes.contains(first),
              components.dropFirst().contains(where: { isSpecificToken($0) }) else {
            return nil
        }
        
        return components.joined(separator: ".")
    }
    
    private func isCoveredByInstalledApp(identifier: String, installedBundleIDs: Set<String>) -> Bool {
        installedBundleIDs.contains(where: { installed in
            identifier == installed ||
            identifier.hasPrefix(installed + ".") ||
            installed.hasPrefix(identifier + ".")
        })
    }
    
    private func readableBundleName(_ identifier: String) -> String {
        let parts = identifier.split(separator: ".").map(String.init)
        let nameParts = parts.suffix(2)
        return nameParts
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    
    
    private var genericBundlePrefixes: Set<String> {
        ["com", "org", "net", "io", "app", "me", "co", "de", "uk", "jp", "kr"]
    }
    
    private var genericProductTokens: Set<String> {
        [
            "app", "apps", "application", "helper", "installer", "launcher", "desktop",
            "manager", "client", "service", "services", "agent", "daemon", "software",
            "update", "updater", "setup", "tool", "tools", "utility", "utilities",
            "menu", "player", "viewer", "editor", "reader", "sync", "cloud", "main"
        ]
    }
    
    private func normalizeName(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    private func normalizeToken(_ value: String) -> String {
        normalizeName(value).replacingOccurrences(of: " ", with: "")
    }
    
    private func isSpecificPhrase(_ value: String) -> Bool {
        let words = value.split(separator: " ").map(String.init)
        if words.count > 1 { return words.joined().count >= 5 }
        guard let first = words.first else { return false }
        return isSpecificToken(first)
    }
    
    private func isSpecificToken(_ value: String) -> Bool {
        value.count >= 4 && !genericProductTokens.contains(value)
    }
    
    private func containsPhrase(_ normalizedValue: String, phrase: String) -> Bool {
        guard isSpecificPhrase(phrase) else { return false }
        return " \(normalizedValue) ".contains(" \(phrase) ")
    }
    
    private func containsWord(_ normalizedValue: String, word: String) -> Bool {
        guard isSpecificToken(word) else { return false }
        return normalizedValue.split(separator: " ").contains(Substring(word))
    }
    
    private func confidenceSortValue(_ confidence: LeftoverConfidence) -> Int {
        switch confidence {
        case .high: return 0
        case .medium: return 1
        case .review: return 2
        }
    }
    
    /// Tính dung lượng nhanh - chỉ scan 1-2 levels, không deep recursive
    private func quickDirectorySize(at url: URL) -> UInt64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        
        // Nếu là file, trả về size ngay
        if !isDir.boolValue {
            return (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? 0
        }
        
        // Nếu là folder, dùng allocatedSizeOfDirectory (nhanh hơn enumerator)
        var totalSize: UInt64 = 0
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey], options: [.skipsHiddenFiles]) else { return 0 }
        
        var count = 0
        let maxFiles = 5000 // Giới hạn số file quét để tránh chậm
        for case let fileURL as URL in enumerator {
            count += 1
            if count > maxFiles { break } // Tránh scan quá lâu
            guard let rv = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .isRegularFileKey]),
                  rv.isRegularFile == true, let s = rv.totalFileAllocatedSize else { continue }
            totalSize += UInt64(s)
        }
        return totalSize
    }
}
