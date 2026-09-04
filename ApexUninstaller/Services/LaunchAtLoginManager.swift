// LaunchAtLoginManager.swift
// ApexUninstaller
// Launch at Login support using SMAppService (macOS 13+)

import Foundation
import AppKit
import ServiceManagement

@Observable
final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    
    private let service = SMAppService.mainApp
    
    var isEnabled: Bool {
        get { status == .enabled }
        set {
            do {
                if newValue {
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                print("LaunchAtLoginManager: failed to \(newValue ? "enable" : "disable") - \(error)")
            }
        }
    }
    
    private var status: SMAppService.Status {
        service.status
    }
    
    var statusDescription: String {
        switch status {
        case .enabled: return "Enabled"
        case .notRegistered: return "Disabled"
        case .notFound: return "Not found"
        case .requiresApproval: return "Requires approval in System Settings"
        @unknown default: return "Unknown"
        }
    }
    
    var requiresApproval: Bool {
        status == .requiresApproval
    }
    
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
