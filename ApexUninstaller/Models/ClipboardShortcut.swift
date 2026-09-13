// ClipboardShortcut.swift
// ApexUninstaller
//
// A deliberately small list of global shortcuts. Each choice contains Command
// or Control so it does not observe ordinary typing and remains compatible
// with the system's global-hotkey protections.

import Carbon.HIToolbox
import Foundation

enum ClipboardShortcut: String, CaseIterable, Codable, Identifiable {
    case optionCommandV
    case controlOptionV
    case controlCommandV
    case controlOptionH
    case controlCommandH

    static let defaultValue: ClipboardShortcut = .optionCommandV

    var id: String { rawValue }

    var keyCode: UInt32 {
        switch self {
        case .optionCommandV, .controlOptionV, .controlCommandV:
            UInt32(kVK_ANSI_V)
        case .controlOptionH, .controlCommandH:
            UInt32(kVK_ANSI_H)
        }
    }

    var modifiers: UInt32 {
        switch self {
        case .optionCommandV:
            UInt32(optionKey) | UInt32(cmdKey)
        case .controlOptionV, .controlOptionH:
            UInt32(controlKey) | UInt32(optionKey)
        case .controlCommandV, .controlCommandH:
            UInt32(controlKey) | UInt32(cmdKey)
        }
    }

    var displayString: String {
        switch self {
        case .optionCommandV:
            "⌥⌘V"
        case .controlOptionV:
            "⌃⌥V"
        case .controlCommandV:
            "⌃⌘V"
        case .controlOptionH:
            "⌃⌥H"
        case .controlCommandH:
            "⌃⌘H"
        }
    }
}
