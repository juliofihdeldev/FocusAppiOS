
import SwiftUI
import Combine

enum TaskStatus: Equatable, Hashable {
    case scheduled
    case inProgress(startedAt: Date)
    case paused(timeSpent: Int, pausedAt: Date)
    case completed(timeSpent: Int, completedAt: Date)
    case cancelled
}

struct Task: Identifiable, Hashable {
    let id: UUID
    let title: String
    let icon: String
    let startTime: Date
    let durationMinutes: Int
    let color: Color
    let isCompleted: Bool
    let taskType: TaskType?
    let subtasks: [Subtask]? = []
    var status: TaskStatus = .scheduled
    var timeSpentMinutes: Int = 0
    var actualStartTime: Date?
    
    // Computed properties for task timing
    var isScheduled: Bool {
        if case .scheduled = status { return true }
        return false
    }
    
    var isActive: Bool {
        if case .inProgress = status { return true }
        return false
    }
    
    var isPaused: Bool {
        if case .paused = status { return true }
        return false
    }
    
    var isFinished: Bool {
        if case .completed = status { return true }
        return isCompleted
    }
    
    var remainingMinutes: Int {
        return max(0, durationMinutes - timeSpentMinutes)
    }
    
    var progressPercentage: Double {
        guard durationMinutes > 0 else { return 0 }
        return min(1.0, Double(timeSpentMinutes) / Double(durationMinutes))
    }
    
    var estimatedEndTime: Date {
        return startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }
    
    var actualEndTime: Date? {
        if case .completed(_, let completedAt) = status {
            return completedAt
        }
        return nil
    }
}

struct Subtask: Identifiable, Hashable {
    let id: UUID
    let title: String
    let isCompleted: Bool
}
 
