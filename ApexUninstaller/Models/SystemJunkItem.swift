// SystemJunkItem.swift
// ApexUninstaller
// Model for system junk items (browser cache, logs, temp files)

import Foundation
import SwiftUI


struct SystemJunkDetail: Identifiable, Hashable {
    let path: URL
    let size: UInt64
    let itemCount: Int

    var id: String { path.standardizedFileURL.resolvingSymlinksInPath().path }
    var displayName: String { path.lastPathComponent.isEmpty ? path.path : path.lastPathComponent }

    var relativePath: String {
        let home = realUserHomeDirectory.path
        let fullPath = path.path
        if fullPath.hasPrefix(home) { return "~" + fullPath.dropFirst(home.count) }
        return fullPath
    }


}

struct SystemJunkItem: Identifiable, Hashable {
    let category: SystemJunkCategory
    let path: URL
    let paths: [URL]
    let details: [SystemJunkDetail]
    let size: UInt64
    let itemCount: Int
    let description: String
    
    var id: String { category.rawValue }
    
    var displayName: String { category.displayName }
    var icon: String { category.icon }
    var color: SystemJunkColor { category.color }
    
    var relativePath: String {
        let home = realUserHomeDirectory.path
        let fullPath = path.path
        if fullPath.hasPrefix(home) { return "~" + fullPath.dropFirst(home.count) }
        return fullPath
    }

    init(
        category: SystemJunkCategory,
        path: URL,
        size: UInt64,
        itemCount: Int,
        description: String,
        paths: [URL]? = nil,
        details: [SystemJunkDetail]? = nil
    ) {
        self.category = category
        self.path = path
        self.details = details ?? [SystemJunkDetail(path: path, size: size, itemCount: itemCount)]
        self.paths = paths ?? self.details.map(\.path)
        self.size = size
        self.itemCount = itemCount
        self.description = description
    }

}

enum SystemJunkCategory: String, CaseIterable, Identifiable {
    case browserCache = "Browser Cache"
    case systemCache = "System Cache"
    case applicationCache = "Application Cache"
    case logs = "System Logs"
    case tempFiles = "Temporary Files"
    case xcodeDerivedData = "Xcode Derived Data"
    case fontCaches = "Font Caches"
    case thumbnailCaches = "Thumbnail Caches"
    
    var id: String { rawValue }

    var localizationKey: String {
        "systemJunk.category.\(localizationSuffix)"
    }

    var descriptionLocalizationKey: String {
        "systemJunk.category.\(localizationSuffix).description"
    }

    private var localizationSuffix: String {
        switch self {
        case .browserCache: return "browserCache"
        case .systemCache: return "systemCache"
        case .applicationCache: return "applicationCache"
        case .logs: return "logs"
        case .tempFiles: return "tempFiles"
        case .xcodeDerivedData: return "xcodeDerivedData"
        case .fontCaches: return "fontCaches"
        case .thumbnailCaches: return "thumbnailCaches"
        }
    }
    
    var displayName: String {
        switch self {
        case .browserCache: return "Browser Cache"
        case .systemCache: return "System Cache"
        case .applicationCache: return "App Caches"
        case .logs: return "System Logs"
        case .tempFiles: return "Temporary Files"
        case .xcodeDerivedData: return "Xcode Build Data"
        case .fontCaches: return "Font Caches"
        case .thumbnailCaches: return "Thumbnail Cache"
        }
    }
    
    var icon: String {
        switch self {
        case .browserCache: return "globe"
        case .systemCache: return "internaldrive"
        case .applicationCache: return "app.badge"
        case .logs: return "doc.text"
        case .tempFiles: return "clock"
        case .xcodeDerivedData: return "hammer"
        case .fontCaches: return "textformat"
        case .thumbnailCaches: return "photo"
        }
    }
    
    var color: SystemJunkColor {
        switch self {
        case .browserCache: return SystemJunkColor(light: .blue, dark: .cyan)
        case .systemCache: return SystemJunkColor(light: .orange, dark: .orange)
        case .applicationCache: return SystemJunkColor(light: .purple, dark: .purple)
        case .logs: return SystemJunkColor(light: .gray, dark: .gray)
        case .tempFiles: return SystemJunkColor(light: .yellow, dark: .yellow)
        case .xcodeDerivedData: return SystemJunkColor(light: .indigo, dark: .indigo)
        case .fontCaches: return SystemJunkColor(light: .pink, dark: .pink)
        case .thumbnailCaches: return SystemJunkColor(light: .cyan, dark: .cyan)
        }
    }
    
    var estimatedSafeToDelete: Bool {
        switch self {
        case .browserCache, .systemCache, .applicationCache, .tempFiles, .logs, .thumbnailCaches, .fontCaches, .xcodeDerivedData:
            return true
        }
    }
}

struct SystemJunkColor {
    let light: Color
    let dark: Color
    
    init(light: SystemJunkColorPreset, dark: SystemJunkColorPreset) {
        self.light = light.color
        self.dark = dark.color
    }
}

enum SystemJunkColorPreset: String {
    case blue, orange, purple, gray, yellow, green, red, indigo, pink, cyan

    var color: Color {
        switch self {
        case .blue: return .blue
        case .orange: return .orange
        case .purple: return .purple
        case .gray: return .gray
        case .yellow: return .yellow
        case .green: return .green
        case .red: return .red
        case .indigo: return .indigo
        case .pink: return .pink
        case .cyan: return .cyan
        }
    }
}

struct SystemJunkScanResult {
    var items: [SystemJunkItem] = []
    var totalSize: UInt64 = 0
    var isComplete: Bool = false
    
    var safeToDeleteSize: UInt64 {
        items.filter { $0.category.estimatedSafeToDelete }.reduce(0) { $0 + $1.size }
    }
    
    var needsConfirmationSize: UInt64 {
        items.filter { !$0.category.estimatedSafeToDelete }.reduce(0) { $0 + $1.size }
    }
}
