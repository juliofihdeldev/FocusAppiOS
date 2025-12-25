import Foundation
import SwiftData
import ActivityKit
import UserNotifications
import UIKit

/// Service that automatically starts Live Activities for scheduled tasks when they reach their start time
@MainActor
class ScheduledTaskLiveActivityService: ObservableObject {
    static let shared = ScheduledTaskLiveActivityService()
    
    private var modelContext: ModelContext?
    private var checkTimer: Timer?
    private var activeLiveActivityTaskIds: Set<UUID> = []
    private let liveActivityManager = LiveActivityManager.shared
    
    private init() {
        setupNotificationHandling()
    }
    
    // MARK: - Setup
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func setupNotificationHandling() {
        // Handle notification when app is in background/foreground
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.handleAppBecameActive()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.handleAppWillResignActive()
            }
        }
    }
    
    private func handleAppBecameActive() {
        print("📱 ScheduledTaskLiveActivityService: App became active, checking scheduled tasks")
        checkScheduledTasks()
        startPeriodicCheck()
    }
    
    private func handleAppWillResignActive() {
        print("📱 ScheduledTaskLiveActivityService: App will resign active, stopping periodic check")
        stopPeriodicCheck()
    }
    
    // MARK: - Task Monitoring
    
    /// Start monitoring scheduled tasks
    func startMonitoring() {
        print("🚀 ScheduledTaskLiveActivityService: Starting monitoring")
        checkScheduledTasks()
        startPeriodicCheck()
        scheduleBackgroundNotifications()
    }
    
    /// Stop monitoring scheduled tasks
    func stopMonitoring() {
        print("🛑 ScheduledTaskLiveActivityService: Stopping monitoring")
        stopPeriodicCheck()
    }
    
    /// Check for scheduled tasks that should start Live Activities
    func checkScheduledTasks() {
        guard let modelContext = modelContext else {
            print("⚠️ ScheduledTaskLiveActivityService: No model context available")
            return
        }
        
        let now = Date()
        let scheduledStatusRawValue = TaskStatus.scheduled.rawValue
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.statusRawValue == scheduledStatusRawValue &&
                task.startTime <= now &&
                !task.isCompleted
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        do {
            let tasksToStart = try modelContext.fetch(descriptor)
            print("📋 ScheduledTaskLiveActivityService: Found \(tasksToStart.count) tasks that should be active")
            
            for task in tasksToStart {
                // Calculate end time to verify task is still within its window
                let endTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
                
                // Only start if task is within its time window
                guard now >= task.startTime && now <= endTime else {
                    continue
                }
                
                // Check if Live Activity already exists for this task
                if !activeLiveActivityTaskIds.contains(task.id) {
                    startLiveActivityForTask(task)
                } else {
                    print("⏭️ ScheduledTaskLiveActivityService: Live Activity already exists for task: \(task.title)")
                }
            }
            
            // Check for tasks that should end
            checkTasksToEnd()
            
        } catch {
            print("❌ ScheduledTaskLiveActivityService: Error fetching tasks: \(error)")
        }
    }
    
    /// Check for tasks that should end their Live Activities
    private func checkTasksToEnd() {
        guard let modelContext = modelContext else { return }
        
        let now = Date()
        // We need to check tasks manually since we can't use computed properties in predicates
        let completedStatusRawValue = TaskStatus.completed.rawValue
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.isCompleted || task.statusRawValue == completedStatusRawValue
            }
        )
        
        do {
            let tasksToEnd = try modelContext.fetch(descriptor)
            
            for task in tasksToEnd {
                if activeLiveActivityTaskIds.contains(task.id) {
                    endLiveActivityForTask(task)
                }
            }
            
            // Also check tasks that have passed their end time
            let allTasksDescriptor = FetchDescriptor<Task>()
            let allActiveTasks = try modelContext.fetch(allTasksDescriptor)
            for task in allActiveTasks {
                if activeLiveActivityTaskIds.contains(task.id) {
                    let endTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
                    if now > endTime {
                        endLiveActivityForTask(task)
                    }
                }
            }
        } catch {
            print("❌ ScheduledTaskLiveActivityService: Error checking tasks to end: \(error)")
        }
    }
    
    // MARK: - Live Activity Management
    
    /// Start Live Activity for a scheduled task
    private func startLiveActivityForTask(_ task: Task) {
        guard liveActivityManager.isLiveActivitySupported else {
            print("⚠️ ScheduledTaskLiveActivityService: Live Activities not supported")
            return
        }
        
        // Check if task is still within its time window
        let now = Date()
        let endTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        guard now >= task.startTime && now <= endTime else {
            print("⏭️ ScheduledTaskLiveActivityService: Task \(task.title) is outside its time window")
            return
        }
        
        // Calculate remaining time
        let remainingSeconds = max(0, endTime.timeIntervalSince(now))
        
        guard remainingSeconds > 0 else {
            print("⏭️ ScheduledTaskLiveActivityService: Task \(task.title) has no remaining time")
            return
        }
        
        // Calculate progress (how much time has passed)
        let totalDuration = TimeInterval(task.durationMinutes * 60)
        let elapsedTime = totalDuration - remainingSeconds
        let progress = min(1.0, max(0.0, elapsedTime / totalDuration))
        
        print("🎯 ScheduledTaskLiveActivityService: Starting Live Activity for task: \(task.title)")
        print("🎯 - Start time: \(task.startTime)")
        print("🎯 - End time: \(endTime)")
        print("🎯 - Remaining: \(remainingSeconds) seconds")
        print("🎯 - Progress: \(Int(progress * 100))%")
        
        // Update task status to inProgress if it hasn't been started manually
        if task.status == .scheduled {
            task.status = .inProgress
            if task.actualStartTime == nil {
                task.actualStartTime = task.startTime
            }
            try? modelContext?.save()
        }
        
        // Start Live Activity using the existing LiveActivityManager
        liveActivityManager.startLiveActivity(
            for: task,
            sessionDuration: remainingSeconds,
            breakDuration: nil
        )
        
        // Track this task's Live Activity
        activeLiveActivityTaskIds.insert(task.id)
        
        // Schedule end notification
        scheduleEndNotification(for: task, at: endTime)
    }
    
    /// End Live Activity for a task
    private func endLiveActivityForTask(_ task: Task) {
        guard activeLiveActivityTaskIds.contains(task.id) else {
            return
        }
        
        print("🏁 ScheduledTaskLiveActivityService: Ending Live Activity for task: \(task.title)")
        
        // Only end if this is the current activity
        if let currentActivity = liveActivityManager.currentActivity,
           currentActivity.attributes.taskId == task.id.uuidString {
            liveActivityManager.endCurrentActivity()
        }
        
        activeLiveActivityTaskIds.remove(task.id)
    }
    
    // MARK: - Periodic Checking
    
    private func startPeriodicCheck() {
        stopPeriodicCheck()
        
        // Check every 30 seconds when app is active
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.checkScheduledTasks()
            }
        }
        
        // Also check every minute for tasks that should end
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.checkTasksToEnd()
            }
        }
    }
    
    private func stopPeriodicCheck() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    // MARK: - Background Notifications
    
    /// Schedule background notifications for task start times
    private func scheduleBackgroundNotifications() {
        guard let modelContext = modelContext else { return }
        
        // Request notification permission if needed
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ ScheduledTaskLiveActivityService: Notification permission error: \(error)")
                return
            }
            
            if granted {
                print("✅ ScheduledTaskLiveActivityService: Notification permission granted")
            }
        }
        
        let now = Date()
        let scheduledStatusRawValue = TaskStatus.scheduled.rawValue
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.statusRawValue == scheduledStatusRawValue &&
                task.startTime > now &&
                !task.isCompleted
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        do {
            let upcomingTasks = try modelContext.fetch(descriptor)
            print("📅 ScheduledTaskLiveActivityService: Scheduling notifications for \(upcomingTasks.count) upcoming tasks")
            
            for task in upcomingTasks {
                scheduleTaskStartNotification(for: task)
            }
        } catch {
            print("❌ ScheduledTaskLiveActivityService: Error fetching upcoming tasks: \(error)")
        }
    }
    
    /// Schedule a notification to trigger Live Activity check when task starts
    private func scheduleTaskStartNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "🚀 Time to Focus"
        content.body = "Starting '\(task.title)'"
        content.sound = .default
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "scheduledTaskStart",
            "action": "startLiveActivity"
        ]
        
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: task.startTime
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "scheduled_task_start_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ ScheduledTaskLiveActivityService: Error scheduling notification: \(error)")
            } else {
                print("✅ ScheduledTaskLiveActivityService: Scheduled notification for task '\(task.title)' at \(task.startTime)")
            }
        }
    }
    
    /// Schedule a notification when task should end
    private func scheduleEndNotification(for task: Task, at endTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "✅ Task Complete"
        content.body = "'\(task.title)' has finished"
        content.sound = .default
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "scheduledTaskEnd",
            "action": "endLiveActivity"
        ]
        
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: endTime
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "scheduled_task_end_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ ScheduledTaskLiveActivityService: Error scheduling end notification: \(error)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Handle notification that indicates a task should start
    func handleTaskStartNotification(taskId: UUID) {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.id == taskId
            }
        )
        
        do {
            if let task = try modelContext.fetch(descriptor).first {
                print("📬 ScheduledTaskLiveActivityService: Received start notification for task: \(task.title)")
                checkScheduledTasks() // This will start the Live Activity if needed
            }
        } catch {
            print("❌ ScheduledTaskLiveActivityService: Error fetching task from notification: \(error)")
        }
    }
    
    /// Handle notification that indicates a task should end
    func handleTaskEndNotification(taskId: UUID) {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.id == taskId
            }
        )
        
        do {
            if let task = try modelContext.fetch(descriptor).first {
                print("📬 ScheduledTaskLiveActivityService: Received end notification for task: \(task.title)")
                endLiveActivityForTask(task)
            }
        } catch {
            print("❌ ScheduledTaskLiveActivityService: Error fetching task from notification: \(error)")
        }
    }
    
    /// Manually register a task's Live Activity (called when user manually starts a task)
    func registerActiveLiveActivity(taskId: UUID) {
        activeLiveActivityTaskIds.insert(taskId)
    }
    
    /// Manually unregister a task's Live Activity (called when user manually ends a task)
    func unregisterActiveLiveActivity(taskId: UUID) {
        activeLiveActivityTaskIds.remove(taskId)
    }
    
    /// Check if a task has an active Live Activity
    func hasActiveLiveActivity(taskId: UUID) -> Bool {
        return activeLiveActivityTaskIds.contains(taskId)
    }
}

