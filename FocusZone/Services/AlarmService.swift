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
            isAlarmKitSupported = AlarmKit.AlarmManager.isSupported
            print("🔔 AlarmManager.isSupported: \(AlarmKit.AlarmManager.isSupported)")
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
        if #available(iOS 18.0, *) {
            #if canImport(AlarmKit)
            Task {
                let status = await AlarmManager.authorizationStatus
                await MainActor.run {
                    self.isAuthorized = status == .authorized
                }
            }
            #endif
        }
    }
    
    func requestAuthorization() async -> Bool {
        guard #available(iOS 18.0, *) else {
            print("AlarmKit requires iOS 18.0 or later")
            return false
        }
        
        #if canImport(AlarmKit)
        do {
            let granted = try await AlarmManager.requestAuthorization()
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("AlarmKit authorization error: \(error)")
            return false
        }
        #else
        print("AlarmKit not available")
        return false
        #endif
    }
    
    // MARK: - Alarm Management
    
    func scheduleAlarm(for task: Task) async -> Bool {
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
        
        guard #available(iOS 18.0, *), isAlarmKitSupported, isAuthorized else {
            print("📱 AlarmKit not available or not authorized, using fallback notifications")
            scheduleFallbackNotification(for: task)
            return true
        }
        
        #if canImport(AlarmKit)
        // Cancel existing alarm if any
        if let existingAlarmId = task.alarmId {
            await cancelAlarm(alarmId: existingAlarmId)
        }
        
        do {
            // Create alarm content
            let alarmContent = AlarmContent(
                title: "🚀 Time to Focus",
                body: "Time to start '\(task.title)' - \(task.durationMinutes) minutes planned",
                sound: .default
            )
            
            // Create alarm request
            let alarmRequest = AlarmRequest(
                content: alarmContent,
                trigger: .date(task.startTime)
            )
            
            // Schedule the alarm
            let alarm = try await AlarmManager.schedule(alarmRequest)
            
            // Store alarm ID in task
            task.alarmId = alarm.id.uuidString
            task.updatedAt = Date()
            
            print("✅ Alarm scheduled successfully for task: \(task.title)")
            print("✅ Alarm ID: \(alarm.id)")
            print("✅ Alarm time: \(task.startTime)")
            
            return true
            
        } catch {
            print("❌ Failed to schedule alarm: \(error)")
            scheduleFallbackNotification(for: task)
            return false
        }
        #else
        scheduleFallbackNotification(for: task)
        return false
        #endif
    }
    
    func cancelAlarm(for task: Task) async {
        guard let alarmId = task.alarmId else { return }
        
        await cancelAlarm(alarmId: alarmId)
        
        // Clear alarm ID from task
        task.alarmId = nil
        task.updatedAt = Date()
    }
    
    private func cancelAlarm(alarmId: String) async {
        guard #available(iOS 18.0, *), isAlarmKitSupported else { return }
        
        #if canImport(AlarmKit)
        guard let uuid = UUID(uuidString: alarmId) else {
            print("Invalid alarm ID: \(alarmId)")
            return
        }
        
        do {
            try await AlarmManager.cancel(alarmId: uuid)
            print("✅ Alarm cancelled: \(alarmId)")
        } catch {
            print("❌ Failed to cancel alarm: \(error)")
        }
        #endif
    }
    
    func updateAlarm(for task: Task) async -> Bool {
        // Cancel existing alarm and schedule new one
        await cancelAlarm(for: task)
        return await scheduleAlarm(for: task)
    }
    
    // MARK: - Alarm Status
    
    func getAlarmStatus(for task: Task) async -> String? {
        guard #available(iOS 18.0, *), isAlarmKitSupported, isAuthorized else { return nil }
        guard let alarmId = task.alarmId, let uuid = UUID(uuidString: alarmId) else { return nil }
        
        #if canImport(AlarmKit)
        do {
            let alarms = try await AlarmManager.alarms
            return alarms.first { $0.id == uuid }?.status.description
        } catch {
            print("Error getting alarm status: \(error)")
            return nil
        }
        #else
        return nil
        #endif
    }
    
    // MARK: - Fallback Notification Service
    
    func scheduleFallbackNotification(for task: Task) {
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
                print("✅ Fallback notification scheduled for '\(task.title)' at \(task.startTime)")
            }
        }
    }
    
    func cancelFallbackNotification(for task: Task) {
        let identifier = "alarm_\(task.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled fallback notification for task: \(task.id.uuidString)")
    }
    
    // MARK: - Alarm Trigger Handling
    
    func handleAlarmTrigger(for task: Task) {
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
        
        // Save the updated task
        do {
            let context = ModelContext(try ModelContainer(for: Task.self))
            context.insert(task)
            try context.save()
            print("✅ Task status updated to in progress")
        } catch {
            print("❌ Error updating task status: \(error)")
        }
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
            
            // Request AlarmKit permission
            let alarmKitGranted = await requestAuthorization()
            
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
        if iOS18OrLater {
            debugInfo += "🔔 AlarmManager.isSupported: \(AlarmKit.AlarmManager.isSupported ? "✅ Yes" : "❌ No")\n"
        }
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
        guard #available(iOS 18.0, *), isAlarmKitSupported, isAuthorized else { return [] }
        
        #if canImport(AlarmKit)
        do {
            let alarms = try await AlarmManager.alarms
            return alarms.map { "\($0.id): \($0.content.title)" }
        } catch {
            print("Error getting scheduled alarms: \(error)")
            return []
        }
        #else
        return []
        #endif
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
