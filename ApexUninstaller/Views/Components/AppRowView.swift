// AppRowView.swift
// ApexUninstaller
//
// Row hiển thị thông tin một ứng dụng trong sidebar.

import SwiftUI

struct AppRowView: View {
    let app: AppInfo
    let isSelected: Bool
    let isScanningLeftovers: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            
            // App Info
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // Dung lượng app
                    Text(app.appSize.compactSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Badge leftovers
                    if app.hasScannedLeftovers && !app.leftovers.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.badge.gearshape")
                                .font(.system(size: 9))
                            Text("\(app.leftovers.count)")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.orange.gradient)
                        )
                    }
                }
            }
            
            Spacer()
            
            // Tổng dung lượng nếu có leftovers
            if isScanningLeftovers {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 18, height: 18)
            } else if app.hasScannedLeftovers && app.leftoverSize > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(app.totalSize.compactSize)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(DesignTokens.accentPrimary)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
