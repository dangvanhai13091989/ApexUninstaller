// DistributionChannel.swift
// ApexUninstaller

import AppKit

enum DistributionChannel {
    #if DIRECT_DISTRIBUTION
    static let isDirect = true
    static let displayName = "Direct"
    #else
    static let isDirect = false
    static let displayName = "Mac App Store"
    #endif

    static let repositoryURL = URL(string: "https://github.com/dangvanhai13091989/ApexUninstaller")!
    static let sponsorsURL = URL(string: "https://github.com/dangvanhai13091989/ApexUninstaller#support-development")!

    @MainActor
    static func openFullDiskAccessSettings() {
        guard isDirect,
              let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
