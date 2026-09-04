// FileSizeExtensionTests.swift
// ApexUninstallerTests
// Unit tests for FileSize extensions

import XCTest
@testable import ApexUninstaller

final class FileSizeExtensionTests: XCTestCase {
    
    func testFormattedSizeBytes() {
        let size: UInt64 = 512
        XCTAssertTrue(size.formattedSize.contains("512"))
    }
    
    func testFormattedSizeKilobytes() {
        let size: UInt64 = 1024
        XCTAssertEqual(size.formattedSize, "1 KB")
    }
    
    func testFormattedSizeMegabytes() {
        let size: UInt64 = 1024 * 1024
        XCTAssertEqual(size.formattedSize, "1 MB")
    }
    
    func testFormattedSizeGigabytes() {
        let size: UInt64 = 1024 * 1024 * 1024
        XCTAssertTrue(size.formattedSize.contains("GB"))
    }
    
    func testFormattedSizeLargeValue() {
        let size: UInt64 = 5 * 1024 * 1024 * 1024
        XCTAssertTrue(size.formattedSize.contains("GB"))
    }
    
    func testCompactSize() {
        let size: UInt64 = 5 * 1024 * 1024 * 1024
        let compact = size.compactSize
        XCTAssertTrue(compact.contains("GB") || compact.contains("5"))
    }
    
    func testZeroSize() {
        let size: UInt64 = 0
        XCTAssertFalse(size.formattedSize.isEmpty)
    }
}
