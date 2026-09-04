// NSImage+Extensions.swift
// ApexUninstaller
//
// Extensions cho NSImage hỗ trợ xử lý icon ứng dụng.

import AppKit

extension NSImage {
    /// Resize ảnh về kích thước cụ thể
    func resized(to targetSize: NSSize) -> NSImage {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        self.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: self.size),
            operation: .sourceOver,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }
    
    /// Icon mặc định cho ứng dụng khi không lấy được icon thực
    static var defaultAppIcon: NSImage {
        NSWorkspace.shared.icon(for: .applicationBundle)
    }
}
