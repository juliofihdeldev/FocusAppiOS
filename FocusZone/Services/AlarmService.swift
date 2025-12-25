import Foundation
import UserNotifications
import SwiftUI
import SwiftData

// Conditional import for AlarmKit (iOS 18+)
#if canImport(AlarmKit)
import AlarmKit
#endif

@MainActor
class AlarmService: ObservableObject {
    static let shared = AlarmService()
    
    @Published var isAlarmKitSupported: Bool = false
    @Published var isAuthorized: Bool = false
    
    private init() {
        checkAlarmKitSupport()
        checkAuthorizationStatus()
    }
    
    // MARK: - AlarmKit Support Check
    
    private func checkAlarmKitSupport() {
        print("🔍 Checking AlarmKit support...")
        print("📱 iOS Version: \(UIDevice.current.systemVersion)")
        
        if #available(iOS 18.0, *) {
            print("✅ iOS 18+ detected")
            #if canImport(AlarmKit)
            print("✅ AlarmKit can be imported")
            // For now, we'll use fallback notifications since AlarmKit API is complex
            isAlarmKitSupported = false
            print("🔔 Using fallback notifications for compatibility")
            #else
            print("❌ AlarmKit cannot be imported")
            isAlarmKitSupported = false
            #endif
        } else {
            print("❌ iOS version too old: \(UIDevice.current.systemVersion)")
            isAlarmKitSupported = false
        }
        print("🔔 Final AlarmKit Support: \(isAlarmKitSupported)")
    }
    
    // MARK: - Authorization
    
    private func checkAuthorizationStatus() {
        // For now, we'll focus on notification permissions
        _Concurrency.Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    // MARK: - Alarm Management
    
    func scheduleAlarm(for task: FocusZone.Task) async -> Bool {
        print("🔔 Attempting to schedule alarm for task: \(task.title)")
        
        guard task.alarmEnabled else {
            print("❌ Alarm not enabled for task: \(task.title)")
            return false
        }
        
        // Check notification permissions first
        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        guard notificationSettings.authorizationStatus == .authorized else {
            print("❌ Notification permissions not granted. Status: \(notificationSettings.authorizationStatus.rawValue)")
            print("💡 Please enable notifications in iOS Settings > FocusZone > Notifications")
            return false
        }
        
        // Use fallback notifications for now
        print("📱 Using fallback notifications for task: \(task.title)")
        scheduleFallbackNotification(for: task)
        return true
    }
    
    func cancelAlarm(for task: FocusZone.Task) async {
        guard task.alarmId != nil else { return }
        
        // Cancel fallback notification
        cancelFallbackNotification(for: task)
        
        // Clear alarm ID from task
        task.alarmId = nil
        task.updatedAt = Date()
    }
    
    func updateAlarm(for task: FocusZone.Task) async -> Bool {
        // Cancel existing alarm and schedule new one
        await cancelAlarm(for: task)
        return await scheduleAlarm(for: task)
    }
    
    // MARK: - Alarm Status
    
    func getAlarmStatus(for task: FocusZone.Task) async -> String? {
        guard task.alarmId != nil else { return nil }
        
        // Check if notification is pending
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let hasNotification = pendingRequests.contains { $0.identifier == "alarm_\(task.id.uuidString)" }
        
        return hasNotification ? "Scheduled" : "Not found"
    }
    
    // MARK: - Fallback Notification Service
    
    func scheduleFallbackNotification(for task: FocusZone.Task) {
        print("📱 Scheduling fallback notification for task: \(task.title)")
        
        let content = UNMutableNotificationContent()
        content.title = "🚀 Time to Focus"
        content.body = "Time to start '\(task.title)' - \(task.durationMinutes) minutes planned"
        content.sound = .default
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "taskAlarm"
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.startTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "alarm_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling fallback notification: \(error)")
            } else {
                let taskTitle = task.title
                let taskStartTime = task.startTime
                print("✅ Fallback notification scheduled for '\(taskTitle)' at \(taskStartTime)")
            }
        }
        
        // Store alarm ID in task
        task.alarmId = "alarm_\(task.id.uuidString)"
        task.updatedAt = Date()
    }
    
    func cancelFallbackNotification(for task: FocusZone.Task) {
        let identifier = "alarm_\(task.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled fallback notification for task: \(task.id.uuidString)")
    }
    
    // MARK: - Alarm Trigger Handling
    
    func handleAlarmTrigger(for task: FocusZone.Task) {
        print("🚨 Alarm triggered for task: \(task.title)")
        
        // Start Live Activity for the task
        let liveActivityManager = LiveActivityManager.shared
        let sessionDuration = TimeInterval(task.durationMinutes * 60)
        
        liveActivityManager.startLiveActivity(
            for: task,
            sessionDuration: sessionDuration,
            breakDuration: nil
        )
        
        // Update task status to in progress
        task.status = .inProgress
        task.actualStartTime = Date()
        task.updatedAt = Date()
        
        print("✅ Task status updated to in progress")
    }
    
    // MARK: - Permission Checking
    
    func checkAllPermissions() async -> (notifications: Bool, alarmKit: Bool, debugInfo: String) {
        var debugInfo = "🔍 Checking all permissions...\n\n"
        
        // Check notification permissions
        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        let notificationsAuthorized = notificationSettings.authorizationStatus == .authorized
        
        debugInfo += "📱 Notification Status: \(notificationSettings.authorizationStatus.rawValue)\n"
        debugInfo += "📱 Alert Setting: \(notificationSettings.alertSetting.rawValue)\n"
        debugInfo += "📱 Sound Setting: \(notificationSettings.soundSetting.rawValue)\n"
        debugInfo += "📱 Badge Setting: \(notificationSettings.badgeSetting.rawValue)\n"
        debugInfo += "---\n"
        
        // Check AlarmKit support and authorization
        debugInfo += "🔔 AlarmKit Support: \(isAlarmKitSupported)\n"
        debugInfo += "🔔 AlarmKit Authorized: \(isAuthorized)\n"
        debugInfo += "🔔 iOS Version: \(UIDevice.current.systemVersion)\n"
        debugInfo += "---\n"
        
        // Check pending notifications
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        debugInfo += "📋 Pending Notifications: \(pendingRequests.count)\n"
        for request in pendingRequests {
            debugInfo += "  - ID: \(request.identifier)\n"
            debugInfo += "    Title: \(request.content.title)\n"
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                debugInfo += "    Trigger: \(trigger.dateComponents)\n"
            }
        }
        debugInfo += "---\n"
        
        return (notificationsAuthorized, isAuthorized, debugInfo)
    }
    
    func requestAllPermissions() async -> (notifications: Bool, alarmKit: Bool) {
        // Request notification permission
        do {
            let notificationGranted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            
            // For now, AlarmKit is not used
            let alarmKitGranted = false
            
            return (notificationGranted, alarmKitGranted)
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return (false, false)
        }
    }
    
    // MARK: - Debug Methods
    
    func debugAlarmKitSupport() -> String {
        var debugInfo = "🔍 AlarmKit Debug Information:\n\n"
        
        debugInfo += "📱 iOS Version: \(UIDevice.current.systemVersion)\n"
        debugInfo += "📱 Device Model: \(UIDevice.current.model)\n"
        debugInfo += "📱 Device Name: \(UIDevice.current.name)\n\n"
        
        debugInfo += "🔔 iOS 18+ Check: \(iOS18OrLater ? "✅ Yes" : "❌ No")\n"
        
        #if canImport(AlarmKit)
        debugInfo += "🔔 AlarmKit Import: ✅ Available\n"
        debugInfo += "🔔 Using Fallback Notifications: ✅ Yes (for compatibility)\n"
        #else
        debugInfo += "🔔 AlarmKit Import: ❌ Not Available\n"
        #endif
        
        debugInfo += "🔔 Final Support Status: \(isAlarmKitSupported ? "✅ Supported" : "❌ Not Supported")\n"
        debugInfo += "🔔 Authorization Status: \(isAuthorized ? "✅ Authorized" : "❌ Not Authorized")\n"
        
        return debugInfo
    }
    
    private var iOS18OrLater: Bool {
        if #available(iOS 18.0, *) {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Debug Methods
    
    func getAllScheduledAlarms() async -> [String] {
        let pendingRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pendingRequests.map { "\($0.identifier): \($0.content.title)" }
    }
    
    func printAlarmStatus() async {
        let alarms = await getAllScheduledAlarms()
        print("Scheduled alarms: \(alarms.count)")
        for alarm in alarms {
            print("- \(alarm)")
            print("---")
        }
        
        // Also print pending notifications
        printPendingNotifications()
    }
    
    func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📱 Pending notifications: \(requests.count)")
            for request in requests {
                print("- ID: \(request.identifier)")
                print("  Title: \(request.content.title)")
                print("  Body: \(request.content.body)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("  Trigger: \(trigger.dateComponents)")
                }
                print("---")
            }
        }
    }
}