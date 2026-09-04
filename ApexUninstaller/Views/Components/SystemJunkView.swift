// SystemJunkView.swift
// ApexUninstaller
// UI for System Junk Cleaner

import SwiftUI
import AppKit

struct SystemJunkView: View {
    let localization: LocalizationManager
    @Bindable var bookmarkManager: BookmarkManager
    @Environment(\.dismiss) private var dismiss
    @State private var scanResult: SystemJunkScanResult?
    @State private var isScanning = false
    @State private var selectedItems: Set<String> = []
    @State private var isCleaning = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var cleanedSize: UInt64 = 0
    @State private var progress: Double = 0
    @State private var expandedItems: Set<String> = []
    @State private var showCleanConfirmation = false
    
    private var selectedSize: UInt64 {
        guard let result = scanResult else { return 0 }
        return result.items
            .flatMap(\.details)
            .filter { selectedItems.contains($0.id) }
            .reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            if isScanning {
                scanningView
            } else if let result = scanResult {
                resultView(result)
            } else {
                emptyView
            }
        }
        .frame(minWidth: 620, minHeight: 480)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.localized("systemJunk.title"))
                    .font(.title2.bold())
                if let result = scanResult {
                    Text("\(result.items.count) \(localization.localized("sidebar.appCount")) • \(result.totalSize.formattedSize)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if scanResult != nil {
                Button(action: startScan) {
                    Label(localization.localized("systemJunk.scanButton"), systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .padding()
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text(localization.localized("systemJunk.scanSystem"))
                .font(.title2.bold())
            
            Text(localization.localized("systemJunk.scanDescription"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            Button(action: startScan) {
                Label(localization.localized("systemJunk.scanButton"), systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Scanning View
    
    private var scanningView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(localization.localized("systemJunk.scanningFiles"))
                .font(.headline)
            
            Text(localization.localized("systemJunk.scanningNote"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Result View
    
    private func resultView(_ result: SystemJunkScanResult) -> some View {
        VStack(spacing: 0) {
            // Summary
            summaryCard(result)
            
            Divider()
            
            // Junk items list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(result.items) { item in
                        JunkItemRow(
                            item: item,
                            selectedDetailIDs: selectedItems,
                            isExpanded: expandedItems.contains(item.id),
                            localization: localization,
                            onToggleItem: {
                                toggleSelection(item)
                            },
                            onToggleDetail: { detail in
                                toggleSelection(detail)
                            },
                            onToggleExpanded: {
                                toggleExpanded(item)
                            },
                            onReveal: { url in
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        )
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Action bar
            actionBar(result)
        }
    }
    
    // MARK: - Summary Card
    
    private func summaryCard(_ result: SystemJunkScanResult) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                metricColumn(
                    value: result.totalSize.formattedSize,
                    title: localization.localized("systemJunk.totalJunk"),
                    color: .primary
                )

                Divider()
                    .frame(height: 42)

                metricColumn(
                    value: result.safeToDeleteSize.formattedSize,
                    title: localization.localized("systemJunk.safeToDelete"),
                    color: .green
                )

                Divider()
                    .frame(height: 42)

                metricColumn(
                    value: "\(result.items.reduce(0) { $0 + $1.itemCount })",
                    title: localization.localized("systemJunk.itemCount"),
                    color: .secondary
                )
            }

            HStack(spacing: 8) {
                Button {
                    selectAllSafe()
                } label: {
                    Label(localization.localized("systemJunk.selectAllSafe"), systemImage: "checkmark.circle")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.small)
                .frame(maxWidth: .infinity)

                Button {
                    selectedItems.removeAll()
                } label: {
                    Label(localization.localized("systemJunk.deselectAll"), systemImage: "circle")
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.small)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func metricColumn(value: String, title: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 46)
    }
    
    // MARK: - Action Bar
    
    private func actionBar(_ result: SystemJunkScanResult) -> some View {
        HStack {
            if selectedItems.isEmpty {
                Text(localization.localized("systemJunk.selectItems"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(selectedItems.count) \(localization.localized("systemJunk.selectedCount")) • \(selectedSize.formattedSize)")
                    .font(.subheadline)
            }
            
            Spacer()
            
            if isCleaning {
                ProgressView(value: progress)
                    .frame(width: 150)
                Text(localization.localized("systemJunk.cleaning"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    showCleanConfirmation = true
                } label: {
                    Label(localization.localized("systemJunk.cleanButton"), systemImage: "trash")
                        .lineLimit(1)
                        .frame(minWidth: 130)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedItems.isEmpty)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .confirmationDialog(
            localization.localized("systemJunk.confirm.title"),
            isPresented: $showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button(localization.localized("systemJunk.confirm.button"), role: .destructive) {
                cleanSelected()
            }
            Button(localization.localized("uninstall.cancel"), role: .cancel) {}
        } message: {
            Text(localization.localized("systemJunk.confirm.message", selectedItems.count, selectedSize.formattedSize))
        }
        .alert(alertMessage.isEmpty ? localization.localized("systemJunk.cleanComplete") : localization.localized("error.title"), isPresented: $showAlert) {
            Button(localization.localized("systemJunk.done")) { }
        } message: {
            Text(alertMessage.isEmpty ? localization.localized("systemJunk.freedSpace", cleanedSize.formattedSize) : alertMessage)
        }
    }
    
    // MARK: - Actions
    
    private func startScan() {
        guard bookmarkManager.hasLibraryAccess || bookmarkManager.requestLibraryAccess() else {
            alertMessage = localization.localized("error.libraryRequired")
            showAlert = true
            return
        }

        isScanning = true
        selectedItems.removeAll()
        expandedItems.removeAll()
        scanResult = nil
        
        Task {
            let result = await SystemJunkScanner.shared.scan(libraryURL: bookmarkManager.libraryURL)
            await MainActor.run {
                self.scanResult = result
                self.isScanning = false
                self.selectAllSafe()
            }
        }
    }
    
    private func toggleSelection(_ item: SystemJunkItem) {
        let detailIDs = Set(item.details.map(\.id))
        guard !detailIDs.isEmpty else { return }

        if detailIDs.isSubset(of: selectedItems) {
            selectedItems.subtract(detailIDs)
        } else {
            selectedItems.formUnion(detailIDs)
        }
    }

    private func toggleSelection(_ detail: SystemJunkDetail) {
        if selectedItems.contains(detail.id) {
            selectedItems.remove(detail.id)
        } else {
            selectedItems.insert(detail.id)
        }
    }

    private func toggleExpanded(_ item: SystemJunkItem) {
        if expandedItems.contains(item.id) {
            expandedItems.remove(item.id)
        } else {
            expandedItems.insert(item.id)
        }
    }
    
    private func selectAllSafe() {
        guard let result = scanResult else { return }
        selectedItems = Set(result.items
            .filter { $0.category.estimatedSafeToDelete }
            .flatMap(\.details)
            .map(\.id))
    }
    
    private func cleanSelected() {
        guard let result = scanResult else { return }
        
        let itemsToClean = selectedItemsForCleaning(from: result)

        isCleaning = true
        progress = 0
        
        Task {
            do {
                let cleaned = try await SystemJunkScanner.shared.clean(items: itemsToClean, skipConfirmation: true)
                await MainActor.run {
                    self.cleanedSize = cleaned
                    self.alertMessage = ""
                    self.isCleaning = false
                    self.selectedItems.removeAll()
                    self.showAlert = true
                    // Rescan
                    self.startScan()
                }
            } catch {
                await MainActor.run {
                    self.isCleaning = false
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }

    private func selectedItemsForCleaning(from result: SystemJunkScanResult) -> [SystemJunkItem] {
        result.items.compactMap { item in
            let details = item.details.filter { selectedItems.contains($0.id) }
            guard !details.isEmpty else { return nil }

            return SystemJunkItem(
                category: item.category,
                path: item.path,
                size: details.reduce(0) { $0 + $1.size },
                itemCount: details.reduce(0) { $0 + $1.itemCount },
                description: item.description,
                paths: details.map(\.path),
                details: details
            )
        }
    }
}

// MARK: - Junk Item Row

struct JunkItemRow: View {
    let item: SystemJunkItem
    let selectedDetailIDs: Set<String>
    let isExpanded: Bool
    let localization: LocalizationManager
    let onToggleItem: () -> Void
    let onToggleDetail: (SystemJunkDetail) -> Void
    let onToggleExpanded: () -> Void
    let onReveal: (URL) -> Void

    private var selectedDetails: [SystemJunkDetail] {
        item.details.filter { selectedDetailIDs.contains($0.id) }
    }

    private var isSelected: Bool {
        !item.details.isEmpty && selectedDetails.count == item.details.count
    }

    private var isPartiallySelected: Bool {
        !isSelected && !selectedDetails.isEmpty
    }

    private var selectedSize: UInt64 {
        selectedDetails.reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onToggleItem) {
                    Image(systemName: checkboxIcon)
                        .font(.title2)
                        .foregroundStyle((isSelected || isPartiallySelected) ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(item.details.isEmpty)

                Image(systemName: item.icon)
                    .font(.title2)
                    .foregroundStyle(item.category.color.light)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.localized(item.category.localizationKey))
                        .font(.subheadline.weight(.medium))

                    Text(localization.localized(item.category.descriptionLocalizationKey))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.size.formattedSize)
                        .font(.subheadline.weight(.semibold))

                    if selectedSize > 0 && selectedSize != item.size {
                        Text("\(localization.localized("detail.selected")) \(selectedSize.formattedSize)")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    } else {
                        Text("\(item.itemCount) \(localization.localized("systemJunk.itemCount"))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(action: onToggleExpanded) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .disabled(item.details.isEmpty)
                .help(localization.localized("systemJunk.viewDetails"))
            }
            .padding()

            if isExpanded {
                Divider()
                    .padding(.leading, 56)

                if item.details.isEmpty {
                    Text(localization.localized("systemJunk.noDetails"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 68)
                        .padding(.vertical, 10)
                } else {
                    VStack(spacing: 0) {
                        ForEach(item.details) { detail in
                            detailRow(detail)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((isSelected || isPartiallySelected) ? Color.blue.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke((isSelected || isPartiallySelected) ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var checkboxIcon: String {
        if isSelected { return "checkmark.circle.fill" }
        if isPartiallySelected { return "minus.circle.fill" }
        return "circle"
    }

    private func detailRow(_ detail: SystemJunkDetail) -> some View {
        let selected = selectedDetailIDs.contains(detail.id)

        return HStack(spacing: 10) {
            Button {
                onToggleDetail(detail)
            } label: {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(selected ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: "doc")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(detail.displayName)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)

                Text(detail.relativePath)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            Text(detail.size.formattedSize)
                .font(.caption.weight(.semibold))
                .monospacedDigit()

            Button {
                onReveal(detail.path)
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 13))
            }
            .buttonStyle(.borderless)
            .help(localization.localized("results.reveal"))
        }
        .padding(.leading, 68)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
