// LeftoverCategoryTests.swift
// ApexUninstallerTests
// Unit tests for leftover categories

import XCTest
@testable import ApexUninstaller

final class LeftoverCategoryTests: XCTestCase {
    
    func testLeftoverCategoryIcons() {
        XCTAssertEqual(LeftoverCategory.applicationSupport.icon, "folder.fill")
        XCTAssertEqual(LeftoverCategory.caches.icon, "internaldrive.fill")
        XCTAssertEqual(LeftoverCategory.preferences.icon, "gearshape.fill")
        XCTAssertEqual(LeftoverCategory.containers.icon, "shippingbox.fill")
        XCTAssertEqual(LeftoverCategory.launchAgents.icon, "bolt.horizontal.circle.fill")
        XCTAssertEqual(LeftoverCategory.logs.icon, "doc.text.fill")
        XCTAssertEqual(LeftoverCategory.savedState.icon, "clock.arrow.circlepath")
    }
    
    func testLeftoverCategoryColors() {
        XCTAssertEqual(LeftoverCategory.applicationSupport.color, .purple)
        XCTAssertEqual(LeftoverCategory.caches.color, .orange)
        XCTAssertEqual(LeftoverCategory.preferences.color, .blue)
        XCTAssertEqual(LeftoverCategory.containers.color, .green)
        XCTAssertEqual(LeftoverCategory.launchAgents.color, .pink)
        XCTAssertEqual(LeftoverCategory.logs.color, .gray)
        XCTAssertEqual(LeftoverCategory.savedState.color, .cyan)
    }
    
    func testLeftoverCategoryLocalizationKeys() {
        XCTAssertEqual(LeftoverCategory.applicationSupport.localizationKey, "category.appSupport")
        XCTAssertEqual(LeftoverCategory.caches.localizationKey, "category.caches")
        XCTAssertEqual(LeftoverCategory.preferences.localizationKey, "category.preferences")
        XCTAssertEqual(LeftoverCategory.containers.localizationKey, "category.containers")
        XCTAssertEqual(LeftoverCategory.launchAgents.localizationKey, "category.launchAgents")
        XCTAssertEqual(LeftoverCategory.logs.localizationKey, "category.logs")
        XCTAssertEqual(LeftoverCategory.savedState.localizationKey, "category.savedState")
    }
    
    func testLeftoverCategoryIdentifiable() {
        for category in LeftoverCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }
    
    func testAllCategoriesExist() {
        let allCategories = LeftoverCategory.allCases
        XCTAssertEqual(allCategories.count, 7)
    }
}
