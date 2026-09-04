// MainView.swift
// ApexUninstaller
// View chính - App Store version. Không trial, dùng BookmarkManager.

import SwiftUI
import UniformTypeIdentifiers
import AppKit
import Darwin

struct MainView: View {
    @Binding var viewModel: AppViewModel
    @Binding var bookmarkManager: BookmarkManager
    @State private var localization = LocalizationManager()
    @State private var isDropTarget = false
    @State private var showSettings = false
    @State private var showDuplicateFinder = false
    @State private var showDashboard = false
    @State private var showUsageAnalysis = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Library access banner (nếu chưa cấp quyền)
            if !bookmarkManager.hasLibraryAccess {
                accessBanner
            }
            
            NavigationSplitView {
                SidebarView(viewModel: viewModel, localization: localization)
            } detail: {
                if viewModel.selectedApp != nil {
                    DetailView(viewModel: viewModel, localization: localization)
                } else {
                    EmptyStateView(hasApps: !viewModel.apps.isEmpty, localization: localization)
                }
            }
            .navigationSplitViewStyle(.balanced)
        }
        .frame(minWidth: 900, minHeight: 600)
        .overlay {
            if isDropTarget {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignTokens.accentPrimary, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                    .padding(16)
                    .background(DesignTokens.accentPrimary.opacity(0.08))
            }
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTarget) { providers in
            handleDroppedFiles(providers)
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $bookmarkManager.showAccessOnboarding) {
            OnboardingSheet(bookmarkManager: bookmarkManager, localization: localization)
        }
        .sheet(isPresented: $viewModel.showOrphanedLeftovers) {
            OrphanedLeftoversSheet(viewModel: viewModel, localization: localization)
        }
        .sheet(isPresented: $viewModel.showCleanupHistory) {
            CleanupHistorySheet(viewModel: viewModel, localization: localization)
        }
        .sheet(isPresented: $viewModel.showIgnoredApps) {
            IgnoredAppsSheet(viewModel: viewModel, localization: localization)
        }
        .sheet(isPresented: $viewModel.showSystemJunk) {
            SystemJunkView(localization: localization, bookmarkManager: bookmarkManager)
        }
        .sheet(isPresented: $showDuplicateFinder) {
            DuplicateFinderView(localization: localization, bookmarkManager: bookmarkManager)
        }
        .sheet(isPresented: $showDashboard) {
            DashboardView(viewModel: viewModel, localization: localization)
                .frame(width: 860, height: 620)
        }
        .sheet(isPresented: $showUsageAnalysis) {
            UsageAnalysisView(viewModel: viewModel, localization: localization)
                .frame(width: 820, height: 620)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(localization: localization)
        }
        .sheet(isPresented: $viewModel.showUninstallResults, onDismiss: {
            viewModel.cleanupAfterUninstall()
        }) {
            if let results = viewModel.uninstallResults {
                UninstallResultsSheet(
                    results: results,
                    localization: localization,
                    onRetry: { url in viewModel.retryFailedItem(at: url) },
                    onReveal: { url in viewModel.revealInFinder(url: url) },
                    onDismiss: { viewModel.showUninstallResults = false }
                )
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text(localization.localized("detail.scanning"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 300, height: 200)
            }
        }
        .alert(localization.localized("error.title"),
               isPresented: .init(get: { viewModel.errorMessage != nil || viewModel.errorMessageKey != nil },
                                  set: { if !$0 { viewModel.clearError() } })) {
            Button(localization.localized("error.ok")) { viewModel.clearError() }
        } message: {
            Text(viewModel.resolvedErrorMessage(using: localization))
        }
        .onAppear {
            viewModel.bookmarkManager = bookmarkManager
            if !bookmarkManager.hasLibraryAccess {
                bookmarkManager.showAccessOnboarding = true
            }
            viewModel.scanApplications()
        }
        .onChange(of: bookmarkManager.hasLibraryAccess) { _, hasAccess in
            if hasAccess {
                viewModel.scanAllLeftoversInBackground(force: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .menuBarTriggerScanReceived)) { _ in
            showSettings = false
            viewModel.scanApplications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .menuBarTriggerOrphansReceived)) { _ in
            showSettings = false
            viewModel.openOrphanedLeftovers()
        }
        .onReceive(NotificationCenter.default.publisher(for: .menuBarTriggerHistoryReceived)) { _ in
            showSettings = false
            viewModel.showCleanupHistory = true
        }
    }
    
    // MARK: - Access Banner
    private var accessBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 14)).foregroundStyle(.orange)
            Text(localization.localized("access.limited")).font(.system(.caption, weight: .medium)).foregroundStyle(.orange)
            Spacer()
            Button {
                Task { @MainActor in
                    if bookmarkManager.requestLibraryAccess() {
                        viewModel.scanAllLeftoversInBackground(force: true)
                    }
                }
            } label: {
                Text(localization.localized("access.grant")).font(.system(.caption, weight: .semibold))
            }.buttonStyle(.borderedProminent).tint(DesignTokens.accentPrimary).controlSize(.small)
        }.padding(.horizontal, 16).padding(.vertical, 8).background(Color.orange.opacity(0.08))
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button { viewModel.openOrphanedLeftovers() } label: {
                Label(localization.localized("toolbar.orphans"), systemImage: "sparkle.magnifyingglass")
            }
            .disabled(!bookmarkManager.hasLibraryAccess)
            .help(localization.localized("toolbar.orphans.help"))
        }
        ToolbarItem(placement: .automatic) {
            Button { viewModel.showCleanupHistory = true } label: {
                Label(localization.localized("toolbar.history"), systemImage: "clock.arrow.circlepath")
            }
            .help(localization.localized("toolbar.history.help"))
        }
        ToolbarItem(placement: .automatic) {
            Button { viewModel.showIgnoredApps = true } label: {
                Label(localization.localized("toolbar.ignored"), systemImage: "eye.slash")
            }
            .help(localization.localized("toolbar.ignored.help"))
        }
        ToolbarItem(placement: .automatic) {
            Menu {
                ForEach(AppLanguage.allCases) { lang in
                    Button { withAnimation { localization.currentLanguage = lang } } label: {
                        HStack {
                            Text("\(lang.flag) \(lang.displayName)")
                            if localization.currentLanguage == lang { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) { Text(localization.currentLanguage.flag); Image(systemName: "chevron.down").font(.system(size: 8)) }
            }.help(localization.localized("settings.language"))
        }
        ToolbarItem(placement: .automatic) {
            HStack(spacing: 6) {
                Circle().fill(bookmarkManager.hasLibraryAccess ? Color.green : Color.orange).frame(width: 8, height: 8)
                Text(bookmarkManager.hasLibraryAccess ? localization.localized("status.libraryGranted") : localization.localized("fda.limited"))
                    .font(.caption).foregroundStyle(.secondary)
            }.onTapGesture { if !bookmarkManager.hasLibraryAccess { bookmarkManager.showAccessOnboarding = true } }
        }
        ToolbarItemGroup(placement: .automatic) {
            Button { viewModel.showSystemJunk = true } label: {
                Label(localization.localized("systemJunk.title"), systemImage: "sparkles")
            }
            .help(localization.localized("systemJunk.title"))

            Button { showDuplicateFinder = true } label: {
                Label(localization.localized("duplicate.title"), systemImage: "doc.on.doc")
            }
            .help(localization.localized("duplicate.title"))

            Button { showDashboard = true } label: {
                Label(localization.localized("toolbar.dashboard"), systemImage: "chart.pie")
            }
            .disabled(viewModel.apps.isEmpty)
            .help(localization.localized("toolbar.dashboard.help"))

            Button { showUsageAnalysis = true } label: {
                Label(localization.localized("toolbar.usage"), systemImage: "clock.badge.questionmark")
            }
            .disabled(viewModel.apps.isEmpty)
            .help(localization.localized("toolbar.usage.help"))
        }
        ToolbarItem(placement: .automatic) {
            Button { showSettings = true } label: {
                Label(localization.localized("toolbar.settings"), systemImage: "gearshape")
            }
            .help(localization.localized("toolbar.settings.help"))
        }
        ToolbarItem(placement: .automatic) {
            Menu {
                if !suggestedAppLocations().isEmpty {
                    Section(localization.localized("scanLocations.suggested")) {
                        ForEach(suggestedAppLocations(), id: \.path) { url in
                            Button {
                                Task { @MainActor in
                                    if bookmarkManager.requestAdditionalAppLocationAccess(startingAt: url) {
                                        viewModel.scanApplications()
                                    }
                                }
                            } label: {
                                Label(pathLabel(for: url), systemImage: "folder")
                            }
                        }
                    }

                    Divider()
                }

                Button {
                    Task { @MainActor in
                        if bookmarkManager.requestAdditionalAppLocationAccess() {
                            viewModel.scanApplications()
                        }
                    }
                } label: {
                    Label(localization.localized("scanLocations.add"), systemImage: "folder.badge.plus")
                }

                if !bookmarkManager.additionalAppLocationURLs.isEmpty {
                    Divider()

                    ForEach(bookmarkManager.additionalAppLocationURLs, id: \.path) { url in
                        Menu(pathLabel(for: url)) {
                            Button {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            } label: {
                                Label(localization.localized("results.reveal"), systemImage: "folder")
                            }

                            Button(role: .destructive) {
                                bookmarkManager.removeAdditionalAppLocation(url)
                                viewModel.scanApplications()
                            } label: {
                                Label(localization.localized("scanLocations.remove"), systemImage: "minus.circle")
                            }
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        bookmarkManager.clearAdditionalAppLocations()
                        viewModel.scanApplications()
                    } label: {
                        Label(localization.localized("scanLocations.clear"), systemImage: "trash")
                    }
                }
            } label: {
                Label(localization.localized("scanLocations.title"), systemImage: "folder.badge.gearshape")
            }
            .help(localization.localized("scanLocations.help"))
        }
        ToolbarItem(placement: .automatic) {
            Button { viewModel.scanApplications() } label: {
                Label(localization.localized("scan.rescan"), systemImage: "arrow.clockwise")
            }.disabled(viewModel.isScanning)
        }
    }

    private func pathLabel(for url: URL) -> String {
        let home = realUserHomeDirectory.path
        let path = url.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private func suggestedAppLocations() -> [URL] {
        let fileManager = FileManager.default
        let candidates: [URL] = [
            URL(fileURLWithPath: "/Users/Shared", isDirectory: true),
            realUserHomeDirectory.appendingPathComponent("Games", isDirectory: true),
            realUserHomeDirectory.appendingPathComponent("Library/Application Support/Steam/steamapps/common", isDirectory: true)
        ]

        let granted = Set(bookmarkManager.additionalAppLocationURLs.map { normalizedPath($0) })
        var seen: Set<String> = []
        return candidates.filter { url in
            var isDir: ObjCBool = false
            let key = normalizedPath(url)
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir),
                  isDir.boolValue,
                  !granted.contains(key),
                  seen.insert(key).inserted else {
                return false
            }
            return true
        }
    }




    private func normalizedPath(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path
    }

    private func handleDroppedFiles(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let nsURL = item as? NSURL {
                url = nsURL as URL
            } else if let string = item as? String {
                url = URL(string: string)
            } else {
                url = nil
            }
            
            if let url {
                Task { @MainActor in
                    viewModel.importDroppedApplication(at: url)
                }
            }
        }
        
        return true
    }
}

struct CleanupHistorySheet: View {
    @Bindable var viewModel: AppViewModel
    let localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(localization.localized("history.title"), systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                if !viewModel.cleanupHistory.isEmpty {
                    Button(localization.localized("history.clear")) {
                        viewModel.clearCleanupHistory()
                    }
                    .buttonStyle(.borderless)
                        .foregroundStyle(.red)
                }
                Button(localization.localized("uninstall.close")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            
            Divider()
            
            if viewModel.cleanupHistory.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text(localization.localized("history.empty"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 520, height: 260)
            } else {
                List(viewModel.cleanupHistory) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: entry.operation))
                            .font(.system(size: 16))
                            .foregroundStyle(color(for: entry.operation))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.appName)
                                .font(.system(.body, weight: .medium))
                                .lineLimit(1)
                            Text("\(localization.localized(entry.operation.localizationKey)) • \(entry.date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(entry.reclaimedSize.formattedSize)
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                            Text("\(entry.removedItemCount) \(localization.localized("history.itemsOk", entry.removedItemCount))\(entry.failedItemCount > 0 ? " • \(localization.localized("history.itemsFailed", entry.failedItemCount))" : "")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(width: 560, height: 360)
            }
        }
    }
    
    private func icon(for operation: CleanupOperation) -> String {
        switch operation {
        case .uninstall: return "trash"
        case .reset: return "arrow.counterclockwise"
        case .orphaned: return "sparkle.magnifyingglass"
        }
    }
    
    private func color(for operation: CleanupOperation) -> Color {
        switch operation {
        case .uninstall: return .red
        case .reset: return .orange
        case .orphaned: return DesignTokens.accentPrimary
        }
    }
}

struct IgnoredAppsSheet: View {
    @Bindable var viewModel: AppViewModel
    let localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(localization.localized("ignored.title"), systemImage: "eye.slash")
                    .font(.headline)
                Spacer()
                if !viewModel.ignoredBundleIDs.isEmpty {
                    Button(localization.localized("ignored.restoreAll")) {
                        viewModel.clearIgnoredApps()
                    }
                    .buttonStyle(.borderless)
                }
                Button(localization.localized("uninstall.close")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            
            Divider()
            
            if viewModel.ignoredBundleIDs.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "eye")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text(localization.localized("ignored.empty"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 520, height: 240)
            } else {
                List(Array(viewModel.ignoredBundleIDs).sorted(), id: \.self) { bundleID in
                    HStack(spacing: 10) {
                        Image(systemName: "app.dashed")
                            .foregroundStyle(.secondary)
                        Text(bundleID)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                        Spacer()
                        Button(localization.localized("ignored.restore")) {
                            viewModel.restoreIgnoredApp(bundleIdentifier: bundleID)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }
                .frame(width: 560, height: 320)
            }
        }
    }
}

struct OrphanedLeftoversSheet: View {
    @Bindable var viewModel: AppViewModel
    let localization: LocalizationManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label(localization.localized("orphans.title"), systemImage: "sparkle.magnifyingglass")
                    .font(.headline)
                Spacer()
                Button(localization.localized("scan.rescan")) {
                    viewModel.scanOrphanedLeftovers()
                }
                .disabled(viewModel.isScanningOrphans)
                Button(localization.localized("detail.selectRecommended")) {
                    viewModel.selectRecommendedOrphans()
                }
                Button(localization.localized("detail.selectAll")) {
                    viewModel.selectAllOrphans()
                }
                Button(localization.localized("detail.deselectAll")) {
                    viewModel.deselectAllOrphans()
                }
            }
            .padding(16)
            
            Divider()
            
            if viewModel.isScanningOrphans {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.large)
                    Text(localization.localized("orphans.scanning"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 680, height: 360)
            } else if viewModel.orphanedGroups.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    Text(localization.localized("orphans.empty"))
                        .font(.headline)
                    Text(localization.localized("orphans.empty.desc"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 680, height: 360)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(viewModel.orphanedGroups) { group in
                            orphanGroup(group)
                        }
                    }
                    .padding(16)
                }
                .frame(width: 720, height: 420)
            }
            
            Divider()
            
            HStack {
                Text("\(viewModel.selectedOrphanedCount) \(localization.localized("detail.selected")) • \(viewModel.selectedOrphanedSize.formattedSize)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(localization.localized("uninstall.cancel")) {
                    viewModel.showOrphanedLeftovers = false
                }
                .keyboardShortcut(.cancelAction)
                Button {
                    viewModel.performOrphanedCleanup()
                } label: {
                    Label(localization.localized("orphans.cleanSelected"), systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(viewModel.selectedOrphanedCount == 0 || viewModel.isUninstalling)
            }
            .padding(16)
        }
    }
    
    private func orphanGroup(_ group: OrphanedLeftoverGroup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.displayName)
                        .font(.system(.subheadline, weight: .semibold))
                    Text("\(group.leftovers.count) \(localization.localized("detail.leftovers")) • \(group.totalSize.formattedSize)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(group.id.replacingOccurrences(of: "bundle:", with: "").replacingOccurrences(of: "name:", with: ""))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 1) {
                ForEach(group.leftovers) { leftover in
                    LeftoverRowView(leftover: leftover, localization: localization) {
                        viewModel.toggleOrphanedLeftover(groupID: group.id, leftoverID: leftover.id)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.3)))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
