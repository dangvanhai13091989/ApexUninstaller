// GlassBackground.swift
// ApexUninstaller
//
// Custom ViewModifier tạo hiệu ứng kính mờ (glassmorphism) cho giao diện.

import SwiftUI

/// Glassmorphism background modifier
struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 12
    var opacity: Double = 0.6
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

/// Glass card style với padding
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 12
    var padding: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .modifier(GlassBackground(cornerRadius: cornerRadius))
    }
}

/// Hover effect cho interactive elements
struct HoverScale: ViewModifier {
    @State private var isHovered = false
    var scale: CGFloat = 1.02
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Áp dụng hiệu ứng glassmorphism
    func glassBackground(cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
    
    /// Áp dụng glass card style với padding
    func glassCard(cornerRadius: CGFloat = 12, padding: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, padding: padding))
    }
    
    /// Áp dụng hover scale effect
    func hoverScale(_ scale: CGFloat = 1.02) -> some View {
        modifier(HoverScale(scale: scale))
    }
}

// MARK: - Design Tokens

/// Bảng màu thiết kế
enum DesignTokens {
    // Accent colors
    static let accentPrimary = Color(nsColor: NSColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 1.0))
    static let accentDanger = Color.red
    
    // Surface colors
    static let surfaceElevated = Color(nsColor: .controlBackgroundColor)
    
    // Category colors
    static let categoryCache = Color.orange
    static let categoryPref = Color.blue
    static let categorySupport = Color.purple
    static let categoryContainer = Color.green
    
    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(nsColor: NSColor(red: 0.08, green: 0.08, blue: 0.14, alpha: 1.0)),
            Color(nsColor: NSColor(red: 0.12, green: 0.10, blue: 0.20, alpha: 1.0)),
            Color(nsColor: NSColor(red: 0.06, green: 0.06, blue: 0.12, alpha: 1.0))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.39, green: 0.40, blue: 0.95),
            Color(red: 0.55, green: 0.36, blue: 0.97)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
