// ClipboardHotkeyManager.swift
// ApexUninstaller
//
// Registers one user-selected global shortcut. This uses the system hotkey API,
// not a keyboard-event monitor: it does not inspect keystrokes and needs
// neither Accessibility nor Input Monitoring permission.

import Carbon.HIToolbox
import Foundation
import Observation

@Observable
@MainActor
final class ClipboardHotkeyManager {
    static let shared = ClipboardHotkeyManager()

    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private(set) var isRegistered = false
    private(set) var registeredShortcut = ClipboardShortcut.defaultValue
    private(set) var failedShortcut: ClipboardShortcut?

    private init() {}

    @discardableResult
    func register(
        shortcut: ClipboardShortcut,
        clearsFailure: Bool = true
    ) -> Bool {
        if hotKey != nil, registeredShortcut == shortcut {
            if clearsFailure {
                failedShortcut = nil
            }
            return true
        }

        unregisterHotKey()
        installEventHandlerIfNeeded()

        guard eventHandler != nil else {
            isRegistered = false
            failedShortcut = shortcut
            return false
        }

        let identifier = EventHotKeyID(signature: OSType(0x4150_4558), id: 1) // APEX
        let registrationStatus = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )

        guard registrationStatus == noErr else {
            hotKey = nil
            isRegistered = false
            failedShortcut = shortcut
            print("ClipboardHotkeyManager: \(shortcut.displayString) is unavailable (\(registrationStatus)).")
            return false
        }

        registeredShortcut = shortcut
        isRegistered = true
        if clearsFailure {
            failedShortcut = nil
        }
        return true
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            clipboardHotkeyHandler,
            1,
            &eventType,
            nil,
            &eventHandler
        )
        guard handlerStatus == noErr else {
            eventHandler = nil
            print("ClipboardHotkeyManager: could not install event handler (\(handlerStatus)).")
            return
        }
    }

    private func unregisterHotKey() {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
            self.hotKey = nil
        }
        isRegistered = false
    }
}

private func clipboardHotkeyHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    Task { @MainActor in
        ClipboardHistoryPanelController.shared.toggle()
    }
    return noErr
}
