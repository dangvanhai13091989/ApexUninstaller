// CleanupHistoryTests.swift
// ApexUninstallerTests
// Unit tests for cleanup history functionality

import XCTest
@testable import ApexUninstaller

final class CleanupHistoryTests: XCTestCase {
    
    func testCleanupHistoryEntryCreation() {
        let entry = CleanupHistoryEntry(
            appName: "TestApp",
            bundleIdentifier: "com.test.app",
            operation: .uninstall,
            removedItemCount: 5,
            failedItemCount: 1,
            reclaimedSize: 1024 * 1024 * 50
        )
        
        XCTAssertEqual(entry.appName, "TestApp")
        XCTAssertEqual(entry.bundleIdentifier, "com.test.app")
        XCTAssertEqual(entry.operation, .uninstall)
        XCTAssertEqual(entry.removedItemCount, 5)
        XCTAssertEqual(entry.failedItemCount, 1)
        XCTAssertEqual(entry.reclaimedSize, 1024 * 1024 * 50)
    }
    
    func testCleanupOperationLocalizationKey() {
        XCTAssertEqual(CleanupOperation.uninstall.localizationKey, "history.operation.uninstall")
        XCTAssertEqual(CleanupOperation.reset.localizationKey, "history.operation.reset")
        XCTAssertEqual(CleanupOperation.orphaned.localizationKey, "history.operation.orphaned")
    }
    
    func testPendingRemovalModeOperation() {
        XCTAssertEqual(PendingRemovalMode.uninstall.operation, .uninstall)
        XCTAssertEqual(PendingRemovalMode.reset.operation, .reset)
    }
}
