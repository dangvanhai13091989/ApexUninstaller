// ScheduledScanManager.swift
// ApexUninstaller
// Service to manage scheduled automatic scans

import Foundation
import UserNotifications

final class ScheduledScanManager {
    
    static let shared = ScheduledScanManager()
    
    private let userDefaults = UserDefaults.standard
    private let lastScanDateKey = "ApexUninstaller.lastAutoScanDate"
    private let scanIntervalKey = "ApexUninstaller.scanInterval"
    private let autoScanEnabledKey = "ApexUninstaller.autoScanEnabled"
    
    enum ScanInterval: Int, CaseIterable {
        case daily = 1
        case weekly = 7
        case monthly = 30
        
        var days: Int { rawValue }
        
        var displayName: String {
            let lang = LocalizationManager.shared.currentLanguage
            switch self {
            case .daily: return L10n.string("schedule.daily", language: lang)
            case .weekly: return L10n.string("schedule.weekly", language: lang)
            case .monthly: return L10n.string("schedule.monthly", language: lang)
            }
        }
    }
    
    private init() {}
    
    // MARK: - Public API
    
    var isAutoScanEnabled: Bool {
        get { userDefaults.bool(forKey: autoScanEnabledKey) }
        set {
            userDefaults.set(newValue, forKey: autoScanEnabledKey)
            if newValue {
                requestNotificationPermission()
                scheduleNotification()
            } else {
                cancelScheduledNotification()
            }
        }
    }
    
    var scanInterval: ScanInterval {
        get {
            let rawValue = userDefaults.integer(forKey: scanIntervalKey)
            return ScanInterval(rawValue: rawValue) ?? .weekly
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: scanIntervalKey)
            if isAutoScanEnabled {
                scheduleNotification()
            }
        }
    }
    
    var lastAutoScanDate: Date? {
        get { userDefaults.object(forKey: lastScanDateKey) as? Date }
        set { userDefaults.set(newValue, forKey: lastScanDateKey) }
    }
    
    var shouldNotifyUser: Bool {
        guard isAutoScanEnabled, let lastScan = lastAutoScanDate else {
            return isAutoScanEnabled
        }
        
        let nextScanDate = Calendar.current.date(byAdding: .day, value: scanInterval.days, to: lastScan)!
        return Date() >= nextScanDate
    }
    
    func markScanCompleted() {
        lastAutoScanDate = Date()
        if isAutoScanEnabled {
            scheduleNotification()
        }
    }
    
    func checkAndNotifyIfNeeded() {
        guard shouldNotifyUser else { return }
        
        let lang = LocalizationManager.shared.currentLanguage
        let content = UNMutableNotificationContent()
        content.title = L10n.string("notification.title", language: lang)
        content.body = L10n.string("notification.body", language: lang)
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "com.apexuninstaller.autoscan",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Private
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleNotification() {
        cancelScheduledNotification()
        
        guard isAutoScanEnabled, let lastScan = lastAutoScanDate else { return }
        
        let nextScanDate = Calendar.current.date(byAdding: .day, value: scanInterval.days, to: lastScan)!
        let timeInterval = nextScanDate.timeIntervalSinceNow
        
        guard timeInterval > 0 else { return }
        
        let lang = LocalizationManager.shared.currentLanguage
        let content = UNMutableNotificationContent()
        content.title = L10n.string("notification.title", language: lang)
        content.body = L10n.string("notification.body", language: lang)
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "com.apexuninstaller.autoscan",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelScheduledNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["com.apexuninstaller.autoscan"])
    }
}
