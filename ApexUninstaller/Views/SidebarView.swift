// SidebarView.swift
// ApexUninstaller
//
// Sidebar hiển thị danh sách ứng dụng đã quét với tìm kiếm và sắp xếp.
// Hỗ trợ đa ngôn ngữ qua LocalizationManager.

import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: AppViewModel
    let localization: LocalizationManager
    
    var body: some View {
        VStack(spacing: 0) {
            sidebarHeader
            
            Divider()
            
            if viewModel.isScanning {
                ScanProgressView(
                    progress: viewModel.scanProgress,
                    appName: viewModel.scanningAppName,
                    isLeftoverScan: false,
                    localization: localization
                )
            } else if viewModel.apps.isEmpty {
                emptyState
            } else {
                appList
                
                if viewModel.isBatchSelectMode {
                    batchActionBar
                }
            }
        }
        .frame(minWidth: 280, idealWidth: 300, maxWidth: 350)
        .confirmationDialog(
            localization.localized("batch.confirm.title"),
            isPresented: $viewModel.showBatchUninstallConfirmation,
            titleVisibility: .visible
        ) {
            Button(localization.localized("batch.confirm.button"), role: .destructive) {
                viewModel.performBatchUninstall()
            }
            Button(localization.localized("uninstall.cancel"), role: .cancel) {}
        } message: {
            Text(localization.localized(
                "batch.confirm.message",
                viewModel.batchSelectedAppIDs.count,
                viewModel.batchUninstallTotalSize.formattedSize
            ))
        }
    }
    
    // MARK: - Header
    
    private var sidebarHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.localized("sidebar.title"))
                        .font(.title3.bold())
                    
                    if !viewModel.apps.isEmpty {
                        Text(sidebarSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if !viewModel.apps.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.toggleBatchSelectMode()
                        }
                    } label: {
                        Image(systemName: viewModel.isBatchSelectMode ? "checkmark.circle.fill" : "checklist")
                            .font(.system(size: 16))
                            .foregroundStyle(viewModel.isBatchSelectMode ? DesignTokens.accentPrimary : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .help(localization.localized("batch.selectMode.help"))
                }
                
                if !viewModel.apps.isEmpty {
                    Menu {
                        sortButton(.nameAsc, localization.localized("sort.nameAsc"))
                        sortButton(.nameDesc, localization.localized("sort.nameDesc"))
                        Divider()
                        sortButton(.sizeDesc, localization.localized("sort.sizeDesc"))
                        sortButton(.sizeAsc, localization.localized("sort.sizeAsc"))
                        Divider()
                        sortButton(.leftoverCount, localization.localized("sort.leftoverCount"))
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24)
                }
                
                Button {
                    viewModel.scanApplications()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isScanning)
                .help(localization.localized("scan.rescanAll"))
            }
            
            if viewModel.totalReclaimableSize > 0 && !viewModel.isScanningAllLeftovers {
                HStack(spacing: 6) {
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.accentPrimary)
                    Text(localization.localized("sidebar.reclaimable", viewModel.totalReclaimableSize.compactSize))
                        .font(.system(.caption2, weight: .medium))
                        .foregroundStyle(DesignTokens.accentPrimary)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func sortButton(_ order: AppSortOrder, _ title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.sortOrder = order
            }
        } label: {
            Label(title, systemImage: order.icon)
        }
        .disabled(viewModel.sortOrder == order)
    }
    
    // MARK: - App List
    
    @ViewBuilder
    private var appList: some View {
        if viewModel.isBatchSelectMode {
            List {
                ForEach(viewModel.filteredApps) { app in
                    batchAppRow(app)
                }
            }
            .listStyle(.sidebar)
            .searchable(
                text: $viewModel.searchText,
                placement: .sidebar,
                prompt: localization.localized("sidebar.search")
            )
        } else {
            List(viewModel.filteredApps, selection: $viewModel.selectedAppID) { app in
                AppRowView(
                    app: app,
                    isSelected: viewModel.selectedAppID == app.id,
                    isScanningLeftovers: viewModel.isScanningAllLeftovers && !app.hasScannedLeftovers
                )
                .tag(app.id)
            }
            .listStyle(.sidebar)
            .searchable(
                text: $viewModel.searchText,
                placement: .sidebar,
                prompt: localization.localized("sidebar.search")
            )
        }
    }
    
    private func batchAppRow(_ app: AppInfo) -> some View {
        Toggle(isOn: Binding(
            get: { viewModel.batchSelectedAppIDs.contains(app.id) },
            set: { isOn in
                if isOn {
                    viewModel.batchSelectedAppIDs.insert(app.id)
                } else {
                    viewModel.batchSelectedAppIDs.remove(app.id)
                }
            }
        )) {
            AppRowView(
                app: app,
                isSelected: viewModel.batchSelectedAppIDs.contains(app.id),
                isScanningLeftovers: viewModel.isScanningAllLeftovers && !app.hasScannedLeftovers
            )
        }
        .toggleStyle(.checkbox)
    }
    
    private var batchActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                Menu {
                    Button(localization.localized("batch.selectAll")) {
                        viewModel.selectAllBatchApps()
                    }
                    Button(localization.localized("batch.deselectAll")) {
                        viewModel.deselectAllBatchApps()
                    }
                } label: {
                    Text("\(viewModel.batchSelectedAppIDs.count) \(localization.localized("detail.selected"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                
                Spacer()
                
                if viewModel.isUninstalling && !viewModel.batchUninstallProgress.isEmpty {
                    ProgressView()
                        .controlSize(.small)
                }
                
                Button {
                    viewModel.checkAndBatchUninstall()
                } label: {
                    Label(localization.localized("batch.uninstall"), systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
                .disabled(viewModel.batchSelectedAppIDs.isEmpty || viewModel.isUninstalling)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "app.dashed")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            
            Text(localization.localized("sidebar.emptyTitle"))
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(localization.localized("sidebar.emptySubtitle"))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.scanApplications()
            } label: {
                Label(localization.localized("sidebar.scanButton"), systemImage: "magnifyingglass")
                    .font(.system(.body, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(DesignTokens.accentPrimary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var sidebarSubtitle: String {
        var parts = ["\(viewModel.filteredApps.count) \(localization.localized("sidebar.appCount"))", viewModel.totalAppsSize.compactSize]
        if viewModel.isScanningAllLeftovers {
            parts.append("\(viewModel.leftoverScanCompletedCount)/\(viewModel.apps.count)")
        }
        return parts.joined(separator: " • ")
    }
}
