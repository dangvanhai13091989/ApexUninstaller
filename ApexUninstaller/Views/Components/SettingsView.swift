// SettingsView.swift
// ApexUninstaller
// Settings View for app preferences

import SwiftUI
import AppKit

struct SettingsView: View {
    let localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("ApexUninstaller.largeLeftoverThresholdMB") private var largeThreshold = 100
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(localization.localized("settings.title"))
                    .font(.title2.bold())
                Spacer()
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
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if DistributionChannel.isDirect {
                        directDistributionSection
                    }

                    // Menu Bar Section
                    menuBarSection
                    
                    // Smart Notifications Section
                    smartNotificationsSection
                    
                    // General Settings
                    generalSection
                    
                    // Scheduled Scan Section
                    scheduledScanSection
                    
                    // Advanced Section
                    advancedSection
                }
                .padding(20)
            }
        }
        .frame(width: 520, height: 580)
    }

    // MARK: - Direct Distribution

    private var directDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized("settings.direct.title"))
                .font(.headline)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(DesignTokens.accentPrimary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(localization.localized("settings.direct.edition"))
                            .font(.subheadline.weight(.semibold))
                        Text(localization.localized("settings.direct.description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                Text(localization.localized("settings.direct.fullDiskHelp"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Button {
                        DistributionChannel.openFullDiskAccessSettings()
                    } label: {
                        Label(localization.localized("settings.direct.fullDisk"), systemImage: "lock.open")
                    }

                    Spacer()

                    Button {
                        NSWorkspace.shared.open(DistributionChannel.repositoryURL)
                    } label: {
                        Label(localization.localized("settings.direct.source"), systemImage: "chevron.left.forwardslash.chevron.right")
                    }

                    Button {
                        NSWorkspace.shared.open(DistributionChannel.sponsorsURL)
                    } label: {
                        Label(localization.localized("settings.direct.sponsor"), systemImage: "heart.fill")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Menu Bar Section
    
    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized("menuBar.title"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: Binding(
                    get: { MenuBarManager.shared.isEnabled },
                    set: { MenuBarManager.shared.isEnabled = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.localized("menuBar.enable"))
                            .font(.subheadline)
                        Text(localization.localized("settings.menuBarAccess"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Smart Notifications Section
    
    private var smartNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized("notification.smartEnable"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: Binding(
                    get: { SmartNotificationService.shared.isEnabled },
                    set: { SmartNotificationService.shared.isEnabled = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.localized("notification.smartEnable"))
                            .font(.subheadline)
                        Text(localization.localized("notification.smartEnable.help"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                
                if SmartNotificationService.shared.isEnabled {
                    Divider()
                    
                    // Threshold setting
                    HStack {
                        Text(localization.localized("settings.reminderThreshold"))
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { Int(SmartNotificationService.shared.thresholdJunkSize / (1024 * 1024)) },
                            set: { SmartNotificationService.shared.thresholdJunkSize = UInt64($0) * 1024 * 1024 }
                        )) {
                            Text("100 \(localization.localized("settings.mb"))").tag(100)
                            Text("500 \(localization.localized("settings.mb"))").tag(500)
                            Text("1 GB").tag(1024)
                            Text("2 GB").tag(2048)
                        }
                        .frame(width: 120)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - General Section
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized("settings.general"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(localization.localized("settings.language"))
                        .font(.subheadline)
                    Spacer()
                    Text(localization.currentLanguage.flag + " " + localization.currentLanguage.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                Toggle(isOn: Binding(
                    get: { LaunchAtLoginManager.shared.isEnabled },
                    set: { LaunchAtLoginManager.shared.isEnabled = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.localized("settings.launchAtLogin"))
                            .font(.subheadline)
                        if LaunchAtLoginManager.shared.requiresApproval {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text(localization.localized("settings.launchAtLogin.requiresApproval"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .toggleStyle(.switch)
                .onChange(of: LaunchAtLoginManager.shared.requiresApproval) { _, requiresApproval in
                    if requiresApproval {
                        LaunchAtLoginManager.shared.openSystemSettings()
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Scheduled Scan Section
    
    private var scheduledScanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized("schedule.title"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: Binding(
                    get: { ScheduledScanManager.shared.isAutoScanEnabled },
                    set: { ScheduledScanManager.shared.isAutoScanEnabled = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.localized("schedule.enable"))
                            .font(.subheadline)
                        Text(localization.localized("settings.getNotified"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                
                Divider()
                
                // Scan Interval
                HStack {
                    Text(localization.localized("schedule.interval"))
                        .font(.subheadline)
                    Spacer()
                    
                    Picker("", selection: Binding(
                        get: { ScheduledScanManager.shared.scanInterval.rawValue },
                        set: { value in
                            ScheduledScanManager.shared.scanInterval = ScheduledScanManager.ScanInterval(rawValue: value) ?? .weekly
                        }
                    )) {
                        Text(localization.localized("schedule.daily")).tag(1)
                        Text(localization.localized("schedule.weekly")).tag(7)
                        Text(localization.localized("schedule.monthly")).tag(30)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                }
                
                // Last Scan Info
                if let lastScan = ScheduledScanManager.shared.lastAutoScanDate {
                    HStack {
                        Text(localization.localized("schedule.lastScan"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(lastScan.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Advanced Section
    
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized("settings.advanced"))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                // Large Leftover Threshold
                HStack {
                    Text(localization.localized("settings.largeLeftoverThreshold"))
                        .font(.subheadline)
                    Spacer()
                    Stepper("\(largeThreshold) \(localization.localized("settings.mb"))", value: $largeThreshold, in: 10...500, step: 10)
                        .frame(width: 200)
                }
                
                Text(localization.localized("settings.leftoverThreshold"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

}
