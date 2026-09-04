// UsageAnalysisView.swift
// ApexUninstaller
// App Usage Analysis View

import SwiftUI
import AppKit

struct UsageAnalysisView: View {
    let viewModel: AppViewModel
    let localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var analysisResult: UsageAnalysisResult?
    @State private var isAnalyzing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Content
            if isAnalyzing {
                analyzingView
            } else if let result = analysisResult {
                analysisContent(result)
            } else {
                emptyState
            }
        }
        .onAppear {
            analyzeUsage()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.localized("usage.title"))
                    .font(.title2.bold())
                if let result = analysisResult {
                    Text(localization.localized("usage.appsAnalyzed", result.totalAnalyzed))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            
            Button {
                analyzeUsage()
            } label: {
                Label(localization.localized("usage.refresh"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            
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
        .padding()
    }
    
    // MARK: - Analyzing View
    
    private var analyzingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text(localization.localized("usage.analyzing"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            Text(localization.localized("usage.scanFirst"))
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Analysis Content
    
    private func analysisContent(_ result: UsageAnalysisResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Summary Cards
                summaryCards(result)
                
                // Unused Apps Section (Red zone)
                if !result.unusedOver3Months.isEmpty {
                    unusedAppsSection(
                        title: localization.localized("usage.unusedOver3Months"),
                        apps: result.unusedOver3Months,
                        color: .red,
                        icon: "clock.badge.xmark"
                    )
                }
                
                if !result.unused1to3Months.isEmpty {
                    unusedAppsSection(
                        title: localization.localized("usage.unused1to3Months"),
                        apps: result.unused1to3Months,
                        color: .orange,
                        icon: "clock.badge.exclamationmark"
                    )
                }
                
                // Recently Used Section
                if !result.recentlyUsed.isEmpty {
                    recentlyUsedSection(result.recentlyUsed)
                }
                
                // Used Within Month Section
                if !result.withinMonth.isEmpty {
                    usedWithinMonthSection(result.withinMonth)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Summary Cards
    
    private func summaryCards(_ result: UsageAnalysisResult) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            SummaryCard(
                title: localization.localized("usage.unusedOver3Months"),
                value: "\(result.unusedOver3Months.count)",
                subtitle: result.unusedOver3Months.reduce(0) { $0 + $1.appInfo.totalSize }.formattedSize,
                color: .red,
                icon: "clock.badge.xmark"
            )
            
            SummaryCard(
                title: localization.localized("usage.unused1to3Months"),
                value: "\(result.unused1to3Months.count)",
                subtitle: result.unused1to3Months.reduce(0) { $0 + $1.appInfo.totalSize }.formattedSize,
                color: .orange,
                icon: "clock.badge.exclamationmark"
            )
            
            SummaryCard(
                title: localization.localized("usage.potentialSavings"),
                value: result.potentialSavings.formattedSize,
                subtitle: "\(result.unusedCount) apps",
                color: .green,
                icon: "externaldrive.fill"
            )
        }
    }
    
    // MARK: - Unused Apps Section
    
    private func unusedAppsSection(title: String, apps: [AppUsageInfo], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text(localization.localized("usage.appCount", apps.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(apps) { info in
                UsageAppRow(info: info, localization: localization, showActions: true)
            }
        }
        .padding()
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Recently Used Section
    
    private func recentlyUsedSection(_ apps: [AppUsageInfo]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundStyle(.green)
                Text(localization.localized("usage.recentlyUsed"))
                    .font(.headline)
                Spacer()
                Text(localization.localized("usage.appCount", apps.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(apps.prefix(10)) { info in
                        CompactAppCard(info: info, localization: localization)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Used Within Month Section
    
    private func usedWithinMonthSection(_ apps: [AppUsageInfo]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.blue)
                Text(localization.localized("usage.usedWithinMonth"))
                    .font(.headline)
                Spacer()
                Text(localization.localized("usage.appCount", apps.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(apps.prefix(5)) { info in
                UsageAppRow(info: info, localization: localization, showActions: false)
            }
            
            if apps.count > 5 {
                Text(localization.localized("usage.moreApps", apps.count - 5))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 44)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Analyze
    
    private func analyzeUsage() {
        guard !viewModel.apps.isEmpty else { return }
        isAnalyzing = true
        
        Task {
            let apps = viewModel.apps
            let result = await Task.detached(priority: .userInitiated) {
                AppUsageAnalyzer.shared.analyzeUsage(for: apps)
            }.value
            
            await MainActor.run {
                self.analysisResult = result
                self.isAnalyzing = false
            }
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Usage App Row

struct UsageAppRow: View {
    let info: AppUsageInfo
    let localization: LocalizationManager
    let showActions: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: info.appInfo.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(info.appInfo.name)
                    .font(.system(.subheadline, weight: .medium))
                    .lineLimit(1)
                
                if info.daysUnused > 0 {
                    Text(localization.localized("usage.daysUnused", info.daysUnused))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(localization.localized("usage.recentlyUsed"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(info.appInfo.totalSize.formattedSize)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Compact App Card

struct CompactAppCard: View {
    let info: AppUsageInfo
    let localization: LocalizationManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: info.appInfo.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(info.appInfo.name)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 70)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
