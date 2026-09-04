// AppUsageAnalyzer.swift
// ApexUninstaller
// Service to analyze app usage based on last access dates

import Foundation
import AppKit

final class AppUsageAnalyzer {
    
    static let shared = AppUsageAnalyzer()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    /// Analyze app usage by checking access/modification dates
    func analyzeUsage(for apps: [AppInfo]) -> UsageAnalysisResult {
        var recentlyUsed: [AppUsageInfo] = []
        var withinMonth: [AppUsageInfo] = []
        var unused1to3Months: [AppUsageInfo] = []
        var unusedOver3Months: [AppUsageInfo] = []
        var unknown: [AppUsageInfo] = []
        
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        
        for app in apps {
            let usageInfo = analyzeSingleApp(app, thirtyDaysAgo: thirtyDaysAgo, threeMonthsAgo: threeMonthsAgo)
            
            switch usageInfo.usageLevel {
            case .recentlyUsed:
                recentlyUsed.append(usageInfo)
            case .usedWithinMonth:
                withinMonth.append(usageInfo)
            case .unused1to3Months:
                unused1to3Months.append(usageInfo)
            case .unusedOver3Months:
                unusedOver3Months.append(usageInfo)
            case .unknown:
                unknown.append(usageInfo)
            }
        }
        
        return UsageAnalysisResult(
            recentlyUsed: recentlyUsed,
            withinMonth: withinMonth,
            unused1to3Months: unused1to3Months,
            unusedOver3Months: unusedOver3Months,
            unknown: unknown,
            totalAnalyzed: apps.count
        )
    }
    
    private func analyzeSingleApp(_ app: AppInfo, thirtyDaysAgo: Date, threeMonthsAgo: Date) -> AppUsageInfo {
        // Try to get last used date from recent items
        let lastUsedDate = getLastUsedDate(for: app)
        let daysUnused: Int
        
        if let lastUsed = lastUsedDate {
            daysUnused = Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day ?? 0
        } else {
            // Fall back to bundle modification date
            daysUnused = -1 // Unknown
        }
        
        let usageLevel: AppUsageInfo.UsageLevel
        if daysUnused < 0 {
            usageLevel = .unknown
        } else if daysUnused == 0 {
            usageLevel = .recentlyUsed
        } else if daysUnused <= 30 {
            usageLevel = .usedWithinMonth
        } else if daysUnused <= 90 {
            usageLevel = .unused1to3Months
        } else {
            usageLevel = .unusedOver3Months
        }
        
        return AppUsageInfo(
            id: app.id,
            appInfo: app,
            lastUsedDate: lastUsedDate,
            usageLevel: usageLevel,
            daysUnused: max(0, daysUnused)
        )
    }
    
    /// Get last used date by checking recent documents and app bundle access date
    private func getLastUsedDate(for app: AppInfo) -> Date? {
        var latestDate: Date?
        
        // Check app bundle access date, then fall back to modification date.
        if let accessDate = try? app.path.resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate {
            latestDate = accessDate
        } else if let modifiedDate = try? fileManager.attributesOfItem(atPath: app.path.path)[.modificationDate] as? Date {
            latestDate = modifiedDate
        }
        
        // Check ~/Library/Application Support for app data modification
        let appSupportPath = realUserHomeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent(app.name)
        
        if let appSupportDate = try? fileManager.attributesOfItem(atPath: appSupportPath.path)[.modificationDate] as? Date {
            if let current = latestDate {
                latestDate = max(current, appSupportDate)
            } else {
                latestDate = appSupportDate
            }
        }
        
        // Return the most recent date found
        return latestDate
    }
}
