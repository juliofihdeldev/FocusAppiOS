import Foundation
import SwiftUI

class TaskConflictService: ObservableObject {
    
    enum ConflictType: String, CaseIterable {
        case timeOverlap = "Time Overlap"
        case noBuffer = "No Buffer Time"
        
        var icon: String {
            switch self {
            case .timeOverlap:
                return "exclamationmark.triangle.fill"
            case .noBuffer:
                return "clock.badge.exclamationmark"
            }
        }
        
        var displayName: String {
            switch self {
            case .timeOverlap:
                return "Time Overlap"
            case .noBuffer:
                return "No Buffer Time"
            }
        }
    }
    
    enum ConflictSeverity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    struct TaskConflict: Identifiable {
        let id = UUID()
        let type: ConflictType
        let severity: ConflictSeverity
        let message: String
        let conflictingTaskId: UUID?
        let conflictingTaskTitle: String?
    }
    
    func detectConflicts(for task: Task, in allTasks: [Task]) -> [TaskConflict] {
        var conflicts: [TaskConflict] = []
        
        // Check for time overlaps
        if let overlapConflict = checkTimeOverlap(for: task, in: allTasks) {
            conflicts.append(overlapConflict)
        }
        
        // Check for insufficient buffer time
        if let bufferConflict = checkBufferTime(for: task, in: allTasks) {
            conflicts.append(bufferConflict)
        }
        
        return conflicts
    }
    
    private func checkTimeOverlap(for task: Task, in allTasks: [Task]) -> TaskConflict? {
        let taskStart = task.startTime
        let taskEnd = task.estimatedEndTime
        
        for otherTask in allTasks where otherTask.id != task.id {
            let otherStart = otherTask.startTime
            let otherEnd = otherTask.estimatedEndTime
            
            // Check if tasks overlap
            if (taskStart < otherEnd && taskEnd > otherStart) {
                let severity: ConflictSeverity
                let message: String
                
                if task.startTime == otherTask.startTime {
                    severity = .critical
                    message = "Starts at same time as '\(otherTask.title)'"
                } else if taskStart < otherStart && taskEnd > otherStart {
                    severity = .high
                    message = "Overlaps with '\(otherTask.title)'"
                } else {
                    severity = .medium
                    message = "Overlaps with '\(otherTask.title)'"
                }
                
                return TaskConflict(
                    type: .timeOverlap,
                    severity: severity,
                    message: message,
                    conflictingTaskId: otherTask.id,
                    conflictingTaskTitle: otherTask.title
                )
            }
        }
        
        return nil
    }
    
    private func checkBufferTime(for task: Task, in allTasks: [Task]) -> TaskConflict? {
        let taskStart = task.startTime
        let taskEnd = task.estimatedEndTime
        
        for otherTask in allTasks where otherTask.id != task.id {
            let otherStart = otherTask.startTime
            let otherEnd = otherTask.estimatedEndTime
            
            // Check if there's less than 5 minutes between tasks
            let timeBetween = abs(taskStart.timeIntervalSince(otherEnd))
            if timeBetween < 300 && timeBetween > 0 { // 5 minutes = 300 seconds
                let minutes = Int(timeBetween/60)
                return TaskConflict(
                    type: .noBuffer,
                    severity: .low,
                    message: "Only \(minutes)m buffer with '\(otherTask.title)'",
                    conflictingTaskId: otherTask.id,
                    conflictingTaskTitle: otherTask.title
                )
            }
        }
        
        return nil
    }
}
