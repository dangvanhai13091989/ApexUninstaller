// ClipboardHistoryManager.swift
// ApexUninstaller
//
// Clipboard history is strictly opt-in. It stores text, links, and limited-size
// images locally, encrypts every retained item, and never sends content
// off-device.

import AppKit
import CryptoKit
import Foundation
import Security

@Observable
@MainActor
final class ClipboardHistoryManager {
    static let shared = ClipboardHistoryManager()

    private enum Storage {
        static let enabledKey = "ApexUninstaller.clipboardHistoryEnabled"
        static let entriesKey = "ApexUninstaller.clipboardHistoryEncryptedEntries"
        static let shortcutKey = "ApexUninstaller.clipboardHistoryShortcut"
        static let maximumEntries = 30
        static let maximumImageEntries = 10
        static let retention: TimeInterval = 24 * 60 * 60
        static let maximumTextLength = 32_768
        static let maximumImageDataLength = 8 * 1_024 * 1_024
        static let imageDirectoryName = "ApexUninstallerClipboardHistory"
    }

    private let pasteboard = NSPasteboard.general
    private let defaults = UserDefaults.standard
    private var timer: Timer?
    private var lastChangeCount: Int
    private var isRestoringShortcut = false

    private(set) var entries: [ClipboardHistoryEntry]
    var shortcut: ClipboardShortcut {
        didSet {
            guard !isRestoringShortcut else { return }

            if ClipboardHotkeyManager.shared.register(shortcut: shortcut) {
                defaults.set(shortcut.rawValue, forKey: Storage.shortcutKey)
            } else {
                // Do not leave the preference pointing at a shortcut owned by
                // another app. Re-register the last known working choice.
                ClipboardHotkeyManager.shared.register(
                    shortcut: oldValue,
                    clearsFailure: false
                )
                isRestoringShortcut = true
                shortcut = oldValue
                isRestoringShortcut = false
            }
        }
    }

    var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Storage.enabledKey)
            if isEnabled {
                beginMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }

    private init() {
        isEnabled = defaults.bool(forKey: Storage.enabledKey)
        entries = ClipboardHistoryCipher.load(from: defaults, key: Storage.entriesKey)
        shortcut = ClipboardShortcut(
            rawValue: defaults.string(forKey: Storage.shortcutKey) ?? ""
        ) ?? .defaultValue
        lastChangeCount = NSPasteboard.general.changeCount
        // Rewrite storage if any entry expired while the app was not running,
        // so it is no longer retained inside the encrypted blob.
        discardExpiredEntries(persist: true)
        discardEntriesWithMissingImages(persist: true)

        if isEnabled {
            beginMonitoring()
        }
    }

    func clearHistory() {
        entries.removeAll()
        ClipboardHistoryCipher.remove(from: defaults, key: Storage.entriesKey)
        removeAllImageFiles()
    }

    @discardableResult
    func copyToPasteboard(_ entry: ClipboardHistoryEntry) -> Bool {
        if let image = entry.image {
            guard let data = imageData(for: image) else { return false }

            pasteboard.clearContents()
            let pasteboardType = NSPasteboard.PasteboardType(image.pasteboardType)
            pasteboard.setData(data, forType: pasteboardType)

            // TIFF is the most widely accepted native image type on macOS.
            // Keep the original representation too, so apps that support PNG,
            // JPEG, or HEIC can paste it without conversion.
            if pasteboardType != .tiff,
               let nsImage = NSImage(data: data),
               let tiffData = nsImage.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
            lastChangeCount = pasteboard.changeCount
            return true
        }

        guard let text = entry.text else { return false }
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        lastChangeCount = pasteboard.changeCount
        return true
    }

    func image(for entry: ClipboardHistoryEntry) -> NSImage? {
        guard let image = entry.image,
              let data = imageData(for: image) else {
            return nil
        }
        return NSImage(data: data)
    }

    private func beginMonitoring() {
        guard timer == nil else { return }

        // Do not read existing clipboard content when a user first turns this
        // on. The next explicit copy is the first item considered for history.
        lastChangeCount = pasteboard.changeCount
        let scheduledTimer = Timer(timeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.capturePasteboardChangeIfNeeded()
            }
        }
        RunLoop.main.add(scheduledTimer, forMode: .common)
        timer = scheduledTimer
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        lastChangeCount = pasteboard.changeCount
    }

    private func capturePasteboardChangeIfNeeded() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        guard !isExcludedSourceApplication else { return }

        if let image = eligibleImageFromPasteboard() {
            add(image: image)
            return
        }

        guard let text = pasteboard.string(forType: .string),
              isEligible(text) else { return }
        add(text: text)
    }

    private var isExcludedSourceApplication: Bool {
        let protectedBundleIdentifiers: Set<String> = [
            "com.apple.keychainaccess",
            "com.1password.1password",
            "com.agilebits.onepassword7",
            "com.bitwarden.desktop",
            "com.dashlane.dashlane",
            "com.lastpass.lastpass"
        ]

        guard let identifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier?.lowercased() else {
            return false
        }
        return protectedBundleIdentifiers.contains(identifier)
    }

    private func isEligible(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && text.utf8.count <= Storage.maximumTextLength
    }

    private func add(text: String) {
        discardExpiredEntries(persist: false)
        entries.removeAll { $0.text == text }
        entries.insert(ClipboardHistoryEntry(text: text), at: 0)
        trimEntriesToLimits()
        persist()
    }

    private func add(image capturedImage: CapturedImage) {
        discardExpiredEntries(persist: false)
        let fingerprint = SHA256.hash(data: capturedImage.data)
            .map { String(format: "%02x", $0) }
            .joined()

        if let existingIndex = entries.firstIndex(
            where: { $0.image?.fingerprint == fingerprint }
        ), let existingImage = entries[existingIndex].image {
            let existingID = entries[existingIndex].id
            entries.remove(at: existingIndex)
            entries.insert(
                ClipboardHistoryEntry(id: existingID, image: existingImage),
                at: 0
            )
            trimEntriesToLimits()
            persist()
            return
        }

        let id = UUID()
        guard let fileName = saveImageData(capturedImage.data, for: id) else { return }
        let metadata = ClipboardHistoryImage(
            fileName: fileName,
            pasteboardType: capturedImage.pasteboardType.rawValue,
            byteCount: capturedImage.data.count,
            pixelWidth: capturedImage.pixelWidth,
            pixelHeight: capturedImage.pixelHeight,
            fingerprint: fingerprint
        )
        entries.insert(ClipboardHistoryEntry(id: id, image: metadata), at: 0)
        trimEntriesToLimits()
        persist()
    }

    private func discardExpiredEntries(persist: Bool) {
        let cutoff = Date.now.addingTimeInterval(-Storage.retention)
        let expiredEntries = entries.filter { $0.capturedAt < cutoff }
        let before = entries.count
        entries.removeAll { $0.capturedAt < cutoff }
        removeImageFiles(for: expiredEntries)
        if persist, before != entries.count {
            self.persist()
        }
    }

    private func persist() {
        ClipboardHistoryCipher.save(entries, to: defaults, key: Storage.entriesKey)
        removeOrphanedImageFiles()
    }

    private func eligibleImageFromPasteboard() -> CapturedImage? {
        let supportedTypes: [NSPasteboard.PasteboardType] = [
            NSPasteboard.PasteboardType("public.png"),
            .tiff,
            NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("public.heic")
        ]

        for type in supportedTypes {
            guard let data = pasteboard.data(forType: type),
                  !data.isEmpty,
                  data.count <= Storage.maximumImageDataLength,
                  let image = NSImage(data: data) else {
                continue
            }

            return CapturedImage(
                data: data,
                pasteboardType: type,
                pixelWidth: max(0, Int(image.size.width.rounded())),
                pixelHeight: max(0, Int(image.size.height.rounded()))
            )
        }
        return nil
    }

    private func trimEntriesToLimits() {
        var retained: [ClipboardHistoryEntry] = []
        var discarded: [ClipboardHistoryEntry] = []
        var imageCount = 0

        for entry in entries {
            guard retained.count < Storage.maximumEntries else {
                discarded.append(entry)
                continue
            }

            if entry.isImage {
                guard imageCount < Storage.maximumImageEntries else {
                    discarded.append(entry)
                    continue
                }
                imageCount += 1
            }
            retained.append(entry)
        }

        entries = retained
        removeImageFiles(for: discarded)
    }

    private func discardEntriesWithMissingImages(persist: Bool) {
        let invalidEntries = entries.filter { entry in
            guard let image = entry.image else { return false }
            return imageData(for: image) == nil
        }
        guard !invalidEntries.isEmpty else { return }

        let invalidIDs = Set(invalidEntries.map(\.id))
        entries.removeAll { invalidIDs.contains($0.id) }
        removeImageFiles(for: invalidEntries)
        if persist {
            self.persist()
        }
    }

    private func saveImageData(_ data: Data, for id: UUID) -> String? {
        guard let encryptedData = ClipboardHistoryCipher.seal(data),
              let directory = imageDirectory(createIfNeeded: true) else {
            return nil
        }

        let fileName = "image-\(id.uuidString).bin"
        let fileURL = directory.appendingPathComponent(fileName)
        do {
            try encryptedData.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    private func imageData(for image: ClipboardHistoryImage) -> Data? {
        guard isSafeImageFileName(image.fileName),
              let directory = imageDirectory(createIfNeeded: false) else {
            return nil
        }
        let fileURL = directory.appendingPathComponent(image.fileName)
        guard let encryptedData = try? Data(contentsOf: fileURL) else { return nil }
        return ClipboardHistoryCipher.open(encryptedData)
    }

    private func removeImageFiles(for entries: [ClipboardHistoryEntry]) {
        guard let directory = imageDirectory(createIfNeeded: false) else { return }
        for entry in entries {
            guard let fileName = entry.image?.fileName,
                  isSafeImageFileName(fileName) else {
                continue
            }
            try? FileManager.default.removeItem(
                at: directory.appendingPathComponent(fileName)
            )
        }
    }

    private func removeAllImageFiles() {
        guard let directory = imageDirectory(createIfNeeded: false) else { return }
        try? FileManager.default.removeItem(at: directory)
    }

    private func removeOrphanedImageFiles() {
        guard let directory = imageDirectory(createIfNeeded: false),
              let fileURLs = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
              ) else {
            return
        }

        let retainedFileNames = Set(entries.compactMap(\.image?.fileName))
        for fileURL in fileURLs where !retainedFileNames.contains(fileURL.lastPathComponent) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func imageDirectory(createIfNeeded: Bool) -> URL? {
        guard let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }

        let directory = applicationSupportDirectory.appendingPathComponent(
            Storage.imageDirectoryName,
            isDirectory: true
        )
        guard createIfNeeded else { return directory }

        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            return directory
        } catch {
            return nil
        }
    }

    private func isSafeImageFileName(_ fileName: String) -> Bool {
        fileName.hasPrefix("image-") &&
            fileName.hasSuffix(".bin") &&
            !fileName.contains("/") &&
            !fileName.contains("\\")
    }
}

private struct CapturedImage {
    let data: Data
    let pasteboardType: NSPasteboard.PasteboardType
    let pixelWidth: Int
    let pixelHeight: Int
}

private enum ClipboardHistoryCipher {
    // The Store and Direct editions have different bundle identifiers and
    // Keychain access groups. Versioning the service prevents a Direct-edition
    // key from blocking or being reused by the sandboxed Store edition.
    private static let keychainService = "\(Bundle.main.bundleIdentifier ?? "com.haidv.apexuninstaller").clipboard-history.v2"
    private static let keychainAccount = "encryption-key"

    static func load(from defaults: UserDefaults, key: String) -> [ClipboardHistoryEntry] {
        guard let encoded = defaults.string(forKey: key),
              let sealedData = Data(base64Encoded: encoded),
              let clearData = open(sealedData),
              let entries = try? JSONDecoder().decode([ClipboardHistoryEntry].self, from: clearData) else {
            return []
        }
        return entries
    }

    static func save(_ entries: [ClipboardHistoryEntry], to defaults: UserDefaults, key: String) {
        guard let clearData = try? JSONEncoder().encode(entries),
              let sealedData = seal(clearData) else {
            return
        }
        defaults.set(sealedData.base64EncodedString(), forKey: key)
    }

    static func seal(_ clearData: Data) -> Data? {
        guard let keyData = loadOrCreateKey(),
              let sealedBox = try? AES.GCM.seal(
                clearData,
                using: SymmetricKey(data: keyData)
              ),
              let combined = sealedBox.combined else {
            return nil
        }
        return combined
    }

    static func open(_ sealedData: Data) -> Data? {
        guard let keyData = loadKey(),
              let sealedBox = try? AES.GCM.SealedBox(combined: sealedData) else {
            return nil
        }
        return try? AES.GCM.open(sealedBox, using: SymmetricKey(data: keyData))
    }

    static func remove(from defaults: UserDefaults, key: String) {
        defaults.removeObject(forKey: key)
    }

    private static func loadOrCreateKey() -> Data? {
        if let existing = loadKey() {
            return existing
        }

        let generated = SymmetricKey(size: .bits256)
        let keyData = generated.withUnsafeBytes { Data($0) }
        return saveKey(keyData) ? keyData : nil
    }

    private static func loadKey() -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func saveKey(_ keyData: Data) -> Bool {
        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecValueData: keyData,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }
}
