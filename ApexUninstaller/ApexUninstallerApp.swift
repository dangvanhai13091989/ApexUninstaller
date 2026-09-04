// ApexUninstallerApp.swift
// ApexUninstaller
// Entry point for ApexUninstaller. macOS 14.0+ (Sonoma), Swift 6, SwiftUI.

import SwiftUI
import AppKit
import UserNotifications

@main
struct ApexUninstallerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    @State private var viewModel = AppViewModel()
    @State private var bookmarkManager = BookmarkManager()
    @State private var menuBarHandler = MenuBarAppHandler()
    @State private var appReady = false
    
    var body: some Scene {
        Window("ApexUninstaller", id: "main") {
            MainView(viewModel: $viewModel, bookmarkManager: $bookmarkManager)
                .onReceive(NotificationCenter.default.publisher(for: .menuBarTriggerScanReceived)) { _ in
                    openMainWindow()
                    viewModel.scanApplications()
                }
                .onReceive(NotificationCenter.default.publisher(for: .menuBarTriggerOrphansReceived)) { _ in
                    openMainWindow()
                    viewModel.openOrphanedLeftovers()
                }
                .onReceive(NotificationCenter.default.publisher(for: .menuBarTriggerHistoryReceived)) { _ in
                    openMainWindow()
                    viewModel.showCleanupHistory = true
                }
                .onAppear {
                    MainWindowCoordinator.shared.register(openWindow)
                    if !appReady {
                        appReady = true
                        if MenuBarManager.shared.isEnabled {
                            MenuBarManager.shared.setupMenuBar()
                        }
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(before: .windowList) {
                Button("Open ApexUninstaller") {
                    openMainWindow()
                }
                .keyboardShortcut("0", modifiers: .command)

                Divider()
            }
        }
        .onChange(of: NSApp.windows.count) { _, newCount in
            if newCount == 0 {
                MenuBarManager.shared.closePopover()
            }
        }
    }
    
    @MainActor
    private func openMainWindow() {
        MainWindowCoordinator.shared.show()
    }
}

@MainActor
final class MainWindowCoordinator {
    static let shared = MainWindowCoordinator()

    private var openWindowAction: OpenWindowAction?

    private init() {}

    func register(_ action: OpenWindowAction) {
        openWindowAction = action
    }

    func show() {
        if let window = NSApp.windows.first(where: { $0.title == "ApexUninstaller" }) {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        openWindowAction?(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        SmartNotificationService.shared.prepare()
        ScheduledScanManager.shared.checkAndNotifyIfNeeded()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag {
            MainWindowCoordinator.shared.show()
        }
        return true
    }
}

// MARK: - Menu Bar App Handler

final class MenuBarAppHandler: ObservableObject {
    private var observers: [NSObjectProtocol] = []
    
    init() {
        register()
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    private func register() {
        let scan = NotificationCenter.default.addObserver(
            forName: .menuBarTriggerScan,
            object: nil,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .menuBarTriggerScanReceived, object: nil)
        }
        
        let orphans = NotificationCenter.default.addObserver(
            forName: .menuBarTriggerOrphans,
            object: nil,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .menuBarTriggerOrphansReceived, object: nil)
        }
        
        let history = NotificationCenter.default.addObserver(
            forName: .menuBarTriggerHistory,
            object: nil,
            queue: .main
        ) { _ in
            NotificationCenter.default.post(name: .menuBarTriggerHistoryReceived, object: nil)
        }
        
        observers = [scan, orphans, history]
    }
}

extension Notification.Name {
    static let menuBarTriggerScanReceived = Notification.Name("menuBarTriggerScanReceived")
    static let menuBarTriggerOrphansReceived = Notification.Name("menuBarTriggerOrphansReceived")
    static let menuBarTriggerHistoryReceived = Notification.Name("menuBarTriggerHistoryReceived")
}
