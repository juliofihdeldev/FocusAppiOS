import Foundation
import SwiftUI

/**
 * Enhanced Task Conflict Service with State Validation
 * 
 * This service detects conflicts between tasks while ensuring that:
 * 1. Conflicting tasks are still present in the actual task list (no ghost conflicts)
 * 2. Conflicting tasks are in their original state (not modified since conflict detection)
 * 
 * USAGE:
 * 
 * 1. Basic conflict detection:
 *    let conflicts = conflictService.detectConflicts(for: task, in: allTasks)
 * 
 * 2. Cache management (call these when tasks are modified):
 *    - conflictService.updateTaskStateCache(for: modifiedTask)  // When a task is updated
 *    - conflictService.removeTaskFromCache(taskId)             // When a task is deleted
 *    - conflictService.refreshTaskCache(taskId)                // Force refresh for external changes
 * 
 * 3. Periodic cleanup:
 *    - conflictService.cleanupCache()                          // Remove stale entries
 *    - conflictService.getCacheDebugInfo()                     // Debug cache state
 * 
 * INTEGRATION POINTS:
 * 
 * Call updateTaskStateCache() in these scenarios:
 * - Task start time changes
 * - Task duration changes  
 * - Task status changes
 * - Task completion state changes
 * 
 * Call removeTaskFromCache() when:
 * - Task is deleted
 * - Task is cancelled
 * 
 * The service automatically handles:
 * - Filtering out cancelled/deleted tasks
 * - Validating task state consistency
 * - Preventing conflicts with modified tasks
 * - Cache invalidation for changed tasks
 */
class TaskConflictService: ObservableObject {
    
    // Cache to track task state for conflict validation
    private var taskStateCache: [UUID: TaskStateSnapshot] = [:]
    
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
            return self.rawValue
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
    
    /// Snapshot of task state for conflict validation
    private struct TaskStateSnapshot {
        let startTime: Date
        let durationMinutes: Int
        let status: String
        let updatedAt: Date
        let isCompleted: Bool
        
        init(from task: Task) {
            self.startTime = task.startTime
            self.durationMinutes = task.durationMinutes
            self.status = task.statusRawValue
            self.updatedAt = task.updatedAt
            self.isCompleted = task.isCompleted
        }
        
        /// Checks if the current task state matches this snapshot
        func matches(_ task: Task) -> Bool {
            return task.startTime == startTime &&
                   task.durationMinutes == durationMinutes &&
                   task.statusRawValue == status &&
                   task.isCompleted == isCompleted
        }
    }
    
    func detectConflicts(for task: Task, in allTasks: [Task]) -> [TaskConflict] {
        var conflicts: [TaskConflict] = []
        
        // Filter out tasks that are no longer valid for conflict detection
        let validTasks = allTasks.filter { otherTask in
            // Skip the current task being checked
            guard otherTask.id != task.id else { return false }
            
            // Skip cancelled/deleted tasks
            guard otherTask.statusRawValue != "cancelled" else { return false }
            
            // Skip tasks that are no longer in the original state
            // This prevents conflicts with tasks that have been modified since detection
            guard isTaskInOriginalState(otherTask) else { return false }
            
            return true
        }
        
        // Check for time overlaps
        if let overlapConflict = checkTimeOverlap(for: task, in: validTasks) {
            // Validate that the conflicting task is still present and unchanged
            if let conflictId = overlapConflict.conflictingTaskId,
               isConflictStillValid(conflictId, in: validTasks) {
                conflicts.append(overlapConflict)
            }
        }
        
        // Check for insufficient buffer time
        if let bufferConflict = checkBufferTime(for: task, in: validTasks) {
            // Validate that the conflicting task is still present and unchanged
            if let conflictId = bufferConflict.conflictingTaskId,
               isConflictStillValid(conflictId, in: validTasks) {
                conflicts.append(bufferConflict)
            }
        }
        
        return conflicts
    }
    
    /// Validates that a conflict is still valid by checking if the conflicting task
    /// is still present in the current task list and hasn't been modified
    private func isConflictStillValid(_ conflictingTaskId: UUID, in currentTasks: [Task]) -> Bool {
        // Check if the conflicting task is still in the current task list
        guard let conflictingTask = currentTasks.first(where: { $0.id == conflictingTaskId }) else {
            return false
        }
        
        // Check if the task is still in its original state
        return isTaskInOriginalState(conflictingTask)
    }
    
    /// Validates that a task is still in its original state for conflict detection
    /// This prevents conflicts with tasks that have been modified, moved, or deleted
    private func isTaskInOriginalState(_ task: Task) -> Bool {
        // Check if the task has been cancelled/deleted
        if task.statusRawValue == "cancelled" {
            return false
        }
        
        // Check if the task has been completed (completed tasks shouldn't cause conflicts)
        if task.statusRawValue == "completed" || task.isCompleted {
            return false
        }
        
        // Check if we have a cached snapshot of this task
        if let cachedSnapshot = taskStateCache[task.id] {
            // If the current state doesn't match the cached snapshot, the task has changed
            if !cachedSnapshot.matches(task) {
                // Remove the stale snapshot
                taskStateCache.removeValue(forKey: task.id)
                return false
            }
            // Task state matches the cached snapshot, so it's still valid
            return true
        } else {
            // No cached snapshot exists, so this is a new task or first time checking
            // Create a snapshot and cache it for future validation
            let snapshot = TaskStateSnapshot(from: task)
            taskStateCache[task.id] = snapshot
            return true
        }
    }
    
    /// Updates the cache when a task is modified
    /// Call this method whenever a task is updated to keep the cache in sync
    func updateTaskStateCache(for task: Task) {
        let snapshot = TaskStateSnapshot(from: task)
        taskStateCache[task.id] = snapshot
    }
    
    /// Removes a task from the cache (e.g., when it's deleted)
    func removeTaskFromCache(_ taskId: UUID) {
        taskStateCache.removeValue(forKey: taskId)
    }
    
    /// Cleans up stale cache entries
    func cleanupCache() {
        let now = Date()
        let staleThreshold: TimeInterval = 24 * 60 * 60 // 24 hours
        
        taskStateCache = taskStateCache.filter { _, snapshot in
            // Keep only recent snapshots
            return now.timeIntervalSince(snapshot.updatedAt) < staleThreshold
        }
    }
    
    /// Gets debug information about the current cache state
    func getCacheDebugInfo() -> String {
        let cacheSize = taskStateCache.count
        let now = Date()
        let recentEntries = taskStateCache.values.filter { snapshot in
            now.timeIntervalSince(snapshot.updatedAt) < 3600 // Last hour
        }.count
        
        return """
        TaskConflictService Cache Info:
        - Total cached tasks: \(cacheSize)
        - Recent entries (last hour): \(recentEntries)
        - Cache timestamp: \(now)
        """
    }
    
    /// Forces a cache refresh for a specific task
    /// Useful when you know a task has been modified externally
    func refreshTaskCache(_ taskId: UUID) {
        taskStateCache.removeValue(forKey: taskId)
    }
    
    /// Clears the entire cache (use with caution)
    func clearCache() {
        taskStateCache.removeAll()
    }
    
    /// Test method to verify conflict detection validation
    /// This helps developers test that the system is working correctly
    func testConflictValidation(for task: Task, in allTasks: [Task]) -> (conflicts: [TaskConflict], validationInfo: String) {
        let conflicts = detectConflicts(for: task, in: allTasks)
        
        let validationInfo = """
        Conflict Detection Test Results:
        - Task: '\(task.title)' (ID: \(task.id))
        - Total tasks in list: \(allTasks.count)
        - Valid tasks for conflict detection: \(allTasks.filter { isTaskInOriginalState($0) }.count)
        - Cached task states: \(taskStateCache.count)
        - Conflicts detected: \(conflicts.count)
        - Cache info: \(getCacheDebugInfo())
        """
        
        return (conflicts, validationInfo)
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
