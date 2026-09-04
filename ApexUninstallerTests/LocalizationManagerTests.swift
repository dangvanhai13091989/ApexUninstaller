// LocalizationManagerTests.swift
// ApexUninstallerTests
// Unit tests for localization

import XCTest
@testable import ApexUninstaller

final class LocalizationManagerTests: XCTestCase {
    
    func testLocalizationKeysExist() {
        // Test that key localization strings exist
        XCTAssertNotNil(L10n.string("sidebar.title", language: .english))
        XCTAssertNotNil(L10n.string("detail.uninstall", language: .english))
        XCTAssertNotNil(L10n.string("detail.reset", language: .english))
        XCTAssertNotNil(L10n.string("dashboard.title", language: .english))
        XCTAssertNotNil(L10n.string("usage.title", language: .english))
    }
    
    func testLocalizationFallbackToEnglish() {
        let key = "nonexistent.key"
        let result = L10n.string(key, language: .vietnamese)
        // Should fall back to English
        XCTAssertEqual(result, key)
    }
    
    func testAllLanguagesHaveSidebarTitle() {
        for language in AppLanguage.allCases {
            let title = L10n.string("sidebar.title", language: language)
            XCTAssertFalse(title.isEmpty, "sidebar.title should exist for \(language)")
        }
    }
    
    func testAllLanguagesHaveDetailUninstall() {
        for language in AppLanguage.allCases {
            let uninstall = L10n.string("detail.uninstall", language: language)
            XCTAssertFalse(uninstall.isEmpty, "detail.uninstall should exist for \(language)")
        }
    }

    func testAllLanguagesHaveUsageRefresh() {
        for language in AppLanguage.allCases {
            let refresh = L10n.string("usage.refresh", language: language)
            XCTAssertFalse(refresh.isEmpty, "usage.refresh should exist for \(language)")
            XCTAssertNotEqual(refresh, "usage.refresh", "usage.refresh should not fall back to raw key for \(language)")
        }
    }
    
    func testAppLanguageDisplayNames() {
        XCTAssertEqual(AppLanguage.english.displayName, "English")
        XCTAssertEqual(AppLanguage.vietnamese.displayName, "Tiếng Việt")
        XCTAssertEqual(AppLanguage.japanese.displayName, "日本語")
        XCTAssertEqual(AppLanguage.korean.displayName, "한국어")
        XCTAssertEqual(AppLanguage.chinese.displayName, "简体中文")
        XCTAssertEqual(AppLanguage.french.displayName, "Français")
        XCTAssertEqual(AppLanguage.german.displayName, "Deutsch")
        XCTAssertEqual(AppLanguage.spanish.displayName, "Español")
    }
    
    func testAppLanguageFlags() {
        XCTAssertEqual(AppLanguage.english.flag, "🇺🇸")
        XCTAssertEqual(AppLanguage.vietnamese.flag, "🇻🇳")
        XCTAssertEqual(AppLanguage.japanese.flag, "🇯🇵")
    }
    
    func testParameterizedLocalization() {
        let result = L10n.string("usage.daysUnused", language: .english, 30)
        XCTAssertTrue(result.contains("30"))
    }
}
