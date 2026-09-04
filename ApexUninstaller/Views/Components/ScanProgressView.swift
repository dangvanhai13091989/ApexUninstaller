// ScanProgressView.swift
// ApexUninstaller
// View hiển thị tiến trình quét ứng dụng với animation.

import SwiftUI

struct ScanProgressView: View {
    let progress: Double
    let appName: String
    let isLeftoverScan: Bool
    let localization: LocalizationManager
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().stroke(DesignTokens.accentPrimary.opacity(0.2), lineWidth: 4).frame(width: 80, height: 80)
                Circle().trim(from: 0, to: progress)
                    .stroke(DesignTokens.accentGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80).rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                Image(systemName: isLeftoverScan ? "doc.text.magnifyingglass" : "magnifyingglass")
                    .font(.system(size: 28, weight: .light)).foregroundStyle(DesignTokens.accentPrimary)
                    .rotationEffect(.degrees(rotation))
            }
            VStack(spacing: 8) {
                Text(isLeftoverScan ? localization.localized("scan.leftovers") : localization.localized("scan.apps"))
                    .font(.headline).foregroundStyle(.primary)
                if !appName.isEmpty {
                    Text(appName).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                }
                Text("\(Int(progress * 100))%")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(DesignTokens.accentPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut, value: progress)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) { rotation = 360 } }
    }
}
