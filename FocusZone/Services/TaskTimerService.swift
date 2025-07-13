import SwiftUI
import Combine

class TaskTimerService: ObservableObject {
    @Published var currentTask: Task?
    @Published var elapsedSeconds: Int = 0
    
    private var timer: Timer?
    private var startTime: Date?
    
    // Start a task
    func startTask(_ task: Task) {
        stopCurrentTask()
        
        var updatedTask = task
        updatedTask.status = .inProgress(startedAt: Date())
        updatedTask.actualStartTime = Date()
        
        currentTask = updatedTask
        startTime = Date()
        elapsedSeconds = task.timeSpentMinutes * 60
        
        startTimer()
    }
    
    // Pause the current task
    func pauseTask() {
        guard var task = currentTask else { return }
        
        stopTimer()
        
        let totalTimeSpent = task.timeSpentMinutes + (elapsedSeconds / 60)
        task.status = .paused(timeSpent: totalTimeSpent, pausedAt: Date())
        task.timeSpentMinutes = totalTimeSpent
        
        currentTask = task
    }
    
    // Resume a paused task
    func resumeTask() {
        guard var task = currentTask, task.isPaused else { return }
        
        task.status = .inProgress(startedAt: Date())
        currentTask = task
        
        startTimer()
    }
    
    // Complete the current task
    func completeTask() {
        guard var task = currentTask else { return }
        
        stopTimer()
        
        let totalTimeSpent = task.timeSpentMinutes + (elapsedSeconds / 60)
        task.status = .completed(timeSpent: totalTimeSpent, completedAt: Date())
        task.timeSpentMinutes = totalTimeSpent
        
        currentTask = task
        
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
            self.elapsedSeconds += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
}