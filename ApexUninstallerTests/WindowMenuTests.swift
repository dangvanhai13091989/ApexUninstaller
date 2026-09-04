// WindowMenuTests.swift
// ApexUninstallerTests

import AppKit
import XCTest
@testable import ApexUninstaller

final class WindowMenuTests: XCTestCase {
    @MainActor
    func testMainMenuContainsPersistentReopenCommand() throws {
        let item = try XCTUnwrap(findMenuItem(
            titled: "Open ApexUninstaller",
            in: NSApp.mainMenu
        ))

        XCTAssertEqual(item.keyEquivalent, "0")
        XCTAssertTrue(item.keyEquivalentModifierMask.contains(.command))
    }

    @MainActor
    private func findMenuItem(titled title: String, in menu: NSMenu?) -> NSMenuItem? {
        guard let menu else { return nil }

        for item in menu.items {
            if item.title == title {
                return item
            }
            if let match = findMenuItem(titled: title, in: item.submenu) {
                return match
            }
        }

        return nil
    }
}
