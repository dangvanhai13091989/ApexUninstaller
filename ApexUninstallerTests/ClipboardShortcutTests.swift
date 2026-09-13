// ClipboardShortcutTests.swift

import Carbon.HIToolbox
import XCTest
@testable import ApexUninstaller

final class ClipboardShortcutTests: XCTestCase {
    func testDefaultShortcutIsAvailableInTheSupportedChoices() {
        XCTAssertTrue(ClipboardShortcut.allCases.contains(.defaultValue))
    }

    func testShortcutsHaveUniqueDisplayNamesAndKeyCombinations() {
        let displayNames = ClipboardShortcut.allCases.map(\.displayString)
        XCTAssertEqual(Set(displayNames).count, displayNames.count)

        let combinations = ClipboardShortcut.allCases.map { "\($0.keyCode)-\($0.modifiers)" }
        XCTAssertEqual(Set(combinations).count, combinations.count)
    }

    func testEveryShortcutUsesCommandOrControl() {
        let commandOrControl = UInt32(cmdKey) | UInt32(controlKey)

        for shortcut in ClipboardShortcut.allCases {
            XCTAssertNotEqual(
                shortcut.modifiers & commandOrControl,
                0,
                "\(shortcut.displayString) must not observe ordinary typing"
            )
        }
    }

    func testLegacyTextHistoryEntryDecodesAfterImageSupportIsAdded() throws {
        let id = UUID()
        let capturedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let legacyEntry = """
        {"id":"\(id.uuidString)","text":"hello","capturedAt":\(capturedAt.timeIntervalSince1970)}
        """

        let decoded = try JSONDecoder().decode(
            ClipboardHistoryEntry.self,
            from: Data(legacyEntry.utf8)
        )

        XCTAssertEqual(decoded.id, id)
        XCTAssertEqual(decoded.text, "hello")
        XCTAssertNil(decoded.image)
    }

    func testImageHistoryEntryHasAnImageLabelAndIcon() {
        let image = ClipboardHistoryImage(
            fileName: "image-00000000-0000-0000-0000-000000000000.bin",
            pasteboardType: "public.png",
            byteCount: 1_024,
            pixelWidth: 400,
            pixelHeight: 300,
            fingerprint: "abc"
        )
        let entry = ClipboardHistoryEntry(image: image)

        XCTAssertTrue(entry.isImage)
        XCTAssertEqual(entry.kindIcon, "photo.on.rectangle")
        XCTAssertTrue(entry.preview.contains("400 × 300"))
    }
}
