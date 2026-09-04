// OnboardingSheet.swift
// ApexUninstaller - Fixed layout, NSOpenPanel flow, clean design

import SwiftUI

struct OnboardingSheet: View {
    @Bindable var bookmarkManager: BookmarkManager
    let localization: LocalizationManager
    @State private var animatePulse = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header icon
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [DesignTokens.accentPrimary.opacity(0.15), .clear], center: .center, startRadius: 10, endRadius: 50))
                    .frame(width: 90, height: 90)
                    .scaleEffect(animatePulse ? 1.1 : 0.95)
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(DesignTokens.accentGradient)
            }
            
            // Title
            VStack(spacing: 6) {
                Text(localization.localized("onboarding.title")).font(.title3.bold())
                Text(localization.localized("onboarding.subtitle")).font(.caption).foregroundStyle(.secondary)
            }
            
            // Steps
            VStack(spacing: 10) {
                stepRow(num: "1", icon: "lock.shield", text: localization.localized("onboarding.step1.desc"))
                stepRow(num: "2", icon: "folder", text: localization.localized("onboarding.step2.desc"))
                stepRow(num: "3", icon: "checkmark.seal", text: localization.localized("onboarding.step3.desc"))
            }.padding(.horizontal, 8)
            
            // Status
            HStack(spacing: 8) {
                Circle().fill(bookmarkManager.hasLibraryAccess ? Color.green : Color.orange).frame(width: 8, height: 8)
                Text(bookmarkManager.hasLibraryAccess ? localization.localized("fda.status.granted") : localization.localized("fda.status.denied"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button(localization.localized("onboarding.skip")) { bookmarkManager.showAccessOnboarding = false }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                Spacer()
                if bookmarkManager.hasLibraryAccess {
                    Button { bookmarkManager.showAccessOnboarding = false } label: {
                        Label(localization.localized("onboarding.continue"), systemImage: "checkmark")
                    }.buttonStyle(.borderedProminent).tint(.green)
                } else {
                    Button {
                        Task { @MainActor in
                            if bookmarkManager.requestLibraryAccess() {
                                // Đợi chút rồi đóng
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    bookmarkManager.showAccessOnboarding = false
                                }
                            }
                        }
                    } label: {
                        Label(localization.localized("access.grant"), systemImage: "folder.badge.plus")
                    }.buttonStyle(.borderedProminent).tint(DesignTokens.accentPrimary)
                }
            }
        }
        .padding(28)
        .frame(width: 440)
        .onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { animatePulse = true } }
    }
    
    private func stepRow(num: String, icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(DesignTokens.accentPrimary.opacity(0.15)).frame(width: 28, height: 28)
                Text(num).font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(DesignTokens.accentPrimary)
            }
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12)).foregroundStyle(.secondary).frame(width: 16)
                Text(text).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
