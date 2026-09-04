// ApexUninstallerTests.swift
// ApexUninstallerTests
// Unit tests for core functionality

import XCTest
@testable import ApexUninstaller

final class AppModelTests: XCTestCase {
    
    func testLeftoverFileInitialization() {
        let url = URL(fileURLWithPath: "/Users/test/Library/Application Support/TestApp")
        let leftover = LeftoverFile(
            path: url,
            size: 1024 * 1024,
            category: .applicationSupport,
            confidence: .high,
            matchReason: "Test match"
        )
        
        XCTAssertEqual(leftover.path, url)
        XCTAssertEqual(leftover.size, 1024 * 1024)
        XCTAssertEqual(leftover.category, .applicationSupport)
        XCTAssertEqual(leftover.confidence, .high)
        XCTAssertEqual(leftover.matchReason, "Test match")
    }
    
    func testLeftoverFileDefaultSelection() {
        let url = URL(fileURLWithPath: "/Users/test/test")
        
        // High confidence should be selected by default
        let highConfidence = LeftoverFile(path: url, size: 100, category: .caches, confidence: .high)
        XCTAssertTrue(highConfidence.isSelected)
        
        // Medium confidence should be selected by default
        let mediumConfidence = LeftoverFile(path: url, size: 100, category: .caches, confidence: .medium)
        XCTAssertTrue(mediumConfidence.isSelected)
        
        // Review confidence should NOT be selected by default
        let reviewConfidence = LeftoverFile(path: url, size: 100, category: .caches, confidence: .review)
        XCTAssertFalse(reviewConfidence.isSelected)
    }
    
    func testLeftoverConfidenceIsRecommended() {
        XCTAssertTrue(LeftoverConfidence.high.isRecommended)
        XCTAssertTrue(LeftoverConfidence.medium.isRecommended)
        XCTAssertFalse(LeftoverConfidence.review.isRecommended)
    }
    
    func testLeftoverCategoryLibrarySubpath() {
        XCTAssertEqual(LeftoverCategory.applicationSupport.librarySubpath, "Application Support")
        XCTAssertEqual(LeftoverCategory.caches.librarySubpath, "Caches")
        XCTAssertEqual(LeftoverCategory.preferences.librarySubpath, "Preferences")
        XCTAssertEqual(LeftoverCategory.launchAgents.librarySubpath, "LaunchAgents")
        XCTAssertEqual(LeftoverCategory.logs.librarySubpath, "Logs")
    }
    
    func testLeftoverFileRelativePath() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let fullPath = home + "/Library/Application Support/TestApp"
        let url = URL(fileURLWithPath: fullPath)
        
        let leftover = LeftoverFile(path: url, size: 100, category: .applicationSupport)
        let relative = leftover.relativePath
        
        XCTAssertTrue(relative.hasPrefix("~"))
        XCTAssertTrue(relative.contains("Library"))
    }
}
