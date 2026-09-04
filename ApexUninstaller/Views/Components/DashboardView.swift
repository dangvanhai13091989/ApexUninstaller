// DashboardView.swift
// ApexUninstaller
// Disk Space Overview Dashboard

import SwiftUI
import AppKit

struct DashboardView: View {
    let viewModel: AppViewModel
    let localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ApexUninstaller.largeLeftoverThresholdMB") private var largeThresholdMB = 100
    
    private var stats: DiskSpaceStats {
        calculateStats()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Quick Stats Cards
                if !viewModel.apps.isEmpty {
                    quickStatsGrid
                    
                    // Top Junk Apps
                    topJunkAppsSection
                    
                    // Category Breakdown
                    categoryBreakdownSection
                    
                    // Large Leftovers
                    largeLeftoversSection
                } else {
                    emptyState
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.localized("dashboard.title"))
                    .font(.title.bold())
                if let lastScan = stats.lastScanDate {
                    Text("\(localization.localized("dashboard.lastScan")): \(lastScan.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                viewModel.scanApplications()
            } label: {
                Label(localization.localized("sidebar.scanButton"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignTokens.accentPrimary)
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
    }
    
    // MARK: - Quick Stats Grid
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: localization.localized("dashboard.totalApps"),
                value: "\(stats.totalApps)",
                icon: "app.fill",
                color: .blue
            )
            
            StatCard(
                title: localization.localized("dashboard.totalJunk"),
                value: stats.totalJunkSize.formattedSize,
                icon: "doc.badge.gearshape.fill",
                color: .orange
            )
            
            StatCard(
                title: localization.localized("dashboard.orphanJunk"),
                value: stats.orphanSize.formattedSize,
                icon: "sparkles",
                color: .purple
            )
            
            StatCard(
                title: localization.localized("usage.potentialSavings"),
                value: stats.totalAppSize.formattedSize,
                icon: "externaldrive.fill",
                color: .green
            )
        }
    }
    
    // MARK: - Top Junk Apps
    
    private var topJunkAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized("dashboard.topJunkApps"))
                .font(.headline)
            
            ForEach(stats.topLeftoverApps.prefix(5)) { app in
                TopJunkAppRow(app: app, localization: localization)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized("dashboard.categoryBreakdown"))
                .font(.headline)
            
            ForEach(stats.categoryBreakdown) { cat in
                CategoryBreakdownRow(category: cat, localization: localization)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Large Leftovers
    
    private var largeLeftoversSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localization.localized("dashboard.largeLeftovers", largeThresholdBytes.formattedSize))
                    .font(.headline)
                Spacer()
            }
            
            let largeApps = stats.topLeftoverApps.filter { $0.hasLargeLeftovers }
            
            if largeApps.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.green)
                        Text(localization.localized("dashboard.noLargeLeftovers"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                ForEach(largeApps.prefix(5)) { app in
                    LargeLeftoverRow(app: app, localization: localization)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            Text(localization.localized("dashboard.noData"))
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Calculate Stats
    
    private func calculateStats() -> DiskSpaceStats {
        guard !viewModel.apps.isEmpty else {
            return .empty
        }
        
        let totalApps = viewModel.apps.count
        let totalJunkSize = viewModel.apps.reduce(0) { $0 + $1.leftoverSize }
        let totalAppSize = viewModel.apps.reduce(0) { $0 + $1.appSize }
        let orphanSize = viewModel.orphanedGroups.reduce(0) { $0 + $1.totalSize }
        
        // Top junk apps
        let topApps = viewModel.apps
            .filter { $0.hasScannedLeftovers && !$0.leftovers.isEmpty }
            .sorted { $0.leftoverSize > $1.leftoverSize }
            .prefix(10)
            .map { app in
                AppJunkInfo(
                    id: app.id,
                    appName: app.name,
                    bundleIdentifier: app.bundleIdentifier,
                    icon: app.icon,
                    junkSize: app.leftoverSize,
                    leftoverCount: app.leftovers.count,
                    hasLargeLeftovers: app.leftovers.contains { $0.size > largeThresholdBytes }
                )
            }
        
        // Category breakdown
        var categoryTotals: [LeftoverCategory: (size: UInt64, count: Int)] = [:]
        for app in viewModel.apps {
            for leftover in app.leftovers {
                let current = categoryTotals[leftover.category] ?? (0, 0)
                categoryTotals[leftover.category] = (current.size + leftover.size, current.count + 1)
            }
        }
        
        let categoryBreakdown = LeftoverCategory.allCases.compactMap { cat -> CategoryJunkInfo? in
            guard let data = categoryTotals[cat], data.size > 0 else { return nil }
            let percentage = totalJunkSize > 0 ? Double(data.size) / Double(totalJunkSize) * 100 : 0
            return CategoryJunkInfo(
                id: cat.rawValue,
                category: cat,
                totalSize: data.size,
                itemCount: data.count,
                percentage: percentage
            )
        }.sorted { $0.totalSize > $1.totalSize }
        
        return DiskSpaceStats(
            totalApps: totalApps,
            totalJunkSize: totalJunkSize,
            totalAppSize: totalAppSize,
            orphanSize: orphanSize,
            topLeftoverApps: Array(topApps),
            categoryBreakdown: categoryBreakdown,
            lastScanDate: Date()
        )
    }

    private var largeThresholdBytes: UInt64 {
        UInt64(largeThresholdMB) * 1024 * 1024
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Top Junk App Row

struct TopJunkAppRow: View {
    let app: AppJunkInfo
    let localization: LocalizationManager
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.system(.subheadline, weight: .medium))
                    .lineLimit(1)
                Text("\(app.leftoverCount) \(localization.localized("detail.leftovers"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(app.junkSize.formattedSize)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Breakdown Row

struct CategoryBreakdownRow: View {
    let category: CategoryJunkInfo
    let localization: LocalizationManager
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: category.category.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(category.category.color)
                    .frame(width: 20)
                Text(localization.localized(category.category.localizationKey))
                    .font(.caption)
                Spacer()
                Text(category.totalSize.formattedSize)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                Text("(\(category.itemCount) \(localization.localized("dashboard.items")))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(category.category.color)
                        .frame(width: geo.size.width * min(category.percentage / 100, 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Large Leftover Row

struct LargeLeftoverRow: View {
    let app: AppJunkInfo
    let localization: LocalizationManager
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.system(.subheadline, weight: .medium))
                    .lineLimit(1)
                Text(localization.localized("usage.suggestUninstall"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(app.junkSize.formattedSize)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.red)
        }
        .padding(.vertical, 4)
    }
}
