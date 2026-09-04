// BookmarkManager.swift
// ApexUninstaller
//
// Quản lý Security-Scoped Bookmarks cho App Sandbox.
// Cho phép app truy cập ~/Library/ sau khi user cấp quyền qua NSOpenPanel.
// Lưu bookmark vĩnh viễn - user chỉ cần cấp quyền 1 lần duy nhất.
// VALIDATE: kiểm tra bookmark phải trỏ đúng ~/Library, nếu sai → hỏi lại.

import Foundation
import AppKit

@Observable
final class BookmarkManager {
    
    /// Đã có quyền truy cập Library chưa
    var hasLibraryAccess: Bool = false
    
    /// Cần hiển thị onboarding cấp quyền
    var showAccessOnboarding: Bool = false
    
    /// URL Library đang truy cập (security-scoped)
    private(set) var libraryURL: URL?

    /// Các thư mục bổ sung user đã cấp quyền để quét ứng dụng ngoài /Applications.
    private(set) var additionalAppLocationURLs: [URL] = []
    
    /// Key lưu bookmark
    private let bookmarkKey = "ApexUninstaller.libraryBookmark"
    private let appLocationsBookmarkKey = "ApexUninstaller.additionalAppLocationBookmarks"
    private let directAppLocationsKey = "ApexUninstaller.directAdditionalAppLocationPaths"
    
    init() {
        if DistributionChannel.isDirect {
            libraryURL = realUserHomeDirectory.appendingPathComponent("Library", isDirectory: true)
            hasLibraryAccess = true
        } else {
            restoreBookmark()
        }
        restoreAdditionalAppLocations()
    }
    
    // MARK: - Yêu cầu quyền truy cập
    
    /// Hiển thị NSOpenPanel để user chọn thư mục ~/Library
    /// User chỉ cần làm 1 lần; quyền được lưu bằng security-scoped bookmark.
    @MainActor
    func requestLibraryAccess() -> Bool {
        if DistributionChannel.isDirect {
            libraryURL = realUserHomeDirectory.appendingPathComponent("Library", isDirectory: true)
            hasLibraryAccess = true
            return true
        }

        let panel = NSOpenPanel()
        panel.title = "Select Library folder to scan leftover files"
        panel.message = "Please select the Library folder in your Home folder.\nPath: ~/Library"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.showsHiddenFiles = true
        
        // Đặt đường dẫn mặc định đến Library thật của user, không phải Library trong sandbox container.
        let homeLibrary = realUserHomeDirectory.appendingPathComponent("Library", isDirectory: true)
        panel.directoryURL = homeLibrary
        
        let response = panel.runModal()
        
        if response == .OK, let selectedURL = panel.url {
            // Validate: phải là thư mục Library
            if !isValidLibraryPath(selectedURL) {
                print("⚠️ User chọn sai thư mục: \(selectedURL.path). Cần chọn ~/Library")
                // Hiện lại panel với thông báo rõ hơn
                return requestLibraryAccessWithWarning()
            }
            return saveBookmark(for: selectedURL)
        }
        
        return false
    }

    /// Cho phép user cấp quyền các vị trí cài app ngoài chuẩn, ví dụ:
    /// /Users/Shared, thư mục Game/Games, Steam library, hoặc ổ ngoài.
    @MainActor
    func requestAdditionalAppLocationAccess(startingAt suggestedURL: URL? = nil) -> Bool {
        let panel = NSOpenPanel()
        panel.title = "Add app scan location"
        if let suggestedURL {
            panel.message = "Select this folder to grant scan access:\n\(suggestedURL.path)"
        } else {
            panel.message = "Select a folder that may contain apps, e.g. /Users/Shared, Game/Games folder, Steam library, or external drives."
        }
        panel.prompt = "Add Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        panel.showsHiddenFiles = true

        let shared = URL(fileURLWithPath: "/Users/Shared", isDirectory: true)
        if let suggestedURL {
            panel.directoryURL = suggestedURL.deletingLastPathComponent()
        } else {
            panel.directoryURL = FileManager.default.fileExists(atPath: shared.path) ? shared : realUserHomeDirectory
        }

        guard panel.runModal() == .OK else { return false }

        if DistributionChannel.isDirect {
            return saveDirectAdditionalAppLocations(panel.urls)
        }
        return saveAdditionalAppLocationBookmarks(for: panel.urls)
    }

    private func saveDirectAdditionalAppLocations(_ urls: [URL]) -> Bool {
        var paths = Set(UserDefaults.standard.stringArray(forKey: directAppLocationsKey) ?? [])
        let previousCount = paths.count

        for url in urls {
            paths.insert(normalizedPath(url))
        }

        let sortedPaths = paths.sorted()
        UserDefaults.standard.set(sortedPaths, forKey: directAppLocationsKey)
        additionalAppLocationURLs = sortedPaths.map { URL(fileURLWithPath: $0, isDirectory: true) }
        return paths.count > previousCount
    }

    /// Hiện lại panel khi user chọn sai thư mục
    @MainActor
    private func requestLibraryAccessWithWarning() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Wrong folder!"
        alert.informativeText = "You need to select the Library folder (~/Library), not Applications.\n\nPress Cmd+Shift+G and type ~/Library to navigate to the correct folder."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Try Again")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            return requestLibraryAccess()
        }
        return false
    }
    
    /// Kiểm tra URL có phải ~/Library không
    private func isValidLibraryPath(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.resolvingSymlinksInPath().path
        let expectedLibrary = realUserHomeDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path
        
        // Chỉ chấp nhận đúng ~/Library để tránh quét nhầm /Library hoặc subfolder.
        return path == expectedLibrary
    }

    /// Home thật của user. Trong App Sandbox, FileManager.homeDirectoryForCurrentUser
    /// có thể trỏ tới container của app, nên không dùng để validate ~/Library.
    
    
    // MARK: - Lưu Bookmark
    
    /// Lưu security-scoped bookmark cho URL đã chọn
    private func saveBookmark(for url: URL) -> Bool {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            
            // Bắt đầu truy cập ngay
            return startAccessing(bookmarkData: bookmarkData)
        } catch {
            print("❌ Lỗi lưu bookmark: \(error)")
            return false
        }
    }

    private func saveAdditionalAppLocationBookmarks(for urls: [URL]) -> Bool {
        var storedBookmarks = UserDefaults.standard.array(forKey: appLocationsBookmarkKey) as? [Data] ?? []
        var knownPaths = Set(additionalAppLocationURLs.map { normalizedPath($0) })
        var addedAny = false

        for url in urls {
            let key = normalizedPath(url)
            guard !knownPaths.contains(key) else { continue }

            do {
                let bookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )

                guard let resolvedURL = resolveSecurityScopedURL(from: bookmarkData) else { continue }
                storedBookmarks.append(bookmarkData)
                additionalAppLocationURLs.append(resolvedURL)
                knownPaths.insert(key)
                addedAny = true
            } catch {
                print("❌ Lỗi lưu bookmark thư mục app: \(error)")
            }
        }

        if addedAny {
            UserDefaults.standard.set(storedBookmarks, forKey: appLocationsBookmarkKey)
        }
        return addedAny
    }
    
    // MARK: - Khôi phục Bookmark
    
    /// Khôi phục bookmark đã lưu từ lần trước
    func restoreBookmark() {
        if DistributionChannel.isDirect {
            libraryURL = realUserHomeDirectory.appendingPathComponent("Library", isDirectory: true)
            hasLibraryAccess = true
            return
        }

        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            hasLibraryAccess = false
            return
        }
        
        _ = startAccessing(bookmarkData: bookmarkData)
    }

    func restoreAdditionalAppLocations() {
        if DistributionChannel.isDirect {
            let paths = UserDefaults.standard.stringArray(forKey: directAppLocationsKey) ?? []
            additionalAppLocationURLs = paths
                .map { URL(fileURLWithPath: $0, isDirectory: true) }
                .filter { FileManager.default.fileExists(atPath: $0.path) }
            return
        }

        let bookmarkDataList = UserDefaults.standard.array(forKey: appLocationsBookmarkKey) as? [Data] ?? []
        var validBookmarks: [Data] = []
        var restoredURLs: [URL] = []
        var seenPaths: Set<String> = []

        for bookmarkData in bookmarkDataList {
            guard let url = resolveSecurityScopedURL(from: bookmarkData) else { continue }
            let key = normalizedPath(url)
            guard seenPaths.insert(key).inserted else {
                url.stopAccessingSecurityScopedResource()
                continue
            }
            validBookmarks.append(bookmarkData)
            restoredURLs.append(url)
        }

        additionalAppLocationURLs = restoredURLs
        if validBookmarks.count != bookmarkDataList.count {
            UserDefaults.standard.set(validBookmarks, forKey: appLocationsBookmarkKey)
        }
    }
    
    /// Bắt đầu truy cập URL từ bookmark data
    private func startAccessing(bookmarkData: Data) -> Bool {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                // Bookmark cũ → cần user cấp lại
                hasLibraryAccess = false
                return false
            }
            
            // Validate: bookmark phải trỏ đến ~/Library
            if !isValidLibraryPath(url) {
                print("⚠️ Bookmark cũ trỏ sai thư mục: \(url.path). Xóa bookmark.")
                revokeAccess()
                return false
            }
            
            // Bắt đầu truy cập security-scoped resource
            if url.startAccessingSecurityScopedResource() {
                libraryURL = url
                hasLibraryAccess = true
                return true
            } else {
                hasLibraryAccess = false
                return false
            }
        } catch {
            hasLibraryAccess = false
            return false
        }
    }

    private func resolveSecurityScopedURL(from bookmarkData: Data) -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard !isStale, url.startAccessingSecurityScopedResource() else {
                return nil
            }
            return url
        } catch {
            return nil
        }
    }
    
    // MARK: - Dừng truy cập
    
    /// Dừng truy cập security-scoped resource (gọi khi app thoát)
    func stopAccessing() {
        if DistributionChannel.isDirect { return }
        libraryURL?.stopAccessingSecurityScopedResource()
        libraryURL = nil
    }

    func removeAdditionalAppLocation(_ url: URL) {
        let key = normalizedPath(url)

        if DistributionChannel.isDirect {
            additionalAppLocationURLs.removeAll { normalizedPath($0) == key }
            UserDefaults.standard.set(additionalAppLocationURLs.map { normalizedPath($0) }, forKey: directAppLocationsKey)
            return
        }

        additionalAppLocationURLs.removeAll { location in
            if normalizedPath(location) == key {
                location.stopAccessingSecurityScopedResource()
                return true
            }
            return false
        }

        let bookmarks = UserDefaults.standard.array(forKey: appLocationsBookmarkKey) as? [Data] ?? []
        let keptBookmarks = bookmarks.filter { bookmarkData in
            guard let resolvedURL = resolveSecurityScopedURL(from: bookmarkData) else { return false }
            defer { resolvedURL.stopAccessingSecurityScopedResource() }
            return normalizedPath(resolvedURL) != key
        }
        UserDefaults.standard.set(keptBookmarks, forKey: appLocationsBookmarkKey)
    }

    func clearAdditionalAppLocations() {
        if DistributionChannel.isDirect {
            additionalAppLocationURLs = []
            UserDefaults.standard.removeObject(forKey: directAppLocationsKey)
            return
        }

        additionalAppLocationURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        additionalAppLocationURLs = []
        UserDefaults.standard.removeObject(forKey: appLocationsBookmarkKey)
    }
    
    /// Xóa bookmark (reset quyền)
    func revokeAccess() {
        if DistributionChannel.isDirect {
            libraryURL = realUserHomeDirectory.appendingPathComponent("Library", isDirectory: true)
            hasLibraryAccess = true
            return
        }

        stopAccessing()
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        hasLibraryAccess = false
    }

    deinit {
        stopAccessing()
        if !DistributionChannel.isDirect {
            additionalAppLocationURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        }
    }

    private func normalizedPath(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path
    }
}
