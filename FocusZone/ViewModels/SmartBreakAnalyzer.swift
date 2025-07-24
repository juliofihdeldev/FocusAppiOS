import SwiftUI
import Foundation

// MARK: - Smart Break Analyzer
class SmartBreakAnalyzer: ObservableObject {
    @Published var suggestions: [BreakSuggestion] = []
    
    func analyzeTasks(_ tasks: [Task]) -> [BreakSuggestion] {
        var newSuggestions: [BreakSuggestion] = []
        let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
        
        // Analyze gaps between tasks and task durations
        for i in 0..<sortedTasks.count {
            let currentTask = sortedTasks[i]
            
            // Skip completed tasks for future suggestions
            if currentTask.isCompleted { continue }
            
            // Check if task is long (>90 minutes) and suggest mid-task break
            if currentTask.durationMinutes > 90 {
                let midTaskBreak = createMidTaskBreakSuggestion(for: currentTask)
                newSuggestions.append(midTaskBreak)
            }
            
            // Check gap to next task
            if i < sortedTasks.count - 1 {
                let nextTask = sortedTasks[i + 1]
                let gapMinutes = Int(nextTask.startTime.timeIntervalSince(currentTask.estimatedEndTime) / 60)
                
                if let gapSuggestion = analyzeGap(
                    afterTask: currentTask,
                    beforeTask: nextTask,
                    gapMinutes: gapMinutes
                ) {
                    newSuggestions.append(gapSuggestion)
                }
            }
        }
        
        // Add time-based suggestions (meal times, hydration reminders)
        newSuggestions.append(contentsOf: createTimeBasedSuggestions(for: sortedTasks))
        
        // Filter and sort suggestions
        let filteredSuggestions = newSuggestions
            .filter { $0.suggestedStartTime > Date() } // Only future suggestions
            .sorted { $0.suggestedStartTime < $1.suggestedStartTime }
        
        DispatchQueue.main.async {
            self.suggestions = filteredSuggestions
        }
        
        return filteredSuggestions
    }
    
    private func createMidTaskBreakSuggestion(for task: Task) -> BreakSuggestion {
        let midPoint = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 30)) // 50% through
        let timeUntil = Int(midPoint.timeIntervalSince(Date()) / 60)
        
        return BreakSuggestion(
            type: .movement,
            suggestedDuration: 5,
            reason: "Long task - stretch break recommended",
            icon: "🤸",
            timeUntilOptimal: max(0, timeUntil),
            insertAfterTaskId: task.id,
            suggestedStartTime: midPoint
        )
    }
    
    private func analyzeGap(afterTask: Task, beforeTask: Task, gapMinutes: Int) -> BreakSuggestion? {
        let gapStart = afterTask.estimatedEndTime
        let timeUntilGap = Int(gapStart.timeIntervalSince(Date()) / 60)
        
        // Different suggestions based on gap length
        switch gapMinutes {
        case 15...30:
            return BreakSuggestion(
                type: .snack,
                suggestedDuration: 15,
                reason: "Perfect time for a snack",
                icon: "🍎",
                timeUntilOptimal: max(0, timeUntilGap),
                insertAfterTaskId: afterTask.id,
                suggestedStartTime: gapStart
            )
            
        case 31...60:
            return BreakSuggestion(
                type: .movement,
                suggestedDuration: 20,
                reason: "Good break for movement",
                icon: "🚶",
                timeUntilOptimal: max(0, timeUntilGap),
                insertAfterTaskId: afterTask.id,
                suggestedStartTime: gapStart.addingTimeInterval(300) // 5 min buffer
            )
            
        case 61...120:
            return BreakSuggestion(
                type: .rest,
                suggestedDuration: 30,
                reason: "Time for a proper break",
                icon: "☕",
                timeUntilOptimal: max(0, timeUntilGap),
                insertAfterTaskId: afterTask.id,
                suggestedStartTime: gapStart.addingTimeInterval(600) // 10 min buffer
            )
            
        default:
            return nil
        }
    }
    
    private func createTimeBasedSuggestions(for tasks: [Task]) -> [BreakSuggestion] {
        var suggestions: [BreakSuggestion] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Hydration reminders every 2 hours
        let nextHydrationTime = calendar.date(byAdding: .hour, value: 2, to: now) ?? now
        if !hasTaskConflict(at: nextHydrationTime, tasks: tasks) {
            suggestions.append(BreakSuggestion(
                type: .hydration,
                suggestedDuration: 2,
                reason: "Stay hydrated",
                icon: "💧",
                timeUntilOptimal: Int(nextHydrationTime.timeIntervalSince(now) / 60),
                insertAfterTaskId: nil,
                suggestedStartTime: nextHydrationTime
            ))
        }
        
        // Lunch suggestion if no lunch task exists
        if let lunchTime = calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now),
           lunchTime > now,
           !hasLunchTask(tasks: tasks) {
            suggestions.append(BreakSuggestion(
                type: .snack,
                suggestedDuration: 45,
                reason: "Lunch time",
                icon: "🍽️",
                timeUntilOptimal: Int(lunchTime.timeIntervalSince(now) / 60),
                insertAfterTaskId: nil,
                suggestedStartTime: lunchTime
            ))
        }
        
        return suggestions
    }
    
    private func hasTaskConflict(at time: Date, tasks: [Task]) -> Bool {
        return tasks.contains { task in
            time >= task.startTime && time <= task.estimatedEndTime
        }
    }
    
    private func hasLunchTask(tasks: [Task]) -> Bool {
        return tasks.contains { task in
            task.title.lowercased().contains("lunch") ||
            task.taskType == .meal
        }
    }
}
