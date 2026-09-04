// AppModel.swift
// ApexUninstaller
//
// Data model đại diện cho một ứng dụng macOS được quét trên hệ thống.

import Foundation
import AppKit

enum AppInstallSource: String, Hashable {
    case appStore
    case external
    
    var localizationKey: String {
        switch self {
        case .appStore: return "insights.source.appStore"
        case .external: return "insights.source.external"
        }
    }
}

/// Thông tin chi tiết của một ứng dụng macOS
struct AppInfo: Identifiable, Hashable {
    let id: UUID
    let name: String
    let bundleIdentifier: String
    let path: URL
    let icon: NSImage
    let appSize: UInt64
    let version: String
    let buildVersion: String?
    let minimumSystemVersion: String?
    let lastModified: Date?
    let installSource: AppInstallSource
    var leftovers: [LeftoverFile]
    var hasScannedLeftovers: Bool
    
    /// Tổng dung lượng bao gồm app + tất cả file rác
    var totalSize: UInt64 {
        appSize + leftovers.reduce(0) { $0 + $1.size }
    }
    
    /// Tổng dung lượng các file rác
    var leftoverSize: UInt64 {
        leftovers.reduce(0) { $0 + $1.size }
    }
    
    /// Số file rác đã được chọn để xóa
    var selectedLeftoverCount: Int {
        leftovers.filter { $0.isSelected }.count
    }
    
    /// Dung lượng các file rác đã chọn
    var selectedLeftoverSize: UInt64 {
        leftovers.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    /// File có độ tin cậy cao hoặc trung bình, mặc định nên được chọn.
    var recommendedLeftoverCount: Int {
        leftovers.filter { $0.confidence.isRecommended }.count
    }
    
    /// File match yếu, cần user xem kỹ trước khi chọn.
    var reviewRequiredLeftoverCount: Int {
        leftovers.filter { $0.confidence == .review }.count
    }
    
    /// Số mục review đang được chọn thủ công.
    var selectedReviewLeftoverCount: Int {
        leftovers.filter { $0.isSelected && $0.confidence == .review }.count
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        path: URL,
        icon: NSImage,
        appSize: UInt64,
        version: String = "Unknown",
        buildVersion: String? = nil,
        minimumSystemVersion: String? = nil,
        lastModified: Date? = nil,
        installSource: AppInstallSource = .external,
        leftovers: [LeftoverFile] = [],
        hasScannedLeftovers: Bool = false
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.icon = icon
        self.appSize = appSize
        self.version = version
        self.buildVersion = buildVersion
        self.minimumSystemVersion = minimumSystemVersion
        self.lastModified = lastModified
        self.installSource = installSource
        self.leftovers = leftovers
        self.hasScannedLeftovers = hasScannedLeftovers
    }
    
    // MARK: - Hashable
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
        && lhs.name == rhs.name
        && lhs.bundleIdentifier == rhs.bundleIdentifier
        && lhs.path == rhs.path
        && lhs.appSize == rhs.appSize
        && lhs.version == rhs.version
        && lhs.hasScannedLeftovers == rhs.hasScannedLeftovers
        && lhs.leftovers == rhs.leftovers
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Thứ tự sắp xếp danh sách ứng dụng
enum AppSortOrder: String, CaseIterable, Identifiable {
    case nameAsc = "name_asc"
    case nameDesc = "name_desc"
    case sizeDesc = "size_desc"
    case sizeAsc = "size_asc"
    case leftoverCount = "leftover_count"
    
    var id: String { rawValue }
    
    var localizationKey: String {
        switch self {
        case .nameAsc: return "sort.nameAsc"
        case .nameDesc: return "sort.nameDesc"
        case .sizeDesc: return "sort.sizeDesc"
        case .sizeAsc: return "sort.sizeAsc"
        case .leftoverCount: return "sort.leftoverCount"
        }
    }
    
    var icon: String {
        switch self {
        case .nameAsc: return "textformat.abc"
        case .nameDesc: return "textformat.abc"
        case .sizeDesc: return "arrow.down.circle"
        case .sizeAsc: return "arrow.up.circle"
        case .leftoverCount: return "doc.badge.gearshape"
        }
    }
}
