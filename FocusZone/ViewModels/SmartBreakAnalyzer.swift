import SwiftUI
import Foundation

// MARK: - Enhanced Smart Break Analyzer with Intelligent Spacing
class SmartBreakAnalyzer: ObservableObject {
    @Published var suggestions: [BreakSuggestion] = []
    
    // Configuration for suggestion spacing and limits
    private let minimumSuggestionSpacing: TimeInterval = 30 * 60 // 30 minutes
    private let maximumDailySuggestions = 5
    private let maximumActiveSuggestions = 1 // Only show one at a time
    
    // Track dismissed suggestions to avoid re-suggesting too soon
    private var dismissedSuggestions: Set<String> = []
    private var lastSuggestionTime: Date?
    
    func analyzeTasks(_ tasks: [Task]) -> [BreakSuggestion] {
        let sortedTasks = tasks.sorted { $0.startTime < $1.startTime }
        var potentialSuggestions: [BreakSuggestion] = []
        
        // Generate all potential suggestions first
        potentialSuggestions.append(contentsOf: analyzeTaskGaps(sortedTasks))
        potentialSuggestions.append(contentsOf: analyzeLongTasks(sortedTasks))
        potentialSuggestions.append(contentsOf: createTimeBasedSuggestions(for: sortedTasks))
        
        // Apply intelligent filtering and spacing
        let filteredSuggestions = applyIntelligentFiltering(potentialSuggestions)
        
        DispatchQueue.main.async {
            self.suggestions = filteredSuggestions
        }
        
        return filteredSuggestions
    }
    
    // MARK: - Intelligent Filtering System
    
    private func applyIntelligentFiltering(_ suggestions: [BreakSuggestion]) -> [BreakSuggestion] {
        let now = Date()
        
        // Step 1: Filter out suggestions that are too close to dismissed ones
        let validSuggestions = suggestions.filter { suggestion in
            !isDismissedRecently(suggestion) &&
            suggestion.suggestedStartTime > now &&
            !isConflictingWithExistingSuggestion(suggestion)
        }
        
        // Step 2: Sort by priority (impact score + timing relevance)
        let prioritizedSuggestions = validSuggestions.sorted { first, second in
            let firstScore = calculatePriorityScore(first, currentTime: now)
            let secondScore = calculatePriorityScore(second, currentTime: now)
            return firstScore > secondScore
        }
        
        // Step 3: Apply spacing rules and limits
        return applySpacingRules(prioritizedSuggestions)
    }
    
    private func calculatePriorityScore(_ suggestion: BreakSuggestion, currentTime: Date) -> Double {
        let baseScore = suggestion.impactScore
        
        // Time relevance factor (suggestions sooner get higher priority)
        let timeUntil = suggestion.suggestedStartTime.timeIntervalSince(currentTime)
        let timeRelevanceFactor = max(0.1, 1.0 - (timeUntil / (4 * 3600))) // Decay over 4 hours
        
        // Type priority multiplier
        let typePriority = getTypePriority(suggestion.type)
        
        // Context bonus (e.g., after long tasks, before important tasks)
        let contextBonus = calculateContextBonus(suggestion)
        
        return baseScore * timeRelevanceFactor * typePriority + contextBonus
    }
    
    private func getTypePriority(_ type: BreakType) -> Double {
        switch type {
        case .hydration: return 1.2 // Higher priority for health
        case .movement: return 1.1 // Important for physical well-being
        case .rest: return 1.0 // Standard priority
        case .snack: return 0.9 // Lower priority unless specifically needed
        case .fresh_air: return 0.8 // Nice to have
        case .eye_rest: return 0.7
        case .social: return 0.6
        }
    }
    
    private func calculateContextBonus(_ suggestion: BreakSuggestion) -> Double {
        var bonus = 0.0
        
        // Bonus for breaks after long tasks
        if suggestion.reason.contains("Long task") {
            bonus += 15.0
        }
        
        // Bonus for meal times
        let hour = Calendar.current.component(.hour, from: suggestion.suggestedStartTime)
        if suggestion.type == .snack && (hour == 12 || hour == 18) {
            bonus += 20.0
        }
        
        // Bonus for hydration reminders every 2 hours
        if suggestion.type == .hydration {
            bonus += 10.0
        }
        
        return bonus
    }
    
    private func applySpacingRules(_ suggestions: [BreakSuggestion]) -> [BreakSuggestion] {
        var selectedSuggestions: [BreakSuggestion] = []
        var lastSelectedTime: Date?
        
        for suggestion in suggestions {
            let canAdd = shouldAddSuggestion(
                suggestion,
                lastSelectedTime: lastSelectedTime,
                existingSuggestions: selectedSuggestions
            )
            
            if canAdd && selectedSuggestions.count < maximumActiveSuggestions {
                selectedSuggestions.append(suggestion)
                lastSelectedTime = suggestion.suggestedStartTime
                
                // For now, only add one suggestion at a time
                break
            }
        }
        
        return selectedSuggestions
    }
    
    private func shouldAddSuggestion(
        _ suggestion: BreakSuggestion,
        lastSelectedTime: Date?,
        existingSuggestions: [BreakSuggestion]
    ) -> Bool {
        // Check minimum spacing from last suggestion
        if let lastTime = lastSelectedTime {
            let timeSinceLastSuggestion = suggestion.suggestedStartTime.timeIntervalSince(lastTime)
            if timeSinceLastSuggestion < minimumSuggestionSpacing {
                return false
            }
        }
        
        // Check spacing from last actual suggestion time
        if let lastSuggestionTime = lastSuggestionTime {
            let timeSinceLastActual = Date().timeIntervalSince(lastSuggestionTime)
            if timeSinceLastActual < minimumSuggestionSpacing {
                return false
            }
        }
        
        // Check for conflicts with existing suggestions
        for existing in existingSuggestions {
            let timeDifference = abs(suggestion.suggestedStartTime.timeIntervalSince(existing.suggestedStartTime))
            if timeDifference < minimumSuggestionSpacing {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Enhanced Suggestion Generation
    
    private func analyzeTaskGaps(_ tasks: [Task]) -> [BreakSuggestion] {
        var suggestions: [BreakSuggestion] = []
        
        for i in 0..<tasks.count {
            let currentTask = tasks[i]
            
            // Skip completed tasks for future suggestions
            if currentTask.isCompleted { continue }
            
            // Check gap to next task
            if i < tasks.count - 1 {
                let nextTask = tasks[i + 1]
                let gapMinutes = Int(nextTask.startTime.timeIntervalSince(currentTask.estimatedEndTime) / 60)
                
                if let gapSuggestion = createGapSuggestion(
                    afterTask: currentTask,
                    beforeTask: nextTask,
                    gapMinutes: gapMinutes
                ) {
                    suggestions.append(gapSuggestion)
                }
            }
        }
        
        return suggestions
    }
    
    private func analyzeLongTasks(_ tasks: [Task]) -> [BreakSuggestion] {
        var suggestions: [BreakSuggestion] = []
        
        for task in tasks {
            if task.isCompleted || task.durationMinutes < 90 { continue }
            
            // Suggest mid-task break for long tasks
            let midPoint = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 30)) // 50% through
            let timeUntil = Int(midPoint.timeIntervalSince(Date()) / 60)
            
            if timeUntil > 0 {
                let suggestion = BreakSuggestion(
                    type: .movement,
                    suggestedDuration: 5,
                    reason: "Long task - stretch break recommended",
                    icon: "🤸",
                    timeUntilOptimal: timeUntil,
                    insertAfterTaskId: task.id,
                    suggestedStartTime: midPoint,
                    impactScore: 75.0
                )
                suggestions.append(suggestion)
            }
        }
        
        return suggestions
    }
    
    private func createGapSuggestion(
        afterTask: Task,
        beforeTask: Task,
        gapMinutes: Int
    ) -> BreakSuggestion? {
        let gapStart = afterTask.estimatedEndTime
        let timeUntilGap = Int(gapStart.timeIntervalSince(Date()) / 60)
        
        guard timeUntilGap > 0 else { return nil }
        
        switch gapMinutes {
        case 15...30:
            return BreakSuggestion(
                type: .snack,
                suggestedDuration: 15,
                reason: "Perfect time for a quick snack",
                icon: "🍎",
                timeUntilOptimal: timeUntilGap,
                insertAfterTaskId: afterTask.id,
                suggestedStartTime: gapStart,
                impactScore: 60.0
            )
            
        case 31...60:
            return BreakSuggestion(
                type: .movement,
                suggestedDuration: 20,
                reason: "Good opportunity for movement",
                icon: "🚶",
                timeUntilOptimal: timeUntilGap,
                insertAfterTaskId: afterTask.id,
                suggestedStartTime: gapStart.addingTimeInterval(300), // 5 min buffer
                impactScore: 70.0
            )
            
        case 61...120:
            return BreakSuggestion(
                type: .rest,
                suggestedDuration: 30,
                reason: "Time for a proper rest break",
                icon: "☕",
                timeUntilOptimal: timeUntilGap,
                insertAfterTaskId: afterTask.id,
                suggestedStartTime: gapStart.addingTimeInterval(600), // 10 min buffer
                impactScore: 80.0
            )
            
        default:
            return nil
        }
    }
    
    private func createTimeBasedSuggestions(for tasks: [Task]) -> [BreakSuggestion] {
        var suggestions: [BreakSuggestion] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Only create time-based suggestions if we don't have recent ones
        guard shouldCreateTimeBasedSuggestion() else { return suggestions }
        
        // Hydration reminder (every 2 hours, but intelligently timed)
        if let nextHydrationTime = findNextOptimalHydrationTime(tasks: tasks, from: now) {
            suggestions.append(BreakSuggestion(
                type: .hydration,
                suggestedDuration: 2,
                reason: "Stay hydrated for optimal focus",
                icon: "💧",
                timeUntilOptimal: Int(nextHydrationTime.timeIntervalSince(now) / 60),
                insertAfterTaskId: nil,
                suggestedStartTime: nextHydrationTime,
                impactScore: 65.0
            ))
        }
        
        return suggestions
    }
    
    private func shouldCreateTimeBasedSuggestion() -> Bool {
        // Only create time-based suggestions if we haven't created any in the last hour
        guard let lastTime = lastSuggestionTime else { return true }
        return Date().timeIntervalSince(lastTime) > 3600 // 1 hour
    }
    
    private func findNextOptimalHydrationTime(tasks: [Task], from: Date) -> Date? {
        let calendar = Calendar.current
        let twoHoursFromNow = from.addingTimeInterval(2 * 3600)
        
        // Find a time that doesn't conflict with tasks
        for task in tasks.sorted(by: { $0.startTime < $1.startTime }) {
            if task.startTime > twoHoursFromNow {
                // Check if there's a 5-minute window before this task
                let windowStart = task.startTime.addingTimeInterval(-5 * 60)
                if windowStart > from {
                    return windowStart
                }
            }
        }
        
        return twoHoursFromNow
    }
    
    // MARK: - Suggestion Management
    
    private func isDismissedRecently(_ suggestion: BreakSuggestion) -> Bool {
        let suggestionKey = "\(suggestion.type.rawValue)_\(Calendar.current.startOfDay(for: suggestion.suggestedStartTime))"
        return dismissedSuggestions.contains(suggestionKey)
    }
    
    private func isConflictingWithExistingSuggestion(_ suggestion: BreakSuggestion) -> Bool {
        return suggestions.contains { existing in
            let timeDifference = abs(suggestion.suggestedStartTime.timeIntervalSince(existing.suggestedStartTime))
            return timeDifference < minimumSuggestionSpacing
        }
    }
    
    // MARK: - Public Methods for Timeline Integration
    
    func markSuggestionShown(_ suggestion: BreakSuggestion) {
        lastSuggestionTime = Date()
    }
    
    func markSuggestionDismissed(_ suggestion: BreakSuggestion) {
        let suggestionKey = "\(suggestion.type.rawValue)_\(Calendar.current.startOfDay(for: suggestion.suggestedStartTime))"
        dismissedSuggestions.insert(suggestionKey)
        
        // Remove the dismissed suggestion from current suggestions
        suggestions.removeAll { $0.id == suggestion.id }
    }
    
    func markSuggestionAccepted(_ suggestion: BreakSuggestion) {
        // Remove the accepted suggestion and clear recent tracking
        suggestions.removeAll { $0.id == suggestion.id }
        lastSuggestionTime = Date()
    }
    
    // Clean up old dismissed suggestions (call daily)
    func cleanupDismissedSuggestions() {
        dismissedSuggestions.removeAll()
    }
}



extension SmartBreakAnalyzer {
    
    // MARK: - Advanced Suggestion Logic
    
    func shouldSuggestBreakAfterTask(_ task: Task, nextTask: Task?) -> BreakSuggestion? {
        let context = createSuggestionContext(for: task, nextTask: nextTask)
        
        // Don't suggest breaks after very short tasks
        guard task.durationMinutes >= 30 else { return nil }
        
        // Don't suggest if user just had a break task
        if task.taskType == .relax {
            return nil
        }
        
        // Calculate break urgency based on work streak
        let urgencyScore = calculateBreakUrgency(context: context)
        
        guard urgencyScore >= 50 else { return nil }
        
        // Choose break type based on context
        let breakType = chooseBestBreakType(for: context)
        let breakDuration = calculateOptimalBreakDuration(for: context, type: breakType)
        
        let suggestion = BreakSuggestion(
            type: breakType,
            suggestedDuration: breakDuration,
            reason: generateContextualReason(for: breakType, context: context),
            icon: breakType.icon,
            timeUntilOptimal: Int(task.estimatedEndTime.addingTimeInterval(300).timeIntervalSince(Date()) / 60), // 5 min buffer
            insertAfterTaskId: task.id,
            suggestedStartTime: task.estimatedEndTime.addingTimeInterval(300),
            impactScore: urgencyScore,
            priority: urgencyScore >= 80 ? .high : .medium
        )
        
        return suggestion
    }
    
    private func createSuggestionContext(for task: Task, nextTask: Task?) -> SuggestionContext {
        return SuggestionContext(
            triggerTask: task,
            nextTask: nextTask,
            currentWorkStreak: calculateWorkStreak(endingWith: task),
            lastBreakTime: findLastBreakTime(),
            timeOfDay: SuggestionContext.TimeOfDay.from(date: task.estimatedEndTime),
            workloadIntensity: assessWorkloadIntensity(for: task)
        )
    }
    
    private func calculateBreakUrgency(context: SuggestionContext) -> Double {
        var urgencyScore = 30.0 // Base score
        
        // Work streak factor (longer streaks = higher urgency)
        let streakHours = context.currentWorkStreak / 3600
        if streakHours >= 3 {
            urgencyScore += 40.0
        } else if streakHours >= 2 {
            urgencyScore += 25.0
        } else if streakHours >= 1 {
            urgencyScore += 10.0
        }
        
        // Time since last break factor
        if let lastBreak = context.lastBreakTime {
            let timeSinceBreak = Date().timeIntervalSince(lastBreak) / 3600
            if timeSinceBreak >= 2 {
                urgencyScore += 30.0
            } else if timeSinceBreak >= 1 {
                urgencyScore += 15.0
            }
        } else {
            // No recent break found
            urgencyScore += 25.0
        }
        
        // Workload intensity factor
        switch context.workloadIntensity {
        case .intense:
            urgencyScore += 20.0
        case .heavy:
            urgencyScore += 15.0
        case .moderate:
            urgencyScore += 5.0
        case .light:
            urgencyScore -= 5.0
        }
        
        // Time of day factor
        switch context.timeOfDay {
        case .midday:
            urgencyScore += 10.0 // Lunch time
        case .afternoon:
            urgencyScore += 5.0 // Post-lunch dip
        default:
            break
        }
        
        // Gap to next task factor
        if let nextTask = context.nextTask {
            let gapMinutes = Int(nextTask.startTime.timeIntervalSince(context.triggerTask?.estimatedEndTime ?? Date()) / 60)
            if gapMinutes >= 15 && gapMinutes <= 60 {
                urgencyScore += 15.0 // Perfect break window
            } else if gapMinutes < 15 {
                urgencyScore -= 20.0 // Too tight
            }
        }
        
        return min(100.0, max(0.0, urgencyScore))
    }
    
    private func chooseBestBreakType(for context: SuggestionContext) -> BreakType {
        // Choose break type based on context
        switch context.timeOfDay {
        case .midday:
            return .snack // Lunch time
        case .afternoon:
            if context.currentWorkStreak > 2 * 3600 { // More than 2 hours
                return .movement
            } else {
                return .rest
            }
        case .morning:
            return .hydration
        case .evening:
            return .rest
        }
    }
    
    private func calculateOptimalBreakDuration(for context: SuggestionContext, type: BreakType) -> Int {
        let baseDuration = type.typicalDuration
        
        // Adjust based on gap to next task
        if let nextTask = context.nextTask {
            let gapMinutes = Int(nextTask.startTime.timeIntervalSince(context.triggerTask?.estimatedEndTime ?? Date()) / 60)
            let maxBreakDuration = max(5, gapMinutes - 10) // Leave 10 min buffer
            return min(baseDuration, maxBreakDuration)
        }
        
        // Adjust based on work intensity
        switch context.workloadIntensity {
        case .intense:
            return min(baseDuration + 10, 30) // Longer breaks for intense work
        case .heavy:
            return baseDuration + 5
        case .light:
            return max(baseDuration - 5, 5)
        default:
            return baseDuration
        }
    }
    
    private func generateContextualReason(for type: BreakType, context: SuggestionContext) -> String {
        let streakHours = Int(context.currentWorkStreak / 3600)
        
        switch type {
        case .movement:
            if streakHours >= 2 {
                return "You've been working for \(streakHours) hours - time to move!"
            } else {
                return "A quick walk will boost your energy"
            }
        case .hydration:
            return "Stay hydrated for optimal focus"
        case .rest:
            if context.workloadIntensity == .intense {
                return "Intense work session - rest will help you recharge"
            } else {
                return "Perfect time for a mental break"
            }
        case .snack:
            if context.timeOfDay == .midday {
                return "Fuel up with a healthy lunch break"
            } else {
                return "A healthy snack will maintain your energy"
            }
        case .fresh_air:
            return "Fresh air will clear your mind and boost alertness"
        case .eye_rest:
            return "Give your eyes a break from the screen"
        case .social:
            return "Connect with others to boost your mood"
        }
    }
    
    private func calculateWorkStreak(endingWith task: Task) -> TimeInterval {
        // Find consecutive work tasks leading up to this task
        let sortedTasks = suggestions.compactMap { $0.insertAfterTaskId }.compactMap { id in
            // This would need access to the task list - simplified for this example
            return task // Placeholder
        }
        
        // Simplified calculation - in real implementation, would track actual work time
        return TimeInterval(task.durationMinutes * 60)
    }
    
    private func findLastBreakTime() -> Date? {
        // Find the most recent break/relax task
        // This would need access to the task list - simplified for this example
        return nil
    }
    
    private func assessWorkloadIntensity(for task: Task) -> SuggestionContext.WorkloadIntensity {
        // Assess intensity based on task duration and type
        switch task.taskType {
        case .work:
            if task.durationMinutes >= 120 {
                return .intense
            } else if task.durationMinutes >= 60 {
                return .heavy
            } else {
                return .moderate
            }
        case .study:
            return task.durationMinutes >= 90 ? .heavy : .moderate
        default:
            return .light
        }
    }
    
    // MARK: - Suggestion Validation
    
    func validateSuggestion(_ suggestion: BreakSuggestion) -> Bool {
        // Validate that suggestion is still relevant and beneficial
        let now = Date()
        
        // Check if suggestion time has passed
        if suggestion.suggestedStartTime <= now {
            return false
        }
        
        // Check if suggestion is too far in the future
        let timeUntilSuggestion = suggestion.suggestedStartTime.timeIntervalSince(now)
        if timeUntilSuggestion > 4 * 3600 { // 4 hours
            return false
        }
        
        // Check minimum impact threshold
        if suggestion.impactScore < 40.0 {
            return false
        }
        
        return true
    }
    
    // MARK: - Suggestion Metrics and Analytics
    
    func getSuggestionMetrics() -> BreakSuggestionMetrics {
        return BreakSuggestionMetrics(
            totalSuggestions: suggestions.count,
            averageImpactScore: suggestions.map(\.impactScore).reduce(0, +) / Double(max(1, suggestions.count)),
            typeDistribution: Dictionary(grouping: suggestions, by: \.type).mapValues { $0.count },
            priorityDistribution: Dictionary(grouping: suggestions, by: \.priority).mapValues { $0.count }
        )
    }
}

struct BreakSuggestionMetrics {
    let totalSuggestions: Int
    let averageImpactScore: Double
    let typeDistribution: [BreakType: Int]
    let priorityDistribution: [SuggestionPriority: Int]
    
    var description: String {
        return """
        Break Suggestion Metrics:
        - Total: \(totalSuggestions)
        - Avg Impact: \(String(format: "%.1f", averageImpactScore))
        - Types: \(typeDistribution)
        - Priorities: \(priorityDistribution)
        """
    }
}
