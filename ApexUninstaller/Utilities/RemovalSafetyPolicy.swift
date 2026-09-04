// RemovalSafetyPolicy.swift
// ApexUninstaller

import Foundation

enum RemovalSafetyPolicy {
    static let blockedMessage = "Blocked by ApexUninstaller safety policy."

    private static let blockedExactPaths: Set<String> = [
        "/", "/Applications", "/Library", "/System", "/Users", "/Volumes",
        "/bin", "/dev", "/etc", "/opt", "/private", "/sbin", "/usr", "/var"
    ]

    private static let blockedPathPrefixes = [
        "/System/", "/bin/", "/dev/", "/etc/", "/sbin/", "/usr/",
        "/private/etc/", "/private/var/db/", "/private/var/root/", "/private/var/vm/"
    ]

    static func canMoveToTrash(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }

        let path = normalizedPath(url)
        guard !path.isEmpty, !blockedExactPaths.contains(path) else { return false }
        guard !blockedPathPrefixes.contains(where: { path.hasPrefix($0) }) else { return false }

        let home = normalizedPath(realUserHomeDirectory)
        let protectedUserRoots: Set<String> = [
            home,
            home + "/Applications",
            home + "/Library",
            home + "/.Trash"
        ]
        guard !protectedUserRoots.contains(path) else { return false }

        let runningApp = normalizedPath(Bundle.main.bundleURL)
        guard path != runningApp, !path.hasPrefix(runningApp + "/") else { return false }

        return true
    }

    static func normalizedPath(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path
    }
}
