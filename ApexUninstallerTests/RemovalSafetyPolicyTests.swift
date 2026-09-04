import XCTest
@testable import ApexUninstaller

final class RemovalSafetyPolicyTests: XCTestCase {
    func testBlocksFilesystemAndUserRoots() {
        XCTAssertFalse(RemovalSafetyPolicy.canMoveToTrash(URL(fileURLWithPath: "/")))
        XCTAssertFalse(RemovalSafetyPolicy.canMoveToTrash(URL(fileURLWithPath: "/Applications")))
        XCTAssertFalse(RemovalSafetyPolicy.canMoveToTrash(realUserHomeDirectory))
        XCTAssertFalse(RemovalSafetyPolicy.canMoveToTrash(realUserHomeDirectory.appendingPathComponent("Library")))
    }

    func testBlocksProtectedSystemContent() {
        XCTAssertFalse(RemovalSafetyPolicy.canMoveToTrash(URL(fileURLWithPath: "/System/Applications/Safari.app")))
        XCTAssertFalse(RemovalSafetyPolicy.canMoveToTrash(URL(fileURLWithPath: "/usr/bin/swift")))
        XCTAssertFalse(RemovalSafetyPolicy.canMoveToTrash(URL(fileURLWithPath: "/private/var/db/example")))
    }

    func testAllowsNormalAppsAndUserLibraryChildren() {
        XCTAssertTrue(RemovalSafetyPolicy.canMoveToTrash(URL(fileURLWithPath: "/Applications/Example.app")))
        XCTAssertTrue(RemovalSafetyPolicy.canMoveToTrash(
            realUserHomeDirectory.appendingPathComponent("Library/Caches/com.example.app")
        ))
    }
}
