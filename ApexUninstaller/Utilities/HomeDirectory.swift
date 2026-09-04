// HomeDirectory.swift
// ApexUninstaller
// Shared utility to get the real user home directory outside the sandbox container.

import Foundation
import Darwin

/// Returns the real user home directory, bypassing the App Sandbox container.
/// In App Sandbox, `FileManager.homeDirectoryForCurrentUser` and `NSHomeDirectory()`
/// both return the sandbox container path. This function uses `getpwuid` to get the
/// actual home directory (e.g. /Users/username).
var realUserHomeDirectory: URL {
    if let passwd = getpwuid(getuid()), let home = passwd.pointee.pw_dir {
        return URL(fileURLWithPath: String(cString: home), isDirectory: true).standardizedFileURL
    }
    return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).standardizedFileURL
}
