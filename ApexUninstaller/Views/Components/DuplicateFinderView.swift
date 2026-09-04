// DuplicateFinderView.swift
// ApexUninstaller
// UI for finding and removing duplicate files and large files

import SwiftUI
import AppKit

enum FileScanTab: String, CaseIterable {
    case duplicates
    case largeFiles

    var icon: String {
        switch self {
        case .duplicates: return "doc.on.doc"
        case .largeFiles: return "externaldrive"
        }
    }
}

struct DuplicateFinderView: View {
    let localization: LocalizationManager
    @Bindable var bookmarkManager: BookmarkManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: FileScanTab = .duplicates
    @State private var showFolderPicker = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            tabSelector
            Divider()
            tabContent
        }
        .frame(minWidth: 600, minHeight: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showFolderPicker) {
            folderPickerSheet
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.localized("duplicate.title"))
                    .font(.title2.bold())
                Text(localization.localized("duplicate.subtitle"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

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

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 4) {
            ForEach(FileScanTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13))
                        Text(tab == .duplicates
                             ? localization.localized("duplicate.tabDuplicates")
                             : localization.localized("duplicate.tabLargeFiles"))
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab
                            ? DesignTokens.accentPrimary.opacity(0.15)
                            : Color.clear
                    )
                    .foregroundStyle(selectedTab == tab ? DesignTokens.accentPrimary : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .duplicates:
            DuplicatesTabView(localization: localization, bookmarkManager: bookmarkManager, showFolderPicker: $showFolderPicker, selectedFolder: $selectedFolder, hasSelectedFolderAccess: $hasSelectedFolderAccess)
        case .largeFiles:
            LargeFilesTabView(localization: localization, bookmarkManager: bookmarkManager, showFolderPicker: $showFolderPicker, selectedFolder: $selectedFolder, hasSelectedFolderAccess: $hasSelectedFolderAccess)
        }
    }

    // MARK: - Folder Picker

    @State private var selectedFolder: URL = realUserHomeDirectory
    @State private var hasSelectedFolderAccess = false

    private var folderPickerSheet: some View {
        FolderPickerSheet(
            localization: localization,
            bookmarkManager: bookmarkManager,
            selectedURL: $selectedFolder,
            hasSelectedFolderAccess: $hasSelectedFolderAccess,
            onCancel: { showFolderPicker = false }
        )
    }
}

// MARK: - Duplicates Tab

struct DuplicatesTabView: View {
    let localization: LocalizationManager
    @Bindable var bookmarkManager: BookmarkManager
    @Binding var showFolderPicker: Bool
    @Binding var selectedFolder: URL
    @Binding var hasSelectedFolderAccess: Bool

    @State private var scanResult: DuplicateScanResult?
    @State private var isScanning = false
    @State private var scanProgress: Double = 0
    @State private var scanStatus: String = ""
    @State private var selectedGroups: Set<UUID> = []
    @State private var selectedFiles: Set<UUID> = []
    @State private var isCleaning = false
    @State private var showCleanAlert = false
    @State private var cleanedSize: UInt64 = 0
    @State private var expandedGroups: Set<UUID> = []

    private var selectedSize: UInt64 {
        guard let result = scanResult else { return 0 }
        return result.groups
            .filter { selectedGroups.contains($0.id) || groupContainsSelectedFiles($0) }
            .reduce(0) { total, group in
                let selectedInGroup: [DuplicateFile]
                if selectedGroups.contains(group.id) {
                    selectedInGroup = Array(group.files.dropFirst())
                } else {
                    selectedInGroup = group.files.filter { selectedFiles.contains($0.id) }
                }
                return total + selectedInGroup.reduce(0) { $0 + $1.size }
            }
    }

    private func groupContainsSelectedFiles(_ group: DuplicateGroup) -> Bool {
        !Set(group.files.map(\.id)).isDisjoint(with: selectedFiles)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isScanning {
                scanningView
            } else if let result = scanResult {
                if result.groups.isEmpty {
                    emptyResultView
                } else {
                    resultView(result)
                }
            } else {
                startView
            }
        }
        .alert(localization.localized("duplicate.cleanComplete"), isPresented: $showCleanAlert) {
            Button(localization.localized("duplicate.done")) {
                if scanResult?.groups.isEmpty == true {
                    // Just dismiss alert
                }
            }
        } message: {
            Text(localization.localized("duplicate.freedSpace", cleanedSize.formattedSize))
        }
    }

    private var startView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.on.doc")
                .font(.system(size: 64))
                .foregroundStyle(DesignTokens.accentPrimary)

            VStack(spacing: 8) {
                Text(localization.localized("duplicate.findDuplicates"))
                    .font(.title2.bold())
                Text(localization.localized("duplicate.howItWorks"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            folderSection

            Spacer()
        }
        .padding()
    }

    private var scanningView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView(value: scanProgress)
                .progressViewStyle(.linear)
                .frame(width: 400)
            Text(scanStatus)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("\(Int(scanProgress * 100))%")
                .font(.system(.title, design: .rounded))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding()
    }

    private var emptyResultView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text(localization.localized("duplicate.noDuplicates"))
                .font(.headline)
            Text(localization.localized("duplicate.noDuplicatesDesc"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button(action: startScan) {
                Label(localization.localized("scan.rescan"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
    }

    private func resultView(_ result: DuplicateScanResult) -> some View {
        VStack(spacing: 0) {
            summaryBar(result)
            Divider()
            duplicateList(result)
            Divider()
            actionBar(result)
        }
    }

    private var folderSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(selectedFolderLabel)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(localization.localized("duplicate.changeFolder")) {
                    showFolderPicker = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: startScan) {
                Label(localization.localized("duplicate.startScan"), systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: 500)
    }

    private var selectedFolderLabel: String {
        let home = realUserHomeDirectory.path
        let path = selectedFolder.path
        if path.hasPrefix(home) { return "~" + path.dropFirst(home.count) }
        return path
    }

    private func summaryBar(_ result: DuplicateScanResult) -> some View {
        HStack(spacing: 16) {
            metricPill(value: "\(result.groups.count)", label: localization.localized("duplicate.groups"), color: DesignTokens.accentPrimary)
            metricPill(value: result.totalWastedSize.formattedSize, label: localization.localized("duplicate.wasted"), color: .red)
            metricPill(value: "\(result.totalFilesScanned)", label: localization.localized("duplicate.filesScanned"), color: .secondary)
            Spacer()
            Button { selectAllGroups() } label: {
                Label(localization.localized("duplicate.selectAll"), systemImage: "checkmark.circle").font(.caption)
            }.buttonStyle(.bordered)
            Button {
                selectedGroups.removeAll()
                selectedFiles.removeAll()
            } label: {
                Label(localization.localized("duplicate.deselectAll"), systemImage: "circle").font(.caption)
            }.buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func metricPill(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(value).font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    private func duplicateList(_ result: DuplicateScanResult) -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(result.groups) { group in
                    DuplicateGroupRow(
                        group: group,
                        isExpanded: expandedGroups.contains(group.id),
                        isGroupSelected: selectedGroups.contains(group.id),
                        selectedFileIDs: selectedFiles,
                        localization: localization,
                        onToggleGroup: { toggleGroup(group) },
                        onToggleFile: { toggleFile($0, in: group) },
                        onToggleExpanded: { toggleExpanded(group) },
                        onReveal: { NSWorkspace.shared.activateFileViewerSelecting([$0]) }
                    )
                }
            }
            .padding()
        }
    }

    private func actionBar(_ result: DuplicateScanResult) -> some View {
        HStack {
            if selectedGroups.isEmpty && selectedFiles.isEmpty {
                Text(localization.localized("duplicate.selectToClean")).font(.subheadline).foregroundStyle(.secondary)
            } else {
                Text("\(selectedFileCount) \(localization.localized("duplicate.files")) • \(selectedSize.formattedSize)")
                    .font(.subheadline)
            }
            Spacer()
            Button(action: cleanSelected) {
                Label(localization.localized("duplicate.cleanSelected"), systemImage: "trash")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(selectedGroups.isEmpty && selectedFiles.isEmpty)
            .disabled(isCleaning)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var selectedFileCount: Int {
        guard let result = scanResult else { return 0 }
        return result.groups
            .filter { selectedGroups.contains($0.id) || groupContainsSelectedFiles($0) }
            .reduce(0) { total, group in
                if selectedGroups.contains(group.id) {
                    return total + max(0, group.files.count - 1)
                }
                return total + group.files.filter { selectedFiles.contains($0.id) }.count
            }
    }

    // MARK: - Actions

    private func startScan() {
        guard hasSelectedFolderAccess else {
            showFolderPicker = true
            return
        }

        if !bookmarkManager.hasLibraryAccess {
            _ = bookmarkManager.requestLibraryAccess()
        }

        isScanning = true
        scanProgress = 0
        scanStatus = ""
        scanResult = nil
        selectedGroups.removeAll()
        selectedFiles.removeAll()
        expandedGroups.removeAll()

        Task {
            let result = await DuplicateFinderService.shared.scan(
                directories: [selectedFolder],
                libraryBookmarkURL: bookmarkManager.libraryURL
            ) { progress, status in
                Task { @MainActor in
                    self.scanProgress = progress
                    self.scanStatus = status
                }
            }

            await MainActor.run {
                self.scanResult = result
                self.isScanning = false
                self.scanProgress = 1.0
            }
        }
    }

    private func toggleGroup(_ group: DuplicateGroup) {
        if selectedGroups.contains(group.id) {
            selectedGroups.remove(group.id)
            selectedFiles.subtract(Set(group.files.map(\.id)))
        } else {
            selectedGroups.insert(group.id)
            selectedFiles.subtract(Set(group.files.map(\.id)))
        }
    }

    private func toggleFile(_ file: DuplicateFile, in group: DuplicateGroup) {
        if selectedFiles.contains(file.id) {
            selectedFiles.remove(file.id)
        } else {
            selectedFiles.insert(file.id)
        }
    }

    private func toggleExpanded(_ group: DuplicateGroup) {
        if expandedGroups.contains(group.id) {
            expandedGroups.remove(group.id)
        } else {
            expandedGroups.insert(group.id)
        }
    }

    private func selectAllGroups() {
        guard let result = scanResult else { return }
        for group in result.groups {
            selectedGroups.insert(group.id)
        }
    }

    private func cleanSelected() {
        guard let result = scanResult else { return }

        let filesToDelete: [URL] = result.groups
            .filter { selectedGroups.contains($0.id) || groupContainsSelectedFiles($0) }
            .flatMap { group in
                if selectedGroups.contains(group.id) {
                    return group.files.dropFirst().map(\.path)
                }
                return group.files.filter { selectedFiles.contains($0.id) }.map(\.path)
            }

        guard !filesToDelete.isEmpty else { return }

        isCleaning = true

        Task {
            var freed: UInt64 = 0
            for url in filesToDelete {
                guard RemovalSafetyPolicy.canMoveToTrash(url) else { continue }
                let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.uint64Value ?? 0
                do {
                    try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                    freed += size
                } catch {
                    // Continue
                }
            }

            await MainActor.run {
                self.cleanedSize = freed
                self.isCleaning = false
                self.selectedGroups.removeAll()
                self.selectedFiles.removeAll()
                self.showCleanAlert = true
                self.startScan()
            }
        }
    }
}

// MARK: - Large Files Tab

struct LargeFilesTabView: View {
    let localization: LocalizationManager
    @Bindable var bookmarkManager: BookmarkManager
    @Binding var showFolderPicker: Bool
    @Binding var selectedFolder: URL
    @Binding var hasSelectedFolderAccess: Bool

    @State private var scanResult: LargeFileScanResult?
    @State private var isScanning = false
    @State private var scanProgress: Double = 0
    @State private var scanStatus: String = ""
    @State private var selectedFiles: Set<UUID> = []
    @State private var isCleaning = false
    @State private var showCleanAlert = false
    @State private var cleanedSize: UInt64 = 0
    @State private var minSizeMB: Int = 10

    private var selectedSize: UInt64 {
        guard let result = scanResult else { return 0 }
        return result.files
            .filter { selectedFiles.contains($0.id) }
            .reduce(0) { $0 + $1.size }
    }

    private var selectedFileCount: Int {
        selectedFiles.count
    }

    var body: some View {
        VStack(spacing: 0) {
            if isScanning {
                scanningView
            } else if let result = scanResult {
                if result.files.isEmpty {
                    emptyResultView
                } else {
                    resultView(result)
                }
            } else {
                startView
            }
        }
        .alert(localization.localized("duplicate.cleanComplete"), isPresented: $showCleanAlert) {
            Button(localization.localized("duplicate.done")) { }
        } message: {
            Text(localization.localized("duplicate.freedSpace", cleanedSize.formattedSize))
        }
    }

    private var startView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "externaldrive")
                .font(.system(size: 64))
                .foregroundStyle(DesignTokens.accentPrimary)

            VStack(spacing: 8) {
                Text(localization.localized("largeFiles.findLargeFiles"))
                    .font(.title2.bold())
                Text(localization.localized("largeFiles.howItWorks"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            sizeFilterSection
            folderSection

            Spacer()
        }
        .padding()
    }

    private var sizeFilterSection: some View {
        HStack(spacing: 12) {
            Text(localization.localized("largeFiles.minSize"))
                .font(.subheadline)
            Picker("", selection: $minSizeMB) {
                Text("10 MB").tag(10)
                Text("50 MB").tag(50)
                Text("100 MB").tag(100)
                Text("500 MB").tag(500)
                Text("1 GB").tag(1024)
            }
            .pickerStyle(.menu)
            .frame(width: 110)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var scanningView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView(value: scanProgress)
                .progressViewStyle(.linear)
                .frame(width: 400)
            Text(scanStatus)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("\(Int(scanProgress * 100))%")
                .font(.system(.title, design: .rounded))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding()
    }

    private var emptyResultView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text(localization.localized("largeFiles.noLargeFiles"))
                .font(.headline)
            Text(localization.localized("largeFiles.noLargeFilesDesc", minSizeMB.description))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button(action: startScan) {
                Label(localization.localized("scan.rescan"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
    }

    private func resultView(_ result: LargeFileScanResult) -> some View {
        VStack(spacing: 0) {
            summaryBar(result)
            Divider()
            fileList(result)
            Divider()
            actionBar(result)
        }
    }

    private var folderSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(selectedFolderLabel)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(localization.localized("duplicate.changeFolder")) {
                    showFolderPicker = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: startScan) {
                Label(localization.localized("largeFiles.startScan"), systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: 500)
    }

    private var selectedFolderLabel: String {
        let home = realUserHomeDirectory.path
        let path = selectedFolder.path
        if path.hasPrefix(home) { return "~" + path.dropFirst(home.count) }
        return path
    }

    private func summaryBar(_ result: LargeFileScanResult) -> some View {
        HStack(spacing: 16) {
            metricPill(value: "\(result.files.count)", label: localization.localized("largeFiles.found"), color: DesignTokens.accentPrimary)
            metricPill(value: result.totalSize.formattedSize, label: localization.localized("largeFiles.totalSize"), color: .orange)
            Spacer()
            Text("\(result.totalScanned) \(localization.localized("duplicate.filesScanned"))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button { selectAll() } label: {
                Label(localization.localized("duplicate.selectAll"), systemImage: "checkmark.circle").font(.caption)
            }.buttonStyle(.bordered)
            Button {
                selectedFiles.removeAll()
            } label: {
                Label(localization.localized("duplicate.deselectAll"), systemImage: "circle").font(.caption)
            }.buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func metricPill(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(value).font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    private func fileList(_ result: LargeFileScanResult) -> some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(result.files) { file in
                    LargeFileRow(
                        file: file,
                        isSelected: selectedFiles.contains(file.id),
                        localization: localization,
                        onToggle: { toggleFile(file) },
                        onReveal: { NSWorkspace.shared.activateFileViewerSelecting([file.path]) }
                    )
                }
            }
            .padding()
        }
    }

    private func actionBar(_ result: LargeFileScanResult) -> some View {
        HStack {
            if selectedFiles.isEmpty {
                Text(localization.localized("largeFiles.selectToClean"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(selectedFileCount) \(localization.localized("duplicate.files")) • \(selectedSize.formattedSize)")
                    .font(.subheadline)
            }
            Spacer()
            Button(action: cleanSelected) {
                Label(localization.localized("duplicate.cleanSelected"), systemImage: "trash")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(selectedFiles.isEmpty)
            .disabled(isCleaning)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Actions

    private func startScan() {
        guard hasSelectedFolderAccess else {
            showFolderPicker = true
            return
        }

        if !bookmarkManager.hasLibraryAccess {
            _ = bookmarkManager.requestLibraryAccess()
        }

        isScanning = true
        scanProgress = 0
        scanStatus = ""
        scanResult = nil
        selectedFiles.removeAll()

        Task {
            let result = await DuplicateFinderService.shared.scanLargeFiles(
                directories: [selectedFolder],
                libraryBookmarkURL: bookmarkManager.libraryURL,
                minSizeMB: minSizeMB
            ) { progress, status in
                Task { @MainActor in
                    self.scanProgress = progress
                    self.scanStatus = status
                }
            }

            await MainActor.run {
                self.scanResult = result
                self.isScanning = false
                self.scanProgress = 1.0
            }
        }
    }

    private func toggleFile(_ file: LargeFile) {
        if selectedFiles.contains(file.id) {
            selectedFiles.remove(file.id)
        } else {
            selectedFiles.insert(file.id)
        }
    }

    private func selectAll() {
        guard let result = scanResult else { return }
        selectedFiles = Set(result.files.map(\.id))
    }

    private func cleanSelected() {
        guard let result = scanResult else { return }

        let filesToDelete = result.files.filter { selectedFiles.contains($0.id) }
        guard !filesToDelete.isEmpty else { return }

        isCleaning = true

        Task {
            var freed: UInt64 = 0
            for file in filesToDelete {
                guard RemovalSafetyPolicy.canMoveToTrash(file.path) else { continue }
                do {
                    try FileManager.default.trashItem(at: file.path, resultingItemURL: nil)
                    freed += file.size
                } catch {
                    // Continue
                }
            }

            await MainActor.run {
                self.cleanedSize = freed
                self.isCleaning = false
                self.selectedFiles.removeAll()
                self.showCleanAlert = true
                self.startScan()
            }
        }
    }
}

// MARK: - Large File Row

struct LargeFileRow: View {
    let file: LargeFile
    let isSelected: Bool
    let localization: LocalizationManager
    let onToggle: () -> Void
    let onReveal: () -> Void

    private var fileIcon: String {
        switch file.fileType {
        case "jpg", "jpeg", "png", "gif", "heic", "webp", "tiff", "bmp": return "photo"
        case "mp4", "mov", "avi", "mkv", "m4v", "wmv": return "film"
        case "mp3", "wav", "aac", "flac", "m4a": return "music.note"
        case "zip", "rar", "7z", "tar", "gz", "dmg": return "doc.zipper"
        case "pdf": return "doc.richtext"
        case "pkg", "mpkg": return "shippingbox"
        default: return "doc"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? DesignTokens.accentPrimary : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: fileIcon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.displayName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(file.relativePath)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(file.size.formattedSize)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.orange)
                .monospacedDigit()

            Button(action: onReveal) {
                Image(systemName: "folder")
                    .font(.system(size: 14))
            }
            .buttonStyle(.borderless)
            .help(localization.localized("results.reveal"))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? DesignTokens.accentPrimary.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? DesignTokens.accentPrimary.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Updated Folder Picker Sheet

struct FolderPickerSheet: View {
    let localization: LocalizationManager
    @Bindable var bookmarkManager: BookmarkManager
    @Binding var selectedURL: URL
    @Binding var hasSelectedFolderAccess: Bool
    let onCancel: () -> Void

    private var presetFolders: [(titleKey: String, subpath: String, icon: String)] {
        [
            (localization.localized("folder.home"), "", "house.fill"),
            (localization.localized("folder.documents"), "Documents", "doc.fill"),
            (localization.localized("folder.downloads"), "Downloads", "arrow.down.circle.fill"),
            (localization.localized("folder.pictures"), "Pictures", "photo.fill"),
            (localization.localized("folder.desktop"), "Desktop", "desktopcomputer"),
            (localization.localized("folder.movies"), "Movies", "film.fill"),
            (localization.localized("folder.music"), "Music", "music.note"),
        ]
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(localization.localized("duplicate.selectFolder"))
                .font(.headline)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(presetFolders, id: \.titleKey) { folder in
                        let url = realUserHomeDirectory.appendingPathComponent(folder.subpath)
                        folderRow(
                            title: folder.titleKey,
                            path: url,
                            icon: folder.icon
                        )
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Button {
                        openCustomPicker()
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                                .foregroundStyle(DesignTokens.accentPrimary)
                                .frame(width: 24)
                            Text(localization.localized("folder.custom"))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                }
            }
            .frame(maxHeight: 320)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Button(localization.localized("uninstall.cancel"), action: onCancel)
                    .buttonStyle(.bordered)
                Spacer()
                Button(localization.localized("duplicate.done")) {
                    onCancel()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400)
    }

    private func folderRow(title: String, path: URL, icon: String) -> some View {
        Button {
            openPicker(startingAt: path)
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(selectedURL == path ? DesignTokens.accentPrimary : .secondary)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Text(shortPath(path))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                if selectedURL == path {
                    Image(systemName: "checkmark")
                        .foregroundStyle(DesignTokens.accentPrimary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
    }

    private func shortPath(_ url: URL) -> String {
        let home = realUserHomeDirectory.path
        let full = url.path
        if full.hasPrefix(home) {
            return "~" + full.dropFirst(home.count)
        }
        return full
    }

    private func openCustomPicker() {
        openPicker(startingAt: selectedURL)
    }

    private func openPicker(startingAt url: URL) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = localization.localized("folder.select")
        panel.directoryURL = url

        if panel.runModal() == .OK, let url = panel.url {
            selectedURL = url
            hasSelectedFolderAccess = true
        }
    }
}

// MARK: - Duplicate Group Row

struct DuplicateGroupRow: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    let isGroupSelected: Bool
    let selectedFileIDs: Set<UUID>
    let localization: LocalizationManager
    let onToggleGroup: () -> Void
    let onToggleFile: (DuplicateFile) -> Void
    let onToggleExpanded: () -> Void
    let onReveal: (URL) -> Void

    private var selectedCount: Int {
        group.files.filter { selectedFileIDs.contains($0.id) }.count
    }

    private var isPartiallySelected: Bool {
        selectedCount > 0 && selectedCount < group.files.count
    }

    var body: some View {
        VStack(spacing: 0) {
            groupHeader
            if isExpanded {
                Divider().padding(.leading, 48)
                VStack(spacing: 1) {
                    ForEach(group.files) { file in
                        DuplicateFileRow(
                            file: file,
                            isSelected: selectedFileIDs.contains(file.id),
                            isFirst: file.id == group.files.first?.id,
                            localization: localization,
                            onToggle: { onToggleFile(file) },
                            onReveal: { onReveal(file.path) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((isGroupSelected || isPartiallySelected) ? DesignTokens.accentPrimary.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke((isGroupSelected || isPartiallySelected) ? DesignTokens.accentPrimary.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }

    private var groupHeader: some View {
        HStack(spacing: 12) {
            Button(action: onToggleGroup) {
                Image(systemName: groupCheckboxIcon)
                    .font(.title2)
                    .foregroundStyle(isGroupSelected ? DesignTokens.accentPrimary : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: "doc.on.doc.fill")
                .font(.title2)
                .foregroundStyle(DesignTokens.accentPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(group.fileCount) \(localization.localized("duplicate.files"))")
                    .font(.subheadline.weight(.medium))
                Text(group.files.first?.displayName ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(group.wastedSize.formattedSize)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                Text(group.totalSize.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: onToggleExpanded) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption.weight(.semibold))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    private var groupCheckboxIcon: String {
        if isGroupSelected { return "checkmark.circle.fill" }
        if isPartiallySelected { return "minus.circle.fill" }
        return "circle"
    }
}

// MARK: - Duplicate File Row

struct DuplicateFileRow: View {
    let file: DuplicateFile
    let isSelected: Bool
    let isFirst: Bool
    let localization: LocalizationManager
    let onToggle: () -> Void
    let onReveal: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? DesignTokens.accentPrimary : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: "doc")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.displayName)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Text(file.relativePath)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            if isFirst {
                Text("ORIGINAL")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(file.size.formattedSize)
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(.secondary)

            Button(action: onReveal) {
                Image(systemName: "folder")
                    .font(.system(size: 13))
            }
            .buttonStyle(.borderless)
            .help(localization.localized("results.reveal"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isFirst ? Color.green.opacity(0.04) : Color.clear)
    }
}
