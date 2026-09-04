// DiskSpaceStats.swift
// ApexUninstaller
// Models for Disk Space Dashboard statistics

import Foundation
import AppKit

struct DiskSpaceStats {
    let totalApps: Int
    let totalJunkSize: UInt64
    let totalAppSize: UInt64
    let orphanSize: UInt64
    let topLeftoverApps: [AppJunkInfo]
    let categoryBreakdown: [CategoryJunkInfo]
    let lastScanDate: Date?
    
    static var empty: DiskSpaceStats {
        DiskSpaceStats(
            totalApps: 0,
            totalJunkSize: 0,
            totalAppSize: 0,
            orphanSize: 0,
            topLeftoverApps: [],
            categoryBreakdown: [],
            lastScanDate: nil
        )
    }
}

struct AppJunkInfo: Identifiable {
    let id: UUID
    let appName: String
    let bundleIdentifier: String
    let icon: NSImage?
    let junkSize: UInt64
    let leftoverCount: Int
    let hasLargeLeftovers: Bool
}

struct CategoryJunkInfo: Identifiable {
    let id: String
    let category: LeftoverCategory
    let totalSize: UInt64
    let itemCount: Int
    let percentage: Double
}
