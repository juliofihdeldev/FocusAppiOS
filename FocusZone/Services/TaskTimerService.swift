import SwiftUI
import Combine
import SwiftData
import EventKit

class TaskTimerService: ObservableObject {
    static let shared = TaskTimerService()
    
    @Published var currentTask: Task?
    @Published var elapsedSeconds: Int = 0
    
    private var timer: Timer?
    private var startTime: Date?
    private var modelContext: ModelContext?
    
    @MainActor private let focusManager = FocusModeManager()
    
    private init() {
        // Initialize any required properties here
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // Start a task with smart time calculation
    @MainActor func startTask(_ task: Task, reset: Bool = false) {
        stopCurrentTask()
        
        // Smart time calculation: choose between previously spent time or schedule-based elapsed time
        let timeAlreadySpent = reset ? 0 : calculateSmartElapsedTime(for: task)
        let startingElapsedSeconds = timeAlreadySpent * 60
        
        // Update task status
        task.status = .inProgress
        task.actualStartTime = Date()
        if reset {
        }
        saveContext()
        
        // Set up timer service state
        currentTask = task
        
        // Set startTime to account for already spent time
        startTime = Date().addingTimeInterval(-TimeInterval(startingElapsedSeconds))
        
        elapsedSeconds = startingElapsedSeconds
        
        print("TaskTimerService: Starting task '\(task.title)' with \(timeAlreadySpent)m already elapsed")
        print("TaskTimerService: Starting timer at \(startingElapsedSeconds) seconds")
        
        // Calculate remaining time for the task
        let remainingMinutes = task.durationMinutes - timeAlreadySpent
        let remainingSeconds = TimeInterval(remainingMinutes * 60)
        
        // Start Live Activity immediately for any task start
        print("🎯 TaskTimerService: About to start Live Activity for task: \(task.title)")
        print("🎯 TaskTimerService: Remaining seconds: \(remainingSeconds)")
        LiveActivityManager.shared.startLiveActivity(
            for: task,
            sessionDuration: remainingSeconds,
            breakDuration: nil
        )
        // Register with scheduled task service to prevent duplicates
        ScheduledTaskLiveActivityService.shared.registerActiveLiveActivity(taskId: task.id)
        print("🎯 TaskTimerService: Live Activity start call completed")
        
        // Create calendar event if sync is enabled
        if CalendarSyncService.shared.syncEnabled && task.calendarEventId == nil {
            task.calendarEventId = CalendarSyncService.shared.createCalendarEvent(from: task)
            saveContext()
        }
        
        // Also start focus session if needed
        _Concurrency.Task {
            await focusManager.setupCustomNotificationFiltering(for: FocusMode.deepWork)
            _ = await focusManager.activateFocus(mode: FocusMode.deepWork, duration: remainingSeconds, task: task)
        }
        // If we've already reached or exceeded planned time, complete immediately
        let maxAllowedSeconds = (task.durationMinutes) * 60
        if elapsedSeconds >= maxAllowedSeconds {
            handleTimerCompletion()
            return
        }

        startTimer()
    }
    
    // Calculate smart elapsed time: previously spent time OR schedule-based time
    public func calculateSmartElapsedTime(for task: Task) -> Int {
        return  task.durationMinutes - _minutesRemain (for: task)
    }
    
    public func _minutesRemain(for task: Task) -> Int {
        let now = Date()
        let taskStartTime = task.startTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        
        // If task is currently active
        if now >= taskStartTime && now <= taskEndTime {
            let remaining = taskEndTime.timeIntervalSince(now)
            let remainingMinutes = Int(remaining / 60)
            
            if remainingMinutes > 60 {
                return remainingMinutes
            } else if remainingMinutes > 0 {
                return remainingMinutes
            } else {
                // Less than a minute remaining
                let remainingSeconds = Int(remaining)
                return remainingSeconds / 60
            }
            
        }
        return 0
    }
    
    // Pause the current task
    @MainActor func pauseTask() {
        guard let task = currentTask else { return }
        
        stopTimer()
        
        // Calculate total time spent including current session
        let _ = elapsedSeconds / 60
        task.status = .paused
        task.updatedAt = Date()
        saveContext()
        
        // Update Live Activity to show paused state
        let (progress, remainingSeconds) = calculateSessionProgress()
        
        _Concurrency.Task { @MainActor in
            LiveActivityManager.shared.updateLiveActivity(
                timeRemaining: TimeInterval(remainingSeconds),
                progress: progress,
                currentPhase: FocusPhase.paused,
                isActive: false
            )
        }
    }
    
    // Resume a paused task
    @MainActor func resumeTask() {
        guard let task = currentTask, task.isPaused else { return }
        
        task.status = .inProgress
        task.updatedAt = Date()
        saveContext()
        
        // Use the actual time spent stored in the task (this takes priority)
        let timeAlreadySpent = _minutesRemain(for: task)
        startTime = Date().addingTimeInterval(-TimeInterval(timeAlreadySpent * 60))
        
        elapsedSeconds = timeAlreadySpent * 60
        
        // Update Live Activity to show active state
        let (progress, remainingSeconds) = calculateSessionProgress()
        
        _Concurrency.Task { @MainActor in
            LiveActivityManager.shared.updateLiveActivity(
                timeRemaining: TimeInterval(remainingSeconds),
                progress: progress,
                currentPhase: FocusPhase.focus,
                isActive: true
            )
        }
        
        startTimer()
    }
    
    // Complete the current task
    @MainActor func completeTask() {
        guard let task = currentTask else { return }
        
        stopTimer()
        
        let totalTimeSpent = elapsedSeconds / 60
        task.isCompleted = true
        task.status = .completed
        task.updatedAt = Date()
        
        print("TaskTimerService: Completed task with \(totalTimeSpent)m total time")
        
        // Update calendar event if sync is enabled
        if CalendarSyncService.shared.syncEnabled, let eventId = task.calendarEventId {
            CalendarSyncService.shared.updateCalendarEvent(eventId: eventId, from: task)
        }
        
        saveContext()
        
        // Update Live Activity to show completed state
        _Concurrency.Task { @MainActor in
            LiveActivityManager.shared.updateLiveActivity(
                timeRemaining: 0,
                progress: 1.0,
                currentPhase: FocusPhase.completed,
                isActive: false
            )
        }
        
        // End Live Activity after showing completion
        _Concurrency.Task { @MainActor in
            LiveActivityManager.shared.endCurrentActivity()
            // Unregister from scheduled task service
            if let task = self.currentTask {
                ScheduledTaskLiveActivityService.shared.unregisterActiveLiveActivity(taskId: task.id)
            }
        }
        
        // Clear after a brief delay to show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentTask = nil
            self.elapsedSeconds = 0
        }
    }
    
    // Stop the current task
    @MainActor func stopCurrentTask() {
        stopTimer()
        
        // Save current progress before stopping
        if let task = currentTask {
            let totalTimeSpent = elapsedSeconds / 60
            task.status = .scheduled
            task.updatedAt = Date()
            
            // Update calendar event if sync is enabled
            if CalendarSyncService.shared.syncEnabled, let eventId = task.calendarEventId {
                CalendarSyncService.shared.updateCalendarEvent(eventId: eventId, from: task)
            }
            
            saveContext()
            
            print("TaskTimerService: Stopped task with \(totalTimeSpent)m total time")
        }
        
            // Close Live Activity when stopping task
        LiveActivityManager.shared.endCurrentActivity()
        
        // Unregister from scheduled task service
        if let task = currentTask {
            ScheduledTaskLiveActivityService.shared.unregisterActiveLiveActivity(taskId: task.id)
        }
        
        _Concurrency.Task {
            await focusManager.deactivateFocus()
        }
        currentTask = nil
        elapsedSeconds = 0
        startTime = nil
    }
    
    // Private timer methods
    private func startTimer() {
        var lastUpdateTime = Date()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                guard let task = self.currentTask else { return }

                let maxAllowedSeconds = (task.durationMinutes) * 60

                // Increment until cap
                if self.elapsedSeconds < maxAllowedSeconds {
                    self.elapsedSeconds += 1
                    
                    // Update Live Activity only every 5 seconds to improve performance
                    let currentTime = Date()
                    if currentTime.timeIntervalSince(lastUpdateTime) >= 5.0 {
                        self.updateLiveActivityProgress()
                        lastUpdateTime = currentTime
                    }
                }

                // Auto-complete exactly at cap and stop counting beyond
                if self.elapsedSeconds >= maxAllowedSeconds {
                    self.elapsedSeconds = maxAllowedSeconds
                    // Always update Live Activity on completion
                    self.updateLiveActivityProgress()
                    // Prevent further ticks from changing state
                    self.handleTimerCompletion()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Live Activity Updates
    
    private func calculateSessionProgress() -> (progress: Double, remainingSeconds: Int) {
        guard let task = currentTask else { return (0.0, 0) }
        
        // Calculate progress based on total task duration
        let totalTaskSeconds = task.durationMinutes * 60
        let remainingSeconds = max(0, totalTaskSeconds - elapsedSeconds)
        let progress = min(1.0, Double(elapsedSeconds) / Double(totalTaskSeconds))
        
        print("🎯 Progress Calculation Debug:")
        print("   - Total Task Seconds: \(totalTaskSeconds)")
        print("   - Elapsed Seconds: \(elapsedSeconds)")
        print("   - Remaining Seconds: \(remainingSeconds)")
        print("   - Progress: \(progress) (\(Int(progress * 100))%)")
        
        return (progress, remainingSeconds)
    }
    
    private func updateLiveActivityProgress() {
        guard let task = currentTask else { return }
        
        let (progress, remainingSeconds) = calculateSessionProgress()
        
        print("🎯 TaskTimerService: Updating Live Activity progress")
        print("   - Task: \(task.title)")
        print("   - Progress: \(Int(progress * 100))%")
        print("   - Remaining: \(remainingSeconds)s")
        print("   - Total Elapsed: \(elapsedSeconds)s")
        
        // Update Live Activity with current progress
        _Concurrency.Task { @MainActor in
            LiveActivityManager.shared.updateLiveActivity(
                timeRemaining: TimeInterval(remainingSeconds),
                progress: progress,
                currentPhase: FocusPhase.focus,
                isActive: true
            )
        }
    }
    
    // Handle automatic timer completion
    @MainActor private func handleTimerCompletion() {
        guard let task = currentTask else { return }
        
        stopTimer()
        
        // Mark task as completed automatically
        task.isCompleted = true
        task.status = .completed
        task.updatedAt = Date()
        saveContext()
        
        print("TaskTimerService: Auto-completed task '\(task.title)' after \(task.durationMinutes) minutes")
        
        // Close Live Activity when timer completes
        LiveActivityManager.shared.endCurrentActivity()
        
        // Clear after a brief delay to show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentTask = nil
            self.elapsedSeconds = 0
        }
    }
    
    // MARK: - Computed Properties
    
    var currentElapsedMinutes: Int {
        elapsedSeconds / 60
    }
    
    var currentRemainingMinutes: Int {
        guard let task = currentTask else { return 0 }
        let remainingSeconds = max(0, (task.durationMinutes * 60) - elapsedSeconds)
        return remainingSeconds / 60
    }
    
    var currentRemainingSeconds: Int {
        guard let task = currentTask else { return 0 }
        let remainingTotalSeconds = max(0, (task.durationMinutes * 60) - elapsedSeconds)
        return remainingTotalSeconds % 60
    }
    
    var currentProgressPercentage: Double {
        guard let task = currentTask, task.durationMinutes > 0 else { return 0 }
        return min(1.0, Double(elapsedSeconds) / Double(task.durationMinutes * 60))
    }
    
    var isOvertime: Bool {
        guard let task = currentTask else { return false }
        return elapsedSeconds > (task.durationMinutes * 60)
    }
    
    var formattedElapsedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedRemainingTime: String {
        guard let task = currentTask else { return "00:00" }
        
        let totalRemainingSeconds = max(0, (task.durationMinutes * 60) - elapsedSeconds)
        let minutes = totalRemainingSeconds / 60
        let seconds = totalRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Additional computed properties for better timer control
    var isTimerRunning: Bool {
        return timer != nil && currentTask?.isActive == true
    }
    
    var shouldShowOvertime: Bool {
        return isOvertime && currentTask?.isActive == true
    }
    
    // Get formatted time remaining with units
    var timeRemainingWithUnits: String {
        guard let task = currentTask else { return "No active task" }
        
        if isOvertime {
            let overtimeSeconds = elapsedSeconds - (task.durationMinutes * 60)
            let overtimeMinutes = overtimeSeconds / 60
            let seconds = overtimeSeconds % 60
            
            if overtimeMinutes > 0 {
                return "\(overtimeMinutes)m \(seconds)s overtime"
            } else {
                return "\(seconds)s overtime"
            }
        } else {
            let remainingTotalSeconds = (task.durationMinutes * 60) - elapsedSeconds
            let minutes = remainingTotalSeconds / 60
            let seconds = remainingTotalSeconds % 60
            
            if minutes > 0 {
                return "\(minutes)m \(seconds)s remaining"
            } else if seconds > 0 {
                return "\(seconds)s remaining"
            } else {
                return "Time's up!"
            }
        }
    }
    
    // Get progress information for UI
    var progressInfo: (percentage: Double, color: Color, isOvertime: Bool) {
        guard currentTask != nil else {
            return (0.0, .gray, false)
        }
        
        let percentage = currentProgressPercentage
        let overtime = isOvertime
        
        let color: Color
        if overtime {
            color = .red
        } else if percentage < 0.5 {
            color = .green
        } else if percentage < 0.8 {
            color = .orange
        } else {
            color = .red
        }
        
        return (min(1.0, percentage), color, overtime)
    }
    
    // MARK: - Private Methods
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
            print("TaskTimerService: Context saved successfully")
        } catch {
            print("TaskTimerService: Error saving context: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    // Check if a task can be resumed
    func canResumeTask(_ task: Task) -> Bool {
        return _minutesRemain(for: task) > 0 && _minutesRemain(for: task)  < task.durationMinutes && !task.isCompleted
    }
    
    // Get time spent vs planned for a task
    func getTaskTimeInfo(_ task: Task) -> (spent: Int, planned: Int, remaining: Int, percentage: Double) {
        let spent = _minutesRemain(for: task)
        let planned = task.durationMinutes
        let remaining = max(0, planned - spent)
        let percentage = planned > 0 ? Double(spent) / Double(planned) : 0.0
        
        return (spent, planned, remaining, min(1.0, percentage))
    }
    
    // Format duration in a human-readable way
    func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
    
    // Calculate how late a task start would be (for UI display)
    func getLateStartInfo(for task: Task) -> (isLate: Bool, minutesLate: Int) {
        let now = Date()
        let taskStartTime = task.startTime
        
        if now > taskStartTime {
            let lateSeconds = now.timeIntervalSince(taskStartTime)
            let minutesLate = Int(lateSeconds / 60)
            return (true, minutesLate)
        }
        
        return (false, 0)
    }
    
    // Get the effective remaining time considering schedule
    func getEffectiveRemainingTime(for task: Task) -> Int {
        let now = Date()
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        if now >= taskEndTime {
            return 0 // Task time window has passed
        }
        
        let remainingScheduledTime = taskEndTime.timeIntervalSince(now)
        return Int(remainingScheduledTime / 60)
    }
}
