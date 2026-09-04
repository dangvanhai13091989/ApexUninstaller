// AppSortOrderTests.swift
// ApexUninstallerTests
// Unit tests for app sorting

import XCTest
@testable import ApexUninstaller

final class AppSortOrderTests: XCTestCase {
    
    func testAppSortOrderIcons() {
        XCTAssertEqual(AppSortOrder.nameAsc.icon, "textformat.abc")
        XCTAssertEqual(AppSortOrder.nameDesc.icon, "textformat.abc")
        XCTAssertEqual(AppSortOrder.sizeDesc.icon, "arrow.down.circle")
        XCTAssertEqual(AppSortOrder.sizeAsc.icon, "arrow.up.circle")
        XCTAssertEqual(AppSortOrder.leftoverCount.icon, "doc.badge.gearshape")
    }
    
    func testAppSortOrderIdentifiable() {
        let sortOrder = AppSortOrder.nameAsc
        XCTAssertEqual(sortOrder.id, sortOrder.rawValue)
    }
    
    func testAllSortOrdersExist() {
        let allOrders = AppSortOrder.allCases
        XCTAssertEqual(allOrders.count, 5)
    }
}
