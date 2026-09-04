// LeftoverFile.swift
// ApexUninstaller
// Data model cho tệp tin rác. Category displayName giờ dùng localization key.

import Foundation
import SwiftUI

struct LeftoverFile: Identifiable, Hashable {
    let id: UUID
    let path: URL
    let size: UInt64
    let category: LeftoverCategory
    let confidence: LeftoverConfidence
    let matchReason: String
    var isSelected: Bool
    
    var displayName: String { path.lastPathComponent }
    
    var relativePath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let fullPath = path.path
        if fullPath.hasPrefix(home) { return "~" + fullPath.dropFirst(home.count) }
        return fullPath
    }
    
    init(
        id: UUID = UUID(),
        path: URL,
        size: UInt64,
        category: LeftoverCategory,
        confidence: LeftoverConfidence = .high,
        matchReason: String = "",
        isSelected: Bool? = nil
    ) {
        self.id = id
        self.path = path
        self.size = size
        self.category = category
        self.confidence = confidence
        self.matchReason = matchReason
        self.isSelected = isSelected ?? confidence.isRecommended
    }
}

enum LeftoverConfidence: String, CaseIterable, Identifiable, Hashable {
    case high
    case medium
    case review
    
    var id: String { rawValue }
    
    var isRecommended: Bool {
        switch self {
        case .high, .medium: return true
        case .review: return false
        }
    }
    
    var localizationKey: String {
        switch self {
        case .high: return "confidence.high"
        case .medium: return "confidence.medium"
        case .review: return "confidence.review"
        }
    }
    
    var icon: String {
        switch self {
        case .high: return "checkmark.shield.fill"
        case .medium: return "shield.lefthalf.filled"
        case .review: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .blue
        case .review: return .orange
        }
    }
}

enum LeftoverCategory: String, CaseIterable, Identifiable {
    case applicationSupport = "Application Support"
    case caches = "Caches"
    case preferences = "Preferences"
    case containers = "Containers"
    case launchAgents = "Launch Agents"
    case logs = "Logs"
    case savedState = "Saved Application State"
    
    var id: String { rawValue }
    
    /// Localization key cho category name
    var localizationKey: String {
        switch self {
        case .applicationSupport: return "category.appSupport"
        case .caches: return "category.caches"
        case .preferences: return "category.preferences"
        case .containers: return "category.containers"
        case .launchAgents: return "category.launchAgents"
        case .logs: return "category.logs"
        case .savedState: return "category.savedState"
        }
    }
    
    var icon: String {
        switch self {
        case .applicationSupport: return "folder.fill"
        case .caches: return "internaldrive.fill"
        case .preferences: return "gearshape.fill"
        case .containers: return "shippingbox.fill"
        case .launchAgents: return "bolt.horizontal.circle.fill"
        case .logs: return "doc.text.fill"
        case .savedState: return "clock.arrow.circlepath"
        }
    }
    
    var color: Color {
        switch self {
        case .applicationSupport: return .purple
        case .caches: return .orange
        case .preferences: return .blue
        case .containers: return .green
        case .launchAgents: return .pink
        case .logs: return .gray
        case .savedState: return .cyan
        }
    }
    
    var librarySubpath: String {
        switch self {
        case .launchAgents: return "LaunchAgents"
        default: return rawValue
        }
    }
}
