// EmptyStateView.swift
// ApexUninstaller

import SwiftUI

struct EmptyStateView: View {
    let hasApps: Bool
    let localization: LocalizationManager
    @State private var animateGradient = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [DesignTokens.accentPrimary.opacity(0.15), .clear], center: .center, startRadius: 20, endRadius: 80))
                    .frame(width: 160, height: 160)
                    .scaleEffect(animateGradient ? 1.1 : 0.9)
                Image(systemName: hasApps ? "arrow.left.circle" : "magnifyingglass.circle")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundStyle(LinearGradient(colors: [DesignTokens.accentPrimary, DesignTokens.accentPrimary.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            VStack(spacing: 8) {
                Text(hasApps ? localization.localized("empty.selectApp") : "ApexUninstaller")
                    .font(.title2.bold())
                Text(hasApps ? localization.localized("empty.selectAppDesc") : localization.localized("empty.welcomeDesc"))
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(4)
            }
            if !hasApps {
                VStack(spacing: 12) {
                    featureRow(icon: "magnifyingglass", title: localization.localized("empty.feature.scan"), desc: localization.localized("empty.feature.scanDesc"))
                    featureRow(icon: "shield.checkered", title: localization.localized("empty.feature.safe"), desc: localization.localized("empty.feature.safeDesc"))
                    featureRow(icon: "bolt.fill", title: localization.localized("empty.feature.fast"), desc: localization.localized("empty.feature.fastDesc"))
                }.padding(.top, 8)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { animateGradient = true } }
    }
    
    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(DesignTokens.accentPrimary)
                .frame(width: 32, height: 32).background(DesignTokens.accentPrimary.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(.subheadline, weight: .medium))
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }.frame(maxWidth: 320)
    }
}
