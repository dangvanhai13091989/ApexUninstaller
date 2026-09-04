// DetailView.swift
// ApexUninstaller - IMPROVED: running app warning, better error UI, retry/reveal buttons

import SwiftUI

struct DetailView: View {
    @Bindable var viewModel: AppViewModel
    let localization: LocalizationManager
    
    private var app: AppInfo? { viewModel.selectedApp }
    
    var body: some View {
        Group {
            if let app = app {
                VStack(spacing: 0) {
                    appHeader(app)
                    appInsightsBar(app)
                    Divider()
                    
                    if !app.hasScannedLeftovers || viewModel.isScanningLeftovers {
                        // Đang scan hoặc chưa scan
                        scanningView
                    } else if app.leftovers.isEmpty {
                        cleanView
                    } else {
                        leftoverListView(app)
                    }
                }
                .confirmationDialog(
                    localization.localized(viewModel.pendingRemovalMode == .reset ? "reset.confirm.title" : "uninstall.confirm.title"),
                    isPresented: $viewModel.showUninstallConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(localization.localized(viewModel.pendingRemovalMode == .reset ? "reset.confirm.button" : "uninstall.confirm.button"), role: .destructive) {
                        viewModel.performUninstall()
                    }
                    Button(localization.localized("uninstall.cancel"), role: .cancel) {}
                } message: {
                    Text(confirmMsg(app))
                }
                .alert(
                    localization.localized("running.title", viewModel.runningAppName),
                    isPresented: $viewModel.showRunningAppWarning
                ) {
                    Button(localization.localized("running.quitContinue"), role: .destructive) {
                        viewModel.quitAndConfirmUninstall()
                    }
                    Button(localization.localized("running.uninstallAnyway")) {
                        viewModel.performUninstall()
                    }
                    Button(localization.localized("uninstall.cancel"), role: .cancel) {}
                } message: {
                    Text(localization.localized("running.message", viewModel.runningAppName))
                }
            }
        }
        .task(id: viewModel.selectedAppID) {
            await viewModel.scanLeftoversIfNeeded()
        }
    }
    
    // MARK: - Header
    private func appHeader(_ app: AppInfo) -> some View {
        HStack(spacing: 14) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name).font(.title3.bold()).lineLimit(1)
                Text(app.bundleIdentifier)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary).lineLimit(1)
                HStack(spacing: 12) {
                    Label(app.appSize.formattedSize, systemImage: "app.fill")
                        .font(.caption).foregroundStyle(.secondary)
                    if app.hasScannedLeftovers {
                        Label(
                            "\(app.leftovers.count) \(localization.localized("detail.leftovers"))",
                            systemImage: "doc.badge.gearshape"
                        )
                        .font(.caption)
                        .foregroundStyle(app.leftovers.isEmpty ? .green : .orange)
                        
                        if app.reviewRequiredLeftoverCount > 0 {
                            Label(
                                "\(app.reviewRequiredLeftoverCount) \(localization.localized("confidence.review"))",
                                systemImage: LeftoverConfidence.review.icon
                            )
                            .font(.caption)
                            .foregroundStyle(LeftoverConfidence.review.color)
                        }
                    }
                }
            }
            
            Spacer()
            
            if app.hasScannedLeftovers {
                HStack(spacing: 8) {
                    Button {
                        viewModel.exportSelectedAppReport(localization: localization)
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .help(localization.localized("detail.exportReport"))
                    
                    Button {
                        viewModel.ignoreSelectedApp()
                    } label: {
                        Image(systemName: "eye.slash")
                    }
                    .buttonStyle(.bordered)
                    .help(localization.localized("detail.ignore"))
                    
                    if !app.leftovers.isEmpty {
                        Button {
                            viewModel.checkAndReset()
                        } label: {
                            Label(localization.localized("detail.reset"), systemImage: "arrow.counterclockwise")
                                .font(.system(.subheadline, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .disabled(viewModel.isUninstalling)
                    }
                    
                    Button {
                        viewModel.checkAndUninstall()
                    } label: {
                        Label(localization.localized("detail.uninstall"), systemImage: "trash")
                            .font(.system(.subheadline, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent).tint(.red)
                    .disabled(viewModel.isUninstalling)
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(.bar)
    }
    
    private func appInsightsBar(_ app: AppInfo) -> some View {
        HStack(spacing: 8) {
            insightPill(
                icon: "number",
                title: localization.localized("insights.version"),
                value: versionText(app),
                color: .blue
            )
            insightPill(
                icon: app.installSource == .appStore ? "bag.fill" : "globe",
                title: localization.localized("insights.source"),
                value: localization.localized(app.installSource.localizationKey),
                color: app.installSource == .appStore ? .green : .orange
            )
            if let minimumSystemVersion = app.minimumSystemVersion {
                insightPill(
                    icon: "macwindow",
                    title: localization.localized("insights.minOS"),
                    value: minimumSystemVersion,
                    color: .purple
                )
            }
            if let lastModified = app.lastModified {
                insightPill(
                    icon: "calendar",
                    title: localization.localized("insights.modified"),
                    value: lastModified.formatted(date: .abbreviated, time: .omitted),
                    color: .gray
                )
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.bar)
    }
    
    private func insightPill(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.11)))
    }
    
    private func versionText(_ app: AppInfo) -> String {
        if let build = app.buildVersion, build != app.version {
            return "\(app.version) (\(build))"
        }
        return app.version
    }
    
    // MARK: - Scanning
    private var scanningView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().controlSize(.large)
            Text(localization.localized("detail.scanning"))
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var cleanView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44)).foregroundStyle(.green.gradient)
            Text(localization.localized("detail.cleanApp")).font(.headline)
            Text(localization.localized("detail.noLeftovers"))
                .font(.caption).foregroundStyle(.secondary)
            
            // Vẫn cho phép xoá app bundle dù không có leftover
            Button {
                viewModel.includeAppBundle = true
                viewModel.checkAndUninstall()
            } label: {
                Label(localization.localized("detail.uninstall"), systemImage: "trash")
                    .font(.system(.subheadline, weight: .semibold))
            }
            .buttonStyle(.borderedProminent).tint(.red)
            .disabled(viewModel.isUninstalling)
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Leftover List
    private func leftoverListView(_ app: AppInfo) -> some View {
        VStack(spacing: 0) {
            // Controls
            HStack(spacing: 8) {
                Toggle(isOn: $viewModel.includeAppBundle) {
                    Label(localization.localized("detail.removeApp"), systemImage: "app.badge.checkmark")
                        .font(.caption)
                }
                .toggleStyle(.checkbox)
                
                Spacer()
                
                Button(localization.localized("detail.selectRecommended")) {
                    viewModel.selectRecommendedLeftovers()
                }
                .buttonStyle(.borderless).font(.caption)
                
                Button(localization.localized("detail.selectAll")) {
                    viewModel.selectAllLeftovers()
                }
                .buttonStyle(.borderless).font(.caption)
                
                Button(localization.localized("detail.deselectAll")) {
                    viewModel.deselectAllLeftovers()
                }
                .buttonStyle(.borderless).font(.caption)
                
                Text("\(app.selectedLeftoverCount) \(localization.localized("detail.selected"))")
                    .font(.caption2).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(.secondary.opacity(0.1)))
                
                if app.selectedReviewLeftoverCount > 0 {
                    Label("\(app.selectedReviewLeftoverCount)", systemImage: LeftoverConfidence.review.icon)
                        .font(.caption2)
                        .foregroundStyle(LeftoverConfidence.review.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(LeftoverConfidence.review.color.opacity(0.12)))
                        .help(localization.localized("detail.reviewSelectedHelp"))
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(.bar)
            
            Divider()
            
            // List
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(LeftoverCategory.allCases) { cat in
                        let items = app.leftovers.filter { $0.category == cat }
                        if !items.isEmpty {
                            categorySection(cat: cat, items: items)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
    
    private func categorySection(cat: LeftoverCategory, items: [LeftoverFile]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: cat.icon).font(.system(size: 11)).foregroundStyle(cat.color)
                Text(localization.localized(cat.localizationKey))
                    .font(.system(.caption, weight: .semibold)).foregroundStyle(cat.color)
                Text("(\(items.count) \(localization.localized("dashboard.items")))").font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Text(items.reduce(0) { $0 + $1.size }.formattedSize)
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            .padding(.top, 8).padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                ForEach(items) { leftover in
                    LeftoverRowView(leftover: leftover, localization: localization) {
                        viewModel.toggleLeftover(leftover.id)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.3)))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func confirmMsg(_ app: AppInfo) -> String {
        let count = app.selectedLeftoverCount
        let size = (viewModel.includeAppBundle ? app.appSize : 0) + app.selectedLeftoverSize
        if viewModel.pendingRemovalMode == .reset {
            var message = "\(count) \(localization.localized("detail.leftovers"))\n\(localization.localized("detail.total")): \(size.formattedSize)"
            if app.selectedReviewLeftoverCount > 0 {
                message += "\n\(localization.localized("detail.reviewWarning"))"
            }
            return message
        }
        
        if count == 0 && viewModel.includeAppBundle {
            return "\(app.name)\n\(localization.localized("detail.total")): \(size.formattedSize)"
        }
        var message = "\(viewModel.includeAppBundle ? app.name + " + " : "")\(count) \(localization.localized("detail.leftovers"))\n\(localization.localized("detail.total")): \(size.formattedSize)"
        if app.selectedReviewLeftoverCount > 0 {
            message += "\n\(localization.localized("detail.reviewWarning"))"
        }
        return message
    }
}

// MARK: - Uninstall Results Sheet — IMPROVED

struct UninstallResultsSheet: View {
    let results: [UninstallResult]
    let localization: LocalizationManager
    let onRetry: (URL) -> Void
    let onReveal: (URL) -> Void
    let onDismiss: () -> Void
    
    private var ok: Int { results.filter { $0.success }.count }
    private var fail: Int { results.filter { !$0.success }.count }
    private var failedResults: [UninstallResult] { results.filter { !$0.success } }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header icon
            Image(systemName: fail == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(fail == 0 ? .green : .orange)
            
            // Title
            Text(fail == 0
                 ? localization.localized("uninstall.success")
                 : localization.localized("uninstall.partial"))
                .font(.headline)
            
            // Count badge
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                    Text(localization.localized("results.succeeded", ok)).font(.subheadline).foregroundStyle(.secondary)
                }
                if fail > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption).foregroundStyle(.red)
                        Text(localization.localized("results.failed", fail)).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            
            // Failed items — với action buttons
            if !failedResults.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text(localization.localized("results.failedItems"))
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color.red.opacity(0.08))
                    
                    Divider().opacity(0.3)
                    
                    // Each failed item
                    ForEach(failedResults) { result in
                        failedItemRow(result)
                        if result.id != failedResults.last?.id {
                            Divider().opacity(0.2).padding(.leading, 40)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.15), lineWidth: 1)
                )
            }
            
            // Tip
            Text(fail == 0
                 ? localization.localized("uninstall.trashInfo")
                 : localization.localized("results.manualTip"))
                .font(.caption2).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            // Close button
            Button(localization.localized("uninstall.close")) {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 420)
    }
    
    // MARK: - Failed Item Row
    
    private func failedItemRow(_ result: UninstallResult) -> some View {
        HStack(spacing: 10) {
            // Icon based on failure reason
            Image(systemName: result.failureReason?.icon ?? "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.red.opacity(0.8))
                .frame(width: 24)
            
            // File info
            VStack(alignment: .leading, spacing: 3) {
                Text(result.originalPath.lastPathComponent)
                    .font(.system(.caption, weight: .semibold))
                    .lineLimit(1)
                
                Text(result.failureReason?.localizedMessage(using: localization) ?? result.error ?? localization.localized("results.unknownError"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Path
                Text(abbreviatePath(result.originalPath))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 4) {
                // Retry button
                Button {
                    onRetry(result.originalPath)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help(localization.localized("results.retry"))
                
                // Reveal in Finder button
                Button {
                    onReveal(result.originalPath)
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help(localization.localized("results.reveal"))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }
    
    /// Rút gọn path cho dễ đọc
    private func abbreviatePath(_ url: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let fullPath = url.path
        if fullPath.hasPrefix(home) {
            return "~" + fullPath.dropFirst(home.count)
        }
        return fullPath
    }
}
