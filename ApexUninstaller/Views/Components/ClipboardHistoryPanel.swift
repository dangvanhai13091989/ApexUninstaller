// ClipboardHistoryPanel.swift
// ApexUninstaller

import AppKit
import SwiftUI

@MainActor
final class ClipboardHistoryPanelController {
    static let shared = ClipboardHistoryPanelController()

    private var panel: NSPanel?

    func toggle() {
        if panel?.isVisible == true {
            close()
        } else {
            show()
        }
    }

    func show() {
        let manager = ClipboardHistoryManager.shared
        let rootView = ClipboardHistoryPanel(manager: manager) { [weak self] entry in
                self?.finishSelection(entry, using: manager)
            }
            // NSHostingController otherwise uses the smallest intrinsic size
            // when this panel has no history entries. Keep the utility window
            // usable in every state, including when the feature is paused.
            .frame(minWidth: 600, minHeight: 500)

        if panel == nil {
            let newPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                // Keep the utility separate from the main window. In
                // particular, do not activate ApexUninstaller when the global
                // shortcut is pressed: the app and text field the user was
                // working in remain active behind this panel.
                styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.isReleasedWhenClosed = false
            newPanel.isFloatingPanel = true
            newPanel.hidesOnDeactivate = false
            newPanel.level = .floating
            newPanel.minSize = NSSize(width: 520, height: 420)
            newPanel.isMovable = true
            // Use a fresh autosave key after increasing the default size. Older
            // installations may have a persisted 440 pt frame, which would
            // otherwise override this window's new, usable default.
            newPanel.setFrameAutosaveName("ApexUninstaller.clipboardHistoryPanel.v2")
            newPanel.title = "Clipboard History"
            newPanel.center()
            panel = newPanel
        }

        panel?.contentViewController = NSHostingController(rootView: rootView)
        panel?.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
    }

    private func finishSelection(_ entry: ClipboardHistoryEntry, using manager: ClipboardHistoryManager) {
        if manager.copyToPasteboard(entry) {
            panel?.orderOut(nil)
        }
    }
}

private struct ClipboardHistoryPanel: View {
    @State private var manager: ClipboardHistoryManager
    let onSelect: (ClipboardHistoryEntry) -> Void

    private var localization: LocalizationManager { LocalizationManager.shared }

    init(manager: ClipboardHistoryManager, onSelect: @escaping (ClipboardHistoryEntry) -> Void) {
        _manager = State(initialValue: manager)
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.localized("clipboard.title"))
                        .font(.headline)
                    Text(ClipboardHistoryManager.shared.shortcut.displayString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(localization.localized("clipboard.clear"), role: .destructive) {
                    manager.clearHistory()
                }
                .disabled(manager.entries.isEmpty)
            }

            if !manager.isEnabled {
                ContentUnavailableView(
                    localization.localized("clipboard.paused.title"),
                    systemImage: "clipboard",
                    description: Text(localization.localized("clipboard.paused.description"))
                )
            } else if manager.entries.isEmpty {
                ContentUnavailableView(
                    localization.localized("clipboard.empty.title"),
                    systemImage: "doc.on.clipboard",
                    description: Text(localization.localized("clipboard.empty.description"))
                )
            } else {
                List(manager.entries) { entry in
                    Button {
                        onSelect(entry)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            if entry.isImage, let image = manager.image(for: entry) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 44, height: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            } else {
                                Image(systemName: entry.kindIcon)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 18)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.preview)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Text(entry.capturedAt, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)
            }

            Text(localization.localized("clipboard.footer"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
    }
}
