// FileSize+Extensions.swift
// ApexUninstaller
//
// Extension format dung lượng file cho hiển thị thân thiện.

import Foundation

extension UInt64 {
    /// Format dung lượng file thành chuỗi dễ đọc (KB, MB, GB)
    /// Ví dụ: 1536 → "1.5 KB", 1048576 → "1.0 MB"
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: Int64(self))
    }
    
    /// Format ngắn gọn hơn cho sidebar
    var compactSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        formatter.zeroPadsFractionDigits = false
        return formatter.string(fromByteCount: Int64(self))
    }
}

extension Int {
    /// Format số lượng file rác
    var leftoverLabel: String {
        if self == 0 {
            return "Chưa quét"
        } else if self == 1 {
            return "1 tệp rác"
        } else {
            return "\(self) tệp rác"
        }
    }
}
