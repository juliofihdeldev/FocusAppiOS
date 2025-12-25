import Foundation
import UserNotifications
import SwiftData
import SwiftUI

class AlarmNotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AlarmNotificationHandler()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle alarm notifications
        if let type = userInfo["type"] as? String, type == "taskAlarm",
           let taskIdString = userInfo["taskId"] as? String,
           let taskId = UUID(uuidString: taskIdString) {
            
            handleAlarmNotification(for: taskId)
        }
        
        // Handle scheduled task start notifications
        if let type = userInfo["type"] as? String, type == "scheduledTaskStart",
           let taskIdString = userInfo["taskId"] as? String,
           let taskId = UUID(uuidString: taskIdString) {
            
            _Concurrency.Task { @MainActor in
                ScheduledTaskLiveActivityService.shared.handleTaskStartNotification(taskId: taskId)
            }
        }
        
        // Handle scheduled task end notifications
        if let type = userInfo["type"] as? String, type == "scheduledTaskEnd",
           let taskIdString = userInfo["taskId"] as? String,
           let taskId = UUID(uuidString: taskIdString) {
            
            _Concurrency.Task { @MainActor in
                ScheduledTaskLiveActivityService.shared.handleTaskEndNotification(taskId: taskId)
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        // Handle scheduled task start notifications when app is in foreground
        if let type = userInfo["type"] as? String, type == "scheduledTaskStart",
           let taskIdString = userInfo["taskId"] as? String,
           let taskId = UUID(uuidString: taskIdString) {
            
            _Concurrency.Task { @MainActor in
                ScheduledTaskLiveActivityService.shared.handleTaskStartNotification(taskId: taskId)
            }
        }
        
        // Handle scheduled task end notifications when app is in foreground
        if let type = userInfo["type"] as? String, type == "scheduledTaskEnd",
           let taskIdString = userInfo["taskId"] as? String,
           let taskId = UUID(uuidString: taskIdString) {
            
            _Concurrency.Task { @MainActor in
                ScheduledTaskLiveActivityService.shared.handleTaskEndNotification(taskId: taskId)
            }
        }
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - Alarm Handling
    
    private func handleAlarmNotification(for taskId: UUID) {
        _Concurrency.Task { @MainActor in
            // For now, just trigger the alarm service
            // The actual task lookup will be handled by the service
            print("🚨 Alarm notification received for task ID: \(taskId)")
            
            // We'll need to get the task from the main app context
            // For now, just log the notification
        }
    }
}
