// MenuBarManager.swift
// ApexUninstaller
// Menu bar / status bar icon for quick access

import Foundation
import AppKit
import SwiftUI

@Observable
final class MenuBarManager: NSObject {
    
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var notificationObservers: [NSObjectProtocol] = []
    private var menuBarPopoverViewModel: MenuBarPopoverViewModel?
    
    var popoverLocalization: LocalizationManager {
        LocalizationManager.shared
    }
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public API
    
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "ApexUninstaller.menuBarEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "ApexUninstaller.menuBarEnabled")
            if newValue {
                setupMenuBar()
            } else {
                removeMenuBar()
            }
        }
    }
    
    var isVisible: Bool {
        statusItem != nil
    }
    
    func setupMenuBar() {
        guard statusItem == nil else { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "trash.circle.fill", accessibilityDescription: "ApexUninstaller")
            button.image?.isTemplate = true
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        setupPopover()
        setupNotificationObservers()
    }
    
    func removeMenuBar() {
        removeNotificationObservers()
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
        popover = nil
    }
    
    private func setupPopover() {
        menuBarPopoverViewModel = MenuBarPopoverViewModel()
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView(viewModel: menuBarPopoverViewModel ?? MenuBarPopoverViewModel())
        )
    }
    
    private func setupNotificationObservers() {
        let quickScan = NotificationCenter.default.addObserver(
            forName: .menuBarQuickScan,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleQuickScan()
        }
        
        let showOrphans = NotificationCenter.default.addObserver(
            forName: .menuBarShowOrphans,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleShowOrphans()
        }
        
        let showHistory = NotificationCenter.default.addObserver(
            forName: .menuBarShowHistory,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleShowHistory()
        }
        
        notificationObservers = [quickScan, showOrphans, showHistory]
    }
    
    private func removeNotificationObservers() {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        notificationObservers.removeAll()
    }
    
    private func handleQuickScan() {
        closePopover()
        NotificationCenter.default.post(name: .menuBarTriggerScan, object: nil)
    }
    
    private func handleShowOrphans() {
        closePopover()
        NotificationCenter.default.post(name: .menuBarTriggerOrphans, object: nil)
    }
    
    private func handleShowHistory() {
        closePopover()
        NotificationCenter.default.post(name: .menuBarTriggerHistory, object: nil)
    }
    
    func closePopover() {
        if popover?.isShown == true {
            popover?.performClose(nil)
        }
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }
    
    private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        let loc = LocalizationManager.shared
        
        let headerItem = NSMenuItem(title: loc.localized("menuBar.appName"), action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let reclaimableSize = getReclaimableSize()
        let statsItem = NSMenuItem(
            title: "\(loc.localized("menuBar.reclaimableSpace")): \(reclaimableSize.formattedSize)",
            action: nil,
            keyEquivalent: ""
        )
        statsItem.isEnabled = false
        menu.addItem(statsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let scanItem = NSMenuItem(
            title: loc.localized("sidebar.scanButton"),
            action: #selector(handleQuickScanAction),
            keyEquivalent: "s"
        )
        scanItem.target = self
        menu.addItem(scanItem)
        
        let orphansItem = NSMenuItem(
            title: loc.localized("toolbar.orphans"),
            action: #selector(handleShowOrphansAction),
            keyEquivalent: "o"
        )
        orphansItem.target = self
        menu.addItem(orphansItem)
        
        let historyItem = NSMenuItem(
            title: loc.localized("toolbar.history"),
            action: #selector(handleShowHistoryAction),
            keyEquivalent: "h"
        )
        historyItem.target = self
        menu.addItem(historyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let openItem = NSMenuItem(
            title: loc.localized("menuBar.openApp"),
            action: #selector(openMainApp),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: loc.localized("menuBar.quit"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func handleQuickScanAction() {
        handleQuickScan()
    }
    
    @objc private func handleShowOrphansAction() {
        handleShowOrphans()
    }
    
    @objc private func handleShowHistoryAction() {
        handleShowHistory()
    }
    
    @MainActor @objc private func openMainApp() {
        MainWindowCoordinator.shared.show()
    }
    
    private func getReclaimableSize() -> UInt64 {
        UInt64(UserDefaults.standard.integer(forKey: "ApexUninstaller.lastReclaimableSize"))
    }
}

// MARK: - Menu Bar Popover ViewModel

@Observable
final class MenuBarPopoverViewModel {
    var reclaimableSize: UInt64 = 0
    var orphanCount: Int = 0
    var recentCleanups: [CleanupHistoryEntry] = []
    var localization: LocalizationManager { LocalizationManager.shared }
    
    func loadData() {
        reclaimableSize = UInt64(UserDefaults.standard.integer(forKey: "ApexUninstaller.lastReclaimableSize"))
        orphanCount = UserDefaults.standard.integer(forKey: "ApexUninstaller.lastOrphanCount")
        
        if let data = UserDefaults.standard.data(forKey: "ApexUninstaller.cleanupHistory"),
           let history = try? JSONDecoder().decode([CleanupHistoryEntry].self, from: data) {
            recentCleanups = Array(history.prefix(3))
        }
    }
}

// MARK: - Menu Bar Popover View

struct MenuBarPopoverView: View {
    @Bindable var viewModel: MenuBarPopoverViewModel
    @State private var isAppeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text(viewModel.localization.localized("menuBar.appName"))
                        .font(.headline)
                    Text(viewModel.localization.localized("menuBar.menuBar"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            
            Divider()
            
            HStack(spacing: 20) {
                VStack {
                    Text(viewModel.reclaimableSize.formattedSize)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.orange)
                    Text(viewModel.localization.localized("menuBar.reclaimableSpace"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text("\(viewModel.orphanCount)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.purple)
                    Text(viewModel.localization.localized("menuBar.orphanFiles"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            VStack(spacing: 8) {
                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: viewModel.localization.localized("sidebar.scanButton"),
                    color: .blue
                ) {
                    NotificationCenter.default.post(name: .menuBarQuickScan, object: nil)
                }
                
                QuickActionButton(
                    icon: "sparkles",
                    title: viewModel.localization.localized("toolbar.orphans"),
                    color: .purple
                ) {
                    NotificationCenter.default.post(name: .menuBarShowOrphans, object: nil)
                }
            }
            .padding()
            
            Divider()
            
            if !viewModel.recentCleanups.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.localization.localized("menuBar.recentItems"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.recentCleanups) { entry in
                        HStack {
                            Image(systemName: entry.operation == .uninstall ? "trash" : "arrow.counterclockwise")
                                .font(.caption)
                                .foregroundStyle(.red)
                            Text(entry.appName)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(entry.reclaimedSize.formattedSize)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
        }
        .frame(width: 300, height: 350)
        .onAppear {
            if !isAppeared {
                viewModel.loadData()
                isAppeared = true
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let menuBarQuickScan = Notification.Name("menuBarQuickScan")
    static let menuBarShowOrphans = Notification.Name("menuBarShowOrphans")
    static let menuBarShowHistory = Notification.Name("menuBarShowHistory")
    static let menuBarTriggerScan = Notification.Name("menuBarTriggerScan")
    static let menuBarTriggerOrphans = Notification.Name("menuBarTriggerOrphans")
    static let menuBarTriggerHistory = Notification.Name("menuBarTriggerHistory")
}

// MARK: - AppLanguage Static Extension

extension AppLanguage {
    static var currentLanguage: AppLanguage {
        if let saved = UserDefaults.standard.string(forKey: "ApexUninstaller.language"),
           let lang = AppLanguage(rawValue: saved) {
            return lang
        }
        return .english
    }
}
