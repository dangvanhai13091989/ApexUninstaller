// UninstallResultTests.swift
// ApexUninstallerTests
// Unit tests for uninstall result handling

import XCTest
@testable import ApexUninstaller

final class UninstallResultTests: XCTestCase {
    
    func testUninstallResultSuccess() {
        let url = URL(fileURLWithPath: "/Applications/TestApp.app")
        let trashURL = URL(fileURLWithPath: "~/.Trash/TestApp.app")
        
        let result = UninstallResult(
            originalPath: url,
            trashPath: trashURL,
            success: true,
            error: nil
        )
        
        XCTAssertTrue(result.success)
        XCTAssertNil(result.error)
        XCTAssertNotNil(result.trashPath)
    }
    
    func testUninstallResultFailure() {
        let url = URL(fileURLWithPath: "/Applications/TestApp.app")
        
        let result = UninstallResult(
            originalPath: url,
            trashPath: nil,
            success: false,
            error: "Permission denied",
            failureReason: .permissionDenied
        )
        
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.error, "Permission denied")
        XCTAssertEqual(result.failureReason, .permissionDenied)
    }
    
    func testFailureReasonUserMessage() {
        let runningReason = FailureReason.appIsRunning(appName: "TestApp")
        XCTAssertTrue(runningReason.userMessage.contains("TestApp"))
        
        let permissionReason = FailureReason.permissionDenied
        XCTAssertFalse(permissionReason.userMessage.isEmpty)
        
        let fileInUseReason = FailureReason.fileInUse
        XCTAssertFalse(fileInUseReason.userMessage.isEmpty)

        let unsafeReason = FailureReason.unsafePath
        XCTAssertFalse(unsafeReason.userMessage.isEmpty)
    }
    
    func testFailureReasonIcon() {
        XCTAssertEqual(FailureReason.appIsRunning(appName: "Test").icon, "app.badge.fill")
        XCTAssertEqual(FailureReason.permissionDenied.icon, "lock.fill")
        XCTAssertEqual(FailureReason.unsafePath.icon, "shield.slash.fill")
        XCTAssertEqual(FailureReason.fileInUse.icon, "lock.rotation")
        XCTAssertEqual(FailureReason.fileNotFound.icon, "questionmark.folder")
        XCTAssertEqual(FailureReason.unknown.icon, "exclamationmark.triangle.fill")
    }
    
    func testUninstallErrorDescription() {
        let noItemsError = UninstallError.noItemsSelected
        XCTAssertEqual(noItemsError.errorDescription, "No items selected")
        
        let runningError = UninstallError.appIsRunning(name: "TestApp")
        XCTAssertTrue(runningError.errorDescription?.contains("TestApp") ?? false)
    }
}
