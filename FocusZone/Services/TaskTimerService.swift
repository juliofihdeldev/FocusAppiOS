import SwiftUI
import Combine
import SwiftData

class TaskTimerService: ObservableObject {
    @Published var currentTask: Task?
    @Published var elapsedSeconds: Int = 0
    
    private var timer: Timer?
    private var startTime: Date?
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // Start a task
    @MainActor func startTask(_ task: Task) {
        stopCurrentTask()
        
        task.status = .inProgress
        task.actualStartTime = Date()
        saveContext()
        
        currentTask = task
        startTime = Date()
        elapsedSeconds = task.timeSpentMinutes * 60
        
        startTimer()
    }
    
    // Pause the current task
    @MainActor func pauseTask() {
        guard let task = currentTask else { return }
        
        stopTimer()
        
        let totalTimeSpent = task.timeSpentMinutes + (elapsedSeconds / 60)
        task.status = .paused
        task.timeSpentMinutes = totalTimeSpent
        task.updatedAt = Date()
        saveContext()
    }
    
    // Resume a paused task
    @MainActor func resumeTask() {
        guard let task = currentTask, task.isPaused else { return }
        
        task.status = .inProgress
        task.updatedAt = Date()
        saveContext()
        
        startTimer()
    }
    
    // Complete the current task
    @MainActor func completeTask() {
        guard let task = currentTask else { return }
        
        stopTimer()
        
        let totalTimeSpent = task.timeSpentMinutes + (elapsedSeconds / 60)
        task.isCompleted = true
        task.status = .completed
        task.timeSpentMinutes = totalTimeSpent
        task.updatedAt = Date()
        saveContext()
        
        // Clear after a brief delay to show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentTask = nil
            self.elapsedSeconds = 0
        }
    }
    
    // Stop the current task
    func stopCurrentTask() {
        stopTimer()
        currentTask = nil
        elapsedSeconds = 0
        startTime = nil
    }
    
    // Private timer methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.elapsedSeconds += 1
                
                // Check if timer should auto-complete when remaining time reaches 0
                if self.currentRemainingMinutes <= 0 && !self.isOvertime {
                    self.handleTimerCompletion()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Handle automatic timer completion
    @MainActor private func handleTimerCompletion() {
        guard let task = currentTask else { return }
        
        stopTimer()
        
        // Mark task as completed automatically
        let totalTimeSpent = task.timeSpentMinutes + (elapsedSeconds / 60)
        task.isCompleted = true
        task.status = .completed
        task.timeSpentMinutes = task.durationMinutes // Set to exact duration
        task.updatedAt = Date()
        saveContext()
        
        // Show completion notification or update UI
        print("Task '\(task.title)' completed automatically after \(task.durationMinutes) minutes")
        
        // Clear after a brief delay to show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentTask = nil
            self.elapsedSeconds = 0
        }
    }
    
    // Computed properties
    var currentElapsedMinutes: Int {
        elapsedSeconds / 60
    }
    
    var currentRemainingMinutes: Int {
        guard let task = currentTask else { return 0 }
        return max(0, task.durationMinutes - currentElapsedMinutes)
    }
    
    var currentProgressPercentage: Double {
        guard let task = currentTask, task.durationMinutes > 0 else { return 0 }
        return min(1.0, Double(currentElapsedMinutes) / Double(task.durationMinutes))
    }
    
    var isOvertime: Bool {
        guard let task = currentTask else { return false }
        return currentElapsedMinutes > task.durationMinutes
    }
    
    var formattedElapsedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedRemainingTime: String {
        let totalSeconds = currentRemainingMinutes * 60
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Additional computed properties for better timer control
    var isTimerRunning: Bool {
        return timer != nil && currentTask?.isActive == true
    }
    
    var shouldShowOvertime: Bool {
        return isOvertime && currentTask?.isActive == true
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
}
