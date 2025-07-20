import UserNotifications
import SwiftUI
import SwiftData

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [
                .alert, .sound, .badge
            ])
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Task Reminders
    
    func scheduleTaskReminders(for task: Task) {
        guard isAuthorized else {
            print("Notifications not authorized")
            return
        }
        
        let taskId = task.id.uuidString
        
        // Clear existing notifications for this task
        cancelNotifications(for: taskId)
        
        // Schedule 5 minutes before
        scheduleFiveMinuteReminder(for: task)
        
        // Schedule at start time
        scheduleStartReminder(for: task)
    }
    
    private func scheduleFiveMinuteReminder(for task: Task) {
        let reminderTime = task.startTime.addingTimeInterval(-300) // 5 minutes before
        
        // Don't schedule if time is in the past
        guard reminderTime > Date() else {
            print("5-minute reminder time is in the past for task: \(task.title)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "📝 Upcoming Task"
        content.body = "'\(task.title)' starts in 5 minutes. Get ready!"
        content.sound = .default
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "fiveMinuteBefore"
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "fiveMin_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling 5-minute reminder: \(error)")
            } else {
                print("Scheduled 5-minute reminder for '\(task.title)' at \(reminderTime)")
            }
        }
    }
    
    private func scheduleStartReminder(for task: Task) {
        guard task.startTime > Date() else {
            print("Start time is in the past for task: \(task.title)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🚀 Time to Focus"
        content.body = "Time to start '\(task.title)' - \(task.durationMinutes) minutes planned"
        content.sound = .default
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "taskStart"
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.startTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "start_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling start reminder: \(error)")
            } else {
                print("Scheduled start reminder for '\(task.title)' at \(task.startTime)")
            }
        }
    }
    
    // MARK: - Task Completion Notification
    
    func sendTaskCompletionNotification(for task: Task, actualDuration: Int) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "✅ Great job!"
        content.body = "You completed '\(task.title)' in \(actualDuration) minutes"
        content.sound = .default
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "taskCompletion"
        ]
        
        let request = UNNotificationRequest(
            identifier: "completion_\(task.id.uuidString)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate notification
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending completion notification: \(error)")
            } else {
                print("Sent completion notification for '\(task.title)'")
            }
        }
    }
    
    // MARK: - Break Reminders
    
    func scheduleBreakReminder(after task: Task) {
        guard isAuthorized else { return }
        
        // Schedule break reminder for 2 minutes after task completion
        let breakTime = Date().addingTimeInterval(120) // 2 minutes from now
        
        let content = UNMutableNotificationContent()
        content.title = "🌱 Break Time"
        content.body = "Time for a 5-minute break before your next task"
        content.sound = .default
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "breakReminder"
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: breakTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "break_\(task.id.uuidString)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling break reminder: \(error)")
            } else {
                print("Scheduled break reminder for \(breakTime)")
            }
        }
    }
    
    // MARK: - Daily Planning Reminder
    
    func scheduleDailyPlanningReminder(at time: Date, taskCount: Int) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🌅 Good morning!"
        
        if taskCount > 0 {
            content.body = "Plan your day - \(taskCount) tasks scheduled for today"
        } else {
            content.body = "Plan your day and add some tasks to stay focused"
        }
        
        content.sound = .default
        content.userInfo = [
            "type": "dailyPlanning",
            "taskCount": taskCount
        ]
        
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_planning",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily planning reminder: \(error)")
            } else {
                print("Scheduled daily planning reminder at \(time)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func cancelNotifications(for taskId: String) {
        let identifiers = [
            "fiveMin_\(taskId)",
            "start_\(taskId)"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Cancelled notifications for task: \(taskId)")
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Cancelled all notifications")
    }
    
    // MARK: - Immediate Notifications
    
    func sendImmediateNotification(title: String, body: String) {
        guard isAuthorized else {
            print("Cannot send immediate notification - not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [
            "type": "immediate"
        ]
        
        let request = UNNotificationRequest(
            identifier: "immediate_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate notification
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending immediate notification: \(error)")
            } else {
                print("Sent immediate notification: \(title)")
            }
        }
    }
    
    // MARK: - Debug Methods
    
    func getPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("Pending notifications: \(requests.count)")
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
