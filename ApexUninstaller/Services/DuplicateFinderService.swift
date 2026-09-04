// DuplicateFinderService.swift
// ApexUninstaller
// Finds duplicate files by size + SHA256 hash comparison.
// Algorithm: group by size -> hash only same-size files -> compare hashes

import Foundation
import CryptoKit

actor DuplicateFinderService {

    static let shared = DuplicateFinderService()

    private let fileManager = FileManager.default

    // MARK: - Public API

    /// Scan for duplicates in a list of directories.
    /// Uses security-scoped bookmarks for ~/Library and user-selected directories.
    func scan(
        directories: [URL],
        libraryBookmarkURL: URL?,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async -> DuplicateScanResult {
        var result = DuplicateScanResult()

        progressHandler(0.05, "Scanning directories...")

        var allFiles: [URL] = []
        var sizeGroups: [UInt64: [URL]] = [:]

        for dir in directories {
            let directoryAccessStarted = dir.startAccessingSecurityScopedResource()
            let libraryAccessStarted = libraryBookmarkURL?.startAccessingSecurityScopedResource() ?? false
            defer {
                if directoryAccessStarted { dir.stopAccessingSecurityScopedResource() }
                if libraryAccessStarted { libraryBookmarkURL?.stopAccessingSecurityScopedResource() }
            }

            guard let enumerator = fileManager.enumerator(
                at: dir,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            while let fileURL = enumerator.nextObject() as? URL {
                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                      values.isRegularFile == true,
                      let fileSize = values.fileSize,
                      fileSize > 0 else {
                    continue
                }

                allFiles.append(fileURL)
                sizeGroups[UInt64(fileSize), default: []].append(fileURL)
            }
        }

        result.totalFilesScanned = allFiles.count

        let candidates = sizeGroups.filter { $0.value.count > 1 }.flatMap { $0.value }
        let candidateCount = candidates.count

        if candidateCount == 0 {
            result.isComplete = true
            return result
        }

        progressHandler(0.1, "Comparing files...")

        var hashGroups: [String: [DuplicateFile]] = [:]

        let batchSize = 50

        for batchStart in stride(from: 0, to: candidateCount, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, candidateCount)
            let batchFiles = Array(candidates[batchStart..<batchEnd])

            await withTaskGroup(of: [DuplicateFile].self) { group in
                for fileURL in batchFiles {
                    group.addTask {
                        await self.hashFile(fileURL)
                    }
                }

                for await files in group {
                    for file in files {
                        hashGroups[file.hash, default: []].append(file)
                    }
                }
            }

            let hashProgress = 0.1 + (Double(batchEnd) / Double(candidateCount)) * 0.85
            progressHandler(hashProgress, "Hashing files \(batchEnd)/\(candidateCount)...")
        }

        let duplicateHashes = hashGroups.filter { $0.value.count > 1 }

        for (_, files) in duplicateHashes {
            let sorted = files.sorted { ($0.modifiedDate ?? .distantPast) > ($1.modifiedDate ?? .distantPast) }
            let group = DuplicateGroup(files: sorted, hash: sorted.first?.hash ?? "")
            result.groups.append(group)
            result.totalWastedSize += group.wastedSize
        }

        result.groups.sort { $0.wastedSize > $1.wastedSize }

        progressHandler(1.0, "Done")
        result.isComplete = true
        return result
    }

    /// Quick scan for a single directory.
    func quickScan(
        directory: URL,
        libraryBookmarkURL: URL?,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async -> DuplicateScanResult {
        await scan(
            directories: [directory],
            libraryBookmarkURL: libraryBookmarkURL,
            progressHandler: progressHandler
        )
    }

    /// Scan for large files in a list of directories.
    func scanLargeFiles(
        directories: [URL],
        libraryBookmarkURL: URL?,
        minSizeMB: Int = 10,
        progressHandler: @escaping @Sendable (Double, String) -> Void
    ) async -> LargeFileScanResult {
        var result = LargeFileScanResult()
        let minBytes = UInt64(minSizeMB) * 1024 * 1024

        progressHandler(0.1, "Scanning for large files...")

        var allLargeFiles: [LargeFile] = []
        var scannedCount = 0

        for dir in directories {
            let directoryAccessStarted = dir.startAccessingSecurityScopedResource()
            let libraryAccessStarted = libraryBookmarkURL?.startAccessingSecurityScopedResource() ?? false
            defer {
                if directoryAccessStarted { dir.stopAccessingSecurityScopedResource() }
                if libraryAccessStarted { libraryBookmarkURL?.stopAccessingSecurityScopedResource() }
            }

            guard let enumerator = fileManager.enumerator(
                at: dir,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            while let fileURL = enumerator.nextObject() as? URL {
                scannedCount += 1

                if scannedCount % 5000 == 0 {
                    progressHandler(0.1 + Double(scannedCount) / 100000.0 * 0.6, "Scanned \(scannedCount) files...")
                }

                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey, .contentModificationDateKey]),
                      values.isRegularFile == true,
                      let fileSize = values.fileSize,
                      UInt64(fileSize) >= minBytes else {
                    continue
                }

                let ext = fileURL.pathExtension.lowercased()
                let fileType = ext.isEmpty ? "file" : ext

                allLargeFiles.append(LargeFile(
                    path: fileURL,
                    size: UInt64(fileSize),
                    modifiedDate: values.contentModificationDate,
                    fileType: fileType
                ))
            }
        }

        result.totalScanned = scannedCount

        // Sort by size descending, take top 200
        allLargeFiles.sort { $0.size > $1.size }
        result.files = Array(allLargeFiles.prefix(200))

        progressHandler(1.0, "Done")
        result.isComplete = true
        return result
    }

    // MARK: - Hashing
    // MARK: - Hashing

    private func hashFile(_ url: URL) async -> [DuplicateFile] {
        guard let hash = computeSHA256(url: url) else {
            return []
        }

        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let size = UInt64(values?.fileSize ?? 0)
        let modified = values?.contentModificationDate

        return [DuplicateFile(path: url, size: size, modifiedDate: modified, hash: hash)]
    }

    private func computeSHA256(url: URL) -> String? {
        let bufferSize = 1024 * 1024 // 1MB chunks

        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { try? handle.close() }

        var hasher = SHA256()

        while true {
            let data = handle.readData(ofLength: bufferSize)
            if data.isEmpty { break }
            hasher.update(data: data)
        }

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
