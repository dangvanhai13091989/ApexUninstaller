// LeftoverRowView.swift
// ApexUninstaller
//
// Row hiển thị thông tin một tệp rác (leftover) trong detail view.

import SwiftUI

struct LeftoverRowView: View {
    let leftover: LeftoverFile
    let localization: LocalizationManager
    let onToggle: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: leftover.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(leftover.isSelected ? leftover.category.color : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            
            // Category Icon
            Image(systemName: leftover.category.icon)
                .font(.system(size: 14))
                .foregroundStyle(leftover.category.color)
                .frame(width: 24)
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(leftover.displayName)
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(leftover.relativePath)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if !leftover.matchReason.isEmpty {
                    Text(leftover.matchReason)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Confidence badge
            Label(localization.localized(leftover.confidence.localizationKey), systemImage: leftover.confidence.icon)
                .labelStyle(.titleAndIcon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(leftover.confidence.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(leftover.confidence.color.opacity(0.15)))
            
            // File size
            Text(leftover.size.formattedSize)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}
