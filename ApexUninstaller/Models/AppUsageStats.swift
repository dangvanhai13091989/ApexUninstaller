// AppUsageStats.swift
// ApexUninstaller
// Models for App Usage Analysis

import Foundation
import AppKit

struct AppUsageInfo: Identifiable {
    let id: UUID
    let appInfo: AppInfo
    let lastUsedDate: Date?
    let usageLevel: UsageLevel
    let daysUnused: Int
    
    enum UsageLevel: String {
        case recentlyUsed = "Recently Used"
        case usedWithinMonth = "Used Within 30 Days"
        case unused1to3Months = "Unused 1-3 Months"
        case unusedOver3Months = "Unused Over 3 Months"
        case unknown = "Unknown"
        
        var color: NSColor {
            switch self {
            case .recentlyUsed: return .systemGreen
            case .usedWithinMonth: return .systemBlue
            case .unused1to3Months: return .systemOrange
            case .unusedOver3Months: return .systemRed
            case .unknown: return .systemGray
            }
        }
        
        var icon: String {
            switch self {
            case .recentlyUsed: return "clock.badge.checkmark"
            case .usedWithinMonth: return "clock"
            case .unused1to3Months: return "clock.badge.exclamationmark"
            case .unusedOver3Months: return "clock.badge.xmark"
            case .unknown: return "clock.dotted"
            }
        }
    }
}

struct UsageAnalysisResult {
    let recentlyUsed: [AppUsageInfo]
    let withinMonth: [AppUsageInfo]
    let unused1to3Months: [AppUsageInfo]
    let unusedOver3Months: [AppUsageInfo]
    let unknown: [AppUsageInfo]
    let totalAnalyzed: Int
    
    var unusedCount: Int {
        unused1to3Months.count + unusedOver3Months.count
    }
    
    var potentialSavings: UInt64 {
        (unused1to3Months + unusedOver3Months).reduce(0) { $0 + $1.appInfo.totalSize }
    }
}
