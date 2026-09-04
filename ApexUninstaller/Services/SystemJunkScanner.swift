// SystemJunkScanner.swift
// ApexUninstaller
// Scanner for user-cleanable junk files.

import Foundation
import AppKit

actor SystemJunkScanner {

    static let shared = SystemJunkScanner()

    private let fileManager = FileManager.default

    private struct ScanContext {
        let home: URL
        let library: URL?

        var userLibrary: URL {
            library ?? home.appendingPathComponent("Library", isDirectory: true)
        }
    }

    private let browserCacheTopLevelNames: Set<String> = [
        "com.apple.Safari",
        "com.apple.Safari.SafeBrowsing",
        "com.apple.WebKit.Networking",
        "com.google.Chrome",
        "Google",
        "org.mozilla.firefox",
        "Firefox",
        "com.microsoft.edgemac",
        "Microsoft Edge",
        "BraveSoftware",
        "Arc",
        "Vivaldi",
        "com.brave.Browser",
        "com.operasoftware.Opera",
        "com.vivaldi.Vivaldi"
    ]

    // MARK: - Public API

    func scan(libraryURL: URL? = nil) async -> SystemJunkScanResult {
        let context = ScanContext(home: realUserHomeDirectory, library: libraryURL)
        var result = SystemJunkScanResult()

        await withTaskGroup(of: [SystemJunkItem].self) { group in
            group.addTask { await self.scanBrowserCaches(context: context) }
            group.addTask { await self.scanSystemCaches(context: context) }
            group.addTask { await self.scanAppCaches(context: context) }
            group.addTask { await self.scanSystemLogs(context: context) }
            group.addTask { await self.scanTempFiles(context: context) }
            group.addTask { await self.scanXcodeDerivedData(context: context) }
            group.addTask { await self.scanFontCaches(context: context) }
            group.addTask { await self.scanThumbnailCaches(context: context) }

            for await items in group {
                result.items.append(contentsOf: items)
                result.totalSize += items.reduce(0) { $0 + $1.size }
            }
        }

        result.items.sort { lhs, rhs in
            categorySortIndex(lhs.category) < categorySortIndex(rhs.category)
        }
        result.isComplete = true
        return result
    }

    // MARK: - Category Scanners

    private func scanBrowserCaches(context: ScanContext) async -> [SystemJunkItem] {
        let caches = context.userLibrary.appendingPathComponent("Caches", isDirectory: true)
        let targets = browserCacheTargets(context: context)

        let summary = scanTargets(targets)
        return [SystemJunkItem(
            category: .browserCache,
            path: caches,
            size: summary.size,
            itemCount: summary.count,
            description: "Safari, Chrome, Edge, Brave, Arc, Firefox caches",
            paths: summary.paths,
            details: summary.details
        )]
    }

    private func scanSystemCaches(context: ScanContext) async -> [SystemJunkItem] {
        let caches = context.userLibrary.appendingPathComponent("Caches", isDirectory: true)
        let targets = childURLs(in: caches, excludingNames: browserCacheTopLevelNames)
        let summary = scanTargets(targets)

        return [SystemJunkItem(
            category: .systemCache,
            path: caches,
            size: summary.size,
            itemCount: summary.count,
            description: "User Library application caches",
            paths: summary.paths,
            details: summary.details
        )]
    }

    private func scanAppCaches(context: ScanContext) async -> [SystemJunkItem] {
        // Note: /Library/Caches is system-level and inaccessible in sandbox.
        // Scan user-level container caches instead.
        let containerCaches = context.userLibrary.appendingPathComponent("Containers", isDirectory: true)
        var writableTargets: [URL] = []
        
        for container in childURLs(in: containerCaches) {
            let cachePath = container.appendingPathComponent("Data/Library/Caches", isDirectory: true)
            if fileManager.fileExists(atPath: cachePath.path),
               fileManager.isReadableFile(atPath: cachePath.path) {
                writableTargets.append(cachePath)
            }
        }
        
        let summary = scanTargets(Array(writableTargets.prefix(100)))

        return [SystemJunkItem(
            category: .applicationCache,
            path: containerCaches,
            size: summary.size,
            itemCount: summary.count,
            description: "Sandboxed application caches",
            paths: summary.paths,
            details: summary.details
        )]
    }

    private func scanSystemLogs(context: ScanContext) async -> [SystemJunkItem] {
        let logs = context.userLibrary.appendingPathComponent("Logs", isDirectory: true)
        let summary = scanTargets(childURLs(in: logs))

        return [SystemJunkItem(
            category: .logs,
            path: logs,
            size: summary.size,
            itemCount: summary.count,
            description: "User application logs",
            paths: summary.paths,
            details: summary.details
        )]
    }

    private func scanTempFiles(context: ScanContext) async -> [SystemJunkItem] {
        // Only use NSTemporaryDirectory() which resolves to sandbox container temp in sandbox mode
        let userTemp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let summary = scanTargets(childURLs(in: userTemp))

        return [SystemJunkItem(
            category: .tempFiles,
            path: userTemp,
            size: summary.size,
            itemCount: summary.count,
            description: "Temporary files",
            paths: summary.paths,
            details: summary.details
        )]
    }

    private func scanXcodeDerivedData(context: ScanContext) async -> [SystemJunkItem] {
        let derivedData = context.userLibrary.appendingPathComponent("Developer/Xcode/DerivedData", isDirectory: true)
        let summary = scanTargets(childURLs(in: derivedData))

        return [SystemJunkItem(
            category: .xcodeDerivedData,
            path: derivedData,
            size: summary.size,
            itemCount: summary.count,
            description: "Xcode build artifacts",
            paths: summary.paths,
            details: summary.details
        )]
    }

    private func scanFontCaches(context: ScanContext) async -> [SystemJunkItem] {
        let fontCaches = context.userLibrary.appendingPathComponent("Caches/com.apple.ATS", isDirectory: true)
        let summary = scanTargets(childURLs(in: fontCaches))

        return [SystemJunkItem(
            category: .fontCaches,
            path: fontCaches,
            size: summary.size,
            itemCount: summary.count,
            description: "Font rendering caches",
            paths: summary.paths,
            details: summary.details
        )]
    }

    private func scanThumbnailCaches(context: ScanContext) async -> [SystemJunkItem] {
        let targets = [
            context.userLibrary.appendingPathComponent("Caches/com.apple.QuickLook", isDirectory: true),
            context.userLibrary.appendingPathComponent("Caches/com.apple.ImageCapture", isDirectory: true),
            context.userLibrary.appendingPathComponent("Containers/com.apple.Preview/Data/Library/Caches", isDirectory: true)
        ]
        let summary = scanTargets(targets)

        return [SystemJunkItem(
            category: .thumbnailCaches,
            path: context.userLibrary.appendingPathComponent("Caches", isDirectory: true),
            size: summary.size,
            itemCount: summary.count,
            description: "Image and preview thumbnails",
            paths: summary.paths,
            details: summary.details
        )]
    }

    private func browserCacheTargets(context: ScanContext) -> [URL] {
        let library = context.userLibrary
        let caches = library.appendingPathComponent("Caches", isDirectory: true)
        var targets: [URL] = [
            caches.appendingPathComponent("com.apple.Safari", isDirectory: true),
            caches.appendingPathComponent("com.apple.Safari.SafeBrowsing", isDirectory: true),
            caches.appendingPathComponent("com.apple.WebKit.Networking", isDirectory: true),
            library.appendingPathComponent("Containers/com.apple.Safari/Data/Library/Caches", isDirectory: true),
            caches.appendingPathComponent("Google/Chrome", isDirectory: true),
            caches.appendingPathComponent("Microsoft Edge", isDirectory: true),
            caches.appendingPathComponent("BraveSoftware/Brave-Browser", isDirectory: true),
            caches.appendingPathComponent("Arc", isDirectory: true),
            caches.appendingPathComponent("Vivaldi", isDirectory: true),
            caches.appendingPathComponent("com.operasoftware.Opera", isDirectory: true),
            caches.appendingPathComponent("Firefox/Profiles", isDirectory: true),
            caches.appendingPathComponent("org.mozilla.firefox", isDirectory: true)
        ]

        let chromiumUserDataRoots = [
            library.appendingPathComponent("Application Support/Google/Chrome", isDirectory: true),
            library.appendingPathComponent("Application Support/Microsoft Edge", isDirectory: true),
            library.appendingPathComponent("Application Support/BraveSoftware/Brave-Browser", isDirectory: true),
            library.appendingPathComponent("Application Support/Arc/User Data", isDirectory: true),
            library.appendingPathComponent("Application Support/Vivaldi", isDirectory: true),
            library.appendingPathComponent("Application Support/com.operasoftware.Opera", isDirectory: true)
        ]

        for root in chromiumUserDataRoots {
            targets.append(contentsOf: chromiumCacheTargets(in: root))
        }

        let firefoxProfiles = library.appendingPathComponent("Application Support/Firefox/Profiles", isDirectory: true)
        for profile in childURLs(in: firefoxProfiles) {
            targets.append(profile.appendingPathComponent("cache2", isDirectory: true))
            targets.append(profile.appendingPathComponent("startupCache", isDirectory: true))
        }

        return deduplicatedURLs(targets)
    }

    private func chromiumCacheTargets(in userDataRoot: URL) -> [URL] {
        let profileNames = [
            "Default",
            "Guest Profile",
            "System Profile"
        ]
        let profileDirectories = childURLs(in: userDataRoot)
            .filter { url in
                profileNames.contains(url.lastPathComponent) || url.lastPathComponent.hasPrefix("Profile ")
            }

        let cacheSubpaths = [
            "Cache",
            "Code Cache",
            "GPUCache",
            "DawnCache",
            "GrShaderCache",
            "ShaderCache",
            "Media Cache",
            "Service Worker/CacheStorage"
        ]

        var targets: [URL] = []
        for profile in profileDirectories {
            targets.append(contentsOf: cacheSubpaths.map { profile.appendingPathComponent($0, isDirectory: true) })
        }
        return targets
    }

    // MARK: - Cleanup

    func clean(items: [SystemJunkItem], skipConfirmation: Bool = false) async throws -> UInt64 {
        var totalCleaned: UInt64 = 0

        for item in items {
            if !item.category.estimatedSafeToDelete && !skipConfirmation {
                continue
            }
            totalCleaned += await cleanItem(item)
        }

        return totalCleaned
    }

    private func cleanItem(_ item: SystemJunkItem) async -> UInt64 {
        await trashTargets(item.paths, removeDirectories: false)
    }

    private func trashTargets(_ targets: [URL], removeDirectories: Bool) async -> UInt64 {
        var trashedSize: UInt64 = 0

        for target in targets {
            guard RemovalSafetyPolicy.canMoveToTrash(target) else { continue }
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: target.path, isDirectory: &isDir) else { continue }

            if isDir.boolValue {
                if removeDirectories {
                    let size = sizeOfURL(target)
                    if (try? fileManager.trashItem(at: target, resultingItemURL: nil)) != nil {
                        trashedSize += size
                    }
                } else {
                    trashedSize += trashDirectoryContents(target)
                }
            } else {
                let size = sizeOfURL(target)
                if (try? fileManager.trashItem(at: target, resultingItemURL: nil)) != nil {
                    trashedSize += size
                }
            }
        }

        return trashedSize
    }

    private func trashDirectoryContents(_ directory: URL) -> UInt64 {
        var trashedSize: UInt64 = 0

        guard let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return 0
        }

        for item in contents {
            guard RemovalSafetyPolicy.canMoveToTrash(item) else { continue }
            let size = sizeOfURL(item)
            if (try? fileManager.trashItem(at: item, resultingItemURL: nil)) != nil {
                trashedSize += size
            }
        }

        return trashedSize
    }

    // MARK: - Helpers

    private func scanTargets(_ targets: [URL]) -> (size: UInt64, count: Int, paths: [URL], details: [SystemJunkDetail]) {
        var totalSize: UInt64 = 0
        var itemCount = 0
        var scannedPaths: [URL] = []
        var details: [SystemJunkDetail] = []

        for target in deduplicatedURLs(targets) {
            guard let scan = scanURL(target), scan.size > 0 || scan.count > 0 else { continue }
            totalSize += scan.size
            itemCount += scan.count
            scannedPaths.append(target)
            details.append(SystemJunkDetail(path: target, size: scan.size, itemCount: scan.count))
        }

        details.sort { $0.size > $1.size }
        return (totalSize, itemCount, scannedPaths, details)
    }

    private func scanURL(_ url: URL) -> (size: UInt64, count: Int)? {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return nil }

        if !isDir.boolValue {
            return (sizeOfURL(url), 1)
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        var totalSize: UInt64 = 0
        var itemCount = 0
        var visited = 0
        let maxItems = 10_000

        for case let fileURL as URL in enumerator {
            visited += 1
            if visited > maxItems { break }

            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                  values.isDirectory == false else {
                continue
            }

            totalSize += UInt64(values.fileSize ?? 0)
            itemCount += 1
        }

        return (totalSize, itemCount)
    }

    private func childURLs(in directory: URL, excludingNames: Set<String> = [], skipsHiddenFiles: Bool = true) -> [URL] {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
            return []
        }

        let options: FileManager.DirectoryEnumerationOptions = skipsHiddenFiles ? [.skipsHiddenFiles] : []
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: options
        ) else {
            return []
        }

        return contents.filter { !excludingNames.contains($0.lastPathComponent) }
    }

    private func deduplicatedURLs(_ urls: [URL]) -> [URL] {
        var seen: Set<String> = []
        return urls.filter { url in
            let key = url.standardizedFileURL.resolvingSymlinksInPath().path
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private func sizeOfURL(_ url: URL) -> UInt64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }

        if isDir.boolValue {
            return scanURL(url)?.size ?? 0
        }

        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? NSNumber else {
            return 0
        }
        return size.uint64Value
    }

    private func categorySortIndex(_ category: SystemJunkCategory) -> Int {
        SystemJunkCategory.allCases.firstIndex(of: category) ?? Int.max
    }
}
