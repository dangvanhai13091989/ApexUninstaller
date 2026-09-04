// LeftoverConfidenceTests.swift
// ApexUninstallerTests
// Unit tests for leftover confidence levels

import XCTest
@testable import ApexUninstaller

final class LeftoverConfidenceTests: XCTestCase {
    
    func testConfidenceIsRecommended() {
        XCTAssertTrue(LeftoverConfidence.high.isRecommended)
        XCTAssertTrue(LeftoverConfidence.medium.isRecommended)
        XCTAssertFalse(LeftoverConfidence.review.isRecommended)
    }
    
    func testConfidenceLocalizationKeys() {
        XCTAssertEqual(LeftoverConfidence.high.localizationKey, "confidence.high")
        XCTAssertEqual(LeftoverConfidence.medium.localizationKey, "confidence.medium")
        XCTAssertEqual(LeftoverConfidence.review.localizationKey, "confidence.review")
    }
    
    func testConfidenceIcons() {
        XCTAssertEqual(LeftoverConfidence.high.icon, "checkmark.shield.fill")
        XCTAssertEqual(LeftoverConfidence.medium.icon, "shield.lefthalf.filled")
        XCTAssertEqual(LeftoverConfidence.review.icon, "exclamationmark.triangle.fill")
    }
    
    func testConfidenceColors() {
        XCTAssertEqual(LeftoverConfidence.high.color, .green)
        XCTAssertEqual(LeftoverConfidence.medium.color, .blue)
        XCTAssertEqual(LeftoverConfidence.review.color, .orange)
    }
    
    func testAllConfidenceLevelsExist() {
        let allLevels = LeftoverConfidence.allCases
        XCTAssertEqual(allLevels.count, 3)
    }
    
    func testConfidenceIdentifiable() {
        for confidence in LeftoverConfidence.allCases {
            XCTAssertEqual(confidence.id, confidence.rawValue)
        }
    }
}
