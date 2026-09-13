// ClipboardHistoryEntry.swift
// ApexUninstaller

import Foundation

struct ClipboardHistoryEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String?
    let image: ClipboardHistoryImage?
    let capturedAt: Date

    init(id: UUID = UUID(), text: String, capturedAt: Date = .now) {
        self.id = id
        self.text = text
        self.image = nil
        self.capturedAt = capturedAt
    }

    init(id: UUID = UUID(), image: ClipboardHistoryImage, capturedAt: Date = .now) {
        self.id = id
        self.text = nil
        self.image = image
        self.capturedAt = capturedAt
    }

    var preview: String {
        if let image {
            return image.preview
        }

        guard let text else { return "Clipboard item" }
        let singleLine = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard singleLine.count > 96 else { return singleLine }
        return String(singleLine.prefix(93)) + "…"
    }

    var kindIcon: String {
        if image != nil {
            return "photo.on.rectangle"
        }

        guard let text else { return "doc.on.clipboard" }
        return URL(string: text) != nil ? "link" : "doc.on.clipboard"
    }

    var isImage: Bool {
        image != nil
    }
}

struct ClipboardHistoryImage: Codable, Hashable {
    let fileName: String
    let pasteboardType: String
    let byteCount: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let fingerprint: String

    var preview: String {
        let size = ByteCountFormatter.string(
            fromByteCount: Int64(byteCount),
            countStyle: .file
        )

        guard pixelWidth > 0, pixelHeight > 0 else {
            return "Image · \(size)"
        }
        return "Image \(pixelWidth) × \(pixelHeight) · \(size)"
    }
}
