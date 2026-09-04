// SmartNotificationService.swift
// ApexUninstaller
// Intelligent notification service for cleanup reminders

import Foundation
import UserNotifications
import AppKit

final class SmartNotificationService {
    
    static let shared = SmartNotificationService()
    
    private init() {
        setupNotificationCategories()
    }
    
    // MARK: - Public API
    
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "ApexUninstaller.smartNotificationsEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "ApexUninstaller.smartNotificationsEnabled")
            if newValue {
                requestPermission()
            }
        }
    }
    
    var thresholdJunkSize: UInt64 {
        get {
            let stored = UserDefaults.standard.integer(forKey: "ApexUninstaller.junkThreshold")
            return stored > 0 ? UInt64(stored) : 500 * 1024 * 1024 // Default 500MB
        }
        set { UserDefaults.standard.set(Int(newValue), forKey: "ApexUninstaller.junkThreshold") }
    }
    
    // MARK: - Permission
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func prepare() {
        // Accessing the singleton registers notification categories without prompting.
    }
    
    func checkPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    // MARK: - Setup Categories
    
    private func setupNotificationCategories() {
        let lang = LocalizationManager.shared.currentLanguage
        
        let cleanAction = UNNotificationAction(
            identifier: "CLEAN_ACTION",
            title: L10n.string("notification.action.clean", language: lang),
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: L10n.string("notification.action.dismiss", language: lang),
            options: []
        )
        
        let cleanupCategory = UNNotificationCategory(
            identifier: "CLEANUP_CATEGORY",
            actions: [cleanAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([cleanupCategory])
    }
    
    // MARK: - Send Notifications
    
    func sendJunkReminder(totalJunk: UInt64, appCount: Int) {
        guard isEnabled else { return }
        guard totalJunk >= thresholdJunkSize else { return }
        
        let lastNotification = UserDefaults.standard.object(forKey: "ApexUninstaller.lastJunkReminder") as? Date
        if let last = lastNotification, Date().timeIntervalSince(last) < 24 * 60 * 60 {
            return
        }
        
        let lang = LocalizationManager.shared.currentLanguage
        let content = UNMutableNotificationContent()
        content.title = L10n.string("notification.junkReminder.title", language: lang)
        content.body = L10n.string("notification.junkReminder.body", language: lang, totalJunk.formattedSize, appCount)
        content.sound = .default
        content.categoryIdentifier = "CLEANUP_CATEGORY"
        content.badge = NSNumber(value: appCount)
        
        let request = UNNotificationRequest(
            identifier: "junkReminder",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        UserDefaults.standard.set(Date(), forKey: "ApexUninstaller.lastJunkReminder")
    }
    
    func sendLargeLeftoverAlert(appName: String, size: UInt64) {
        guard isEnabled else { return }
        guard size >= 1024 * 1024 * 1024 else { return } // Only > 1GB

        let throttleKey = "ApexUninstaller.lastLargeLeftoverAlert.\(appName)"
        let lastNotification = UserDefaults.standard.object(forKey: throttleKey) as? Date
        if let last = lastNotification, Date().timeIntervalSince(last) < 7 * 24 * 60 * 60 {
            return
        }
        
        let lang = LocalizationManager.shared.currentLanguage
        let content = UNMutableNotificationContent()
        content.title = L10n.string("notification.largeLeftover.title", language: lang)
        content.body = L10n.string("notification.largeLeftover.body", language: lang, appName, size.formattedSize)
        content.sound = .default
        content.categoryIdentifier = "CLEANUP_CATEGORY"
        
        let request = UNNotificationRequest(
            identifier: "largeLeftover.\(appName)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        UserDefaults.standard.set(Date(), forKey: throttleKey)
    }
    
    func sendCleanupCompleteNotification(appName: String, reclaimedSize: UInt64) {
        guard isEnabled else { return }
        
        let lang = LocalizationManager.shared.currentLanguage
        let content = UNMutableNotificationContent()
        content.title = L10n.string("notification.cleanupComplete.title", language: lang)
        content.body = L10n.string("notification.cleanupComplete.body", language: lang, appName, reclaimedSize.formattedSize)
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "cleanupComplete.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Clear Notifications
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        NSApp.dockTile.badgeLabel = nil
    }
    
    func clearBadge() {
        NSApp.dockTile.badgeLabel = nil
    }
}

// MARK: - UNUserNotificationCenterDelegate Helper

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "CLEAN_ACTION":
            // User chose to clean - open main app
            openMainApp()
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped notification
            openMainApp()
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func openMainApp() {
        NSApp.activate()
    }
}
