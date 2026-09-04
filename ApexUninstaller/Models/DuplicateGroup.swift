// DuplicateGroup.swift
// ApexUninstaller
// Model for duplicate file groups

import Foundation
import AppKit

struct DuplicateFile: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let size: UInt64
    let modifiedDate: Date?
    let hash: String

    var displayName: String {
        path.lastPathComponent
    }

    var relativePath: String {
        let home = realUserHomeDirectory.path
        let fullPath = path.path
        if fullPath.hasPrefix(home) {
            return "~" + fullPath.dropFirst(home.count)
        }
        return fullPath
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let files: [DuplicateFile]
    let hash: String

    var totalSize: UInt64 {
        files.reduce(0) { $0 + $1.size }
    }

    var wastedSize: UInt64 {
        guard files.count > 1 else { return 0 }
        return totalSize - files[0].size
    }

    var fileCount: Int { files.count }
}

struct DuplicateScanResult {
    var groups: [DuplicateGroup] = []
    var totalWastedSize: UInt64 = 0
    var totalFilesScanned: Int = 0
    var isComplete: Bool = false

    var totalDuplicateSize: UInt64 {
        groups.reduce(0) { $0 + $1.totalSize }
    }
}

// MARK: - Large Files

struct LargeFile: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let size: UInt64
    let modifiedDate: Date?
    let fileType: String

    var displayName: String { path.lastPathComponent }
    var relativePath: String {
        let home = realUserHomeDirectory.path
        let fullPath = path.path
        if fullPath.hasPrefix(home) { return "~" + fullPath.dropFirst(home.count) }
        return fullPath
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct LargeFileScanResult {
    var files: [LargeFile] = []
    var totalScanned: Int = 0
    var isComplete: Bool = false

    var totalSize: UInt64 {
        files.reduce(0) { $0 + $1.size }
    }
}
