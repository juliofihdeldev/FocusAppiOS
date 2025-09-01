//
//  FocusAnalyticsEngine.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/24/25.
//

import Foundation
import SwiftData

// MARK: - Focus Analytics Engine
@MainActor
class FocusAnalyticsEngine: ObservableObject {
    @Published var weeklyInsights: [FocusInsight] = []
    @Published var isAnalyzing = false

    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Main Analysis Function
    func generateWeeklyInsights() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        guard let tasks = await fetchRecentTasks() else { return }
        
        var insights: [FocusInsight] = []
        
        // Analyze different patterns
        insights.append(contentsOf: analyzeTimeOfDayPatterns(tasks))
        insights.append(contentsOf: analyzeTaskDurationPatterns(tasks))
        insights.append(contentsOf: analyzeBreakEffectiveness(tasks))
        insights.append(contentsOf: analyzeCompletionPatterns(tasks))
        insights.append(contentsOf: analyzeDayOfWeekPatterns(tasks))
        
        // Sort by impact score and take top 3-5
        weeklyInsights = insights
            .sorted { $0.impactScore > $1.impactScore }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Weekly Plan Builder (Apply for this week)

    func buildWeeklyPlan(for range: DateInterval) async -> [PlannedChange] {
        guard let modelContext = modelContext else { return [] }
        // Fetch tasks within the week window
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.startTime >= range.start && task.startTime < range.end && !task.isCompleted
            },
            sortBy: [SortDescriptor(\.startTime)]
        )
        let tasksInWeek: [Task]
        do { tasksInWeek = try modelContext.fetch(descriptor) } catch { return [] }

        var changes: [PlannedChange] = []

        // 1) timeOfDay: move up to 3 work/study tasks into 6-9 AM if currently outside window
        let targetWindow = TimeOfDay.earlyMorning // 6-9 AM
        let candidates = tasksInWeek.filter { ($0.taskType == .work || $0.taskType == .study) && !isDate($0.startTime, in: targetWindow) }
        for task in candidates.prefix(3) {
            if let movedStart = suggestStart(in: targetWindow, sameDayAs: task.startTime, duration: task.durationMinutes) {
                changes.append(.moveTask(taskId: task.id, toStart: movedStart))
                // Break before important tasks: 10 minutes
                let breakStart = movedStart.addingTimeInterval(TimeInterval(-10 * 60))
                if breakStart >= startOfDay(task.startTime) {
                    changes.append(.addFocusBlock(date: breakStart, durationMinutes: 10, title: NSLocalizedString("break_auto", comment: "Auto-generated break title")))
                }
            }
        }

        // 2) taskDuration: split long tasks (> 90m) into 2 chunks (e.g., 2×45)
        let longTasks = tasksInWeek.filter { $0.durationMinutes > 90 }
        for task in longTasks.prefix(2) {
            changes.append(.splitTask(taskId: task.id, chunksMinutes: [task.durationMinutes / 2, task.durationMinutes - task.durationMinutes / 2]))
        }

        // 3) completion: if last 7-day completion looks low, add a catch-up 60m block mid-week evening (6-9 PM)
        if let lowCompletion = weeklyInsights.first(where: { $0.type == .completion && $0.title.contains(NSLocalizedString("room_for_growth", comment: "Room for Growth insight title")) }) {
            let midWeek = Calendar.current.date(byAdding: .day, value: 3, to: range.start) ?? range.start
            if let catchUpStart = suggestStart(in: .evening, sameDayAs: midWeek, duration: 60) {
                changes.append(.addFocusBlock(date: catchUpStart, durationMinutes: 60, title: NSLocalizedString("catch_up_focus_auto", comment: "Auto-generated catch-up focus title")))
            }
        }

        return changes
    }

 
    // MARK: - Helpers (planning)
    private func fetchTask<T: PersistentModel>(by id: UUID, in context: ModelContext) -> T? {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in task.id == id }
        )
        if let found = try? context.fetch(descriptor).first, let asT = found as? T { return asT }
        return nil
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func isDate(_ date: Date, in slot: TimeOfDay) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        switch slot {
        case .earlyMorning: return (6..<9).contains(hour)
        case .lateMorning: return (9..<12).contains(hour)
        case .earlyAfternoon: return (12..<15).contains(hour)
        case .lateAfternoon: return (15..<18).contains(hour)
        case .evening: return (18..<21).contains(hour)
        case .night: return hour < 6 || hour >= 21
        }
    }

    private func suggestStart(in slot: TimeOfDay, sameDayAs date: Date, duration: Int) -> Date? {
        let cal = Calendar.current
        let dayStart = startOfDay(date)
        let components = cal.dateComponents([.year, .month, .day], from: dayStart)
        let startHour: Int
        switch slot {
        case .earlyMorning: startHour = 6
        case .lateMorning: startHour = 9
        case .earlyAfternoon: startHour = 12
        case .lateAfternoon: startHour = 15
        case .evening: startHour = 18
        case .night: startHour = 21
        }
        if let base = cal.date(from: DateComponents(year: components.year, month: components.month, day: components.day, hour: startHour, minute: 0)) {
            return base
        }
        return nil
    }
    
    // MARK: - Pattern Analysis Functions
    
    private func analyzeTimeOfDayPatterns(_ tasks: [Task]) -> [FocusInsight] {
        let timeSlots = categorizeTasksByTimeOfDay(tasks)
        var insights: [FocusInsight] = []
        
        // Find best performance time
        if let bestSlot = timeSlots.max(by: { $0.value.averageCompletionRate < $1.value.averageCompletionRate }) {
            let improvement = bestSlot.value.averageCompletionRate - timeSlots.values.map(\.averageCompletionRate).average()
            
            if improvement > 0.15 { // 15% better than average
                insights.append(FocusInsight(
                    type: .timeOfDay,
                    title: "🌅 Peak Performance Window",
                                    message: String(format: NSLocalizedString("more_productive_during_time", comment: "More productive during time period message"), Int(improvement * 100), bestSlot.key.displayName),
                recommendation: String(format: NSLocalizedString("schedule_important_tasks_between", comment: "Schedule important tasks between time recommendation"), bestSlot.key.timeRange),
                    impactScore: improvement * 100,
                    dataPoints: bestSlot.value.taskCount,
                    trend: .improving
                ))
            }
        }
        
        // Find worst performance time
        if let worstSlot = timeSlots.min(by: { $0.value.averageCompletionRate < $1.value.averageCompletionRate }) {
            let decline = timeSlots.values.map(\.averageCompletionRate).average() - worstSlot.value.averageCompletionRate
            
            if decline > 0.20 { // 20% worse than average
                insights.append(FocusInsight(
                    type: .timeOfDay,
                    title: "⚠️ Energy Dip Detected",
                                    message: String(format: NSLocalizedString("focus_drops_during_time", comment: "Focus drops during time period message"), Int(decline * 100), worstSlot.key.displayName),
                recommendation: String(format: NSLocalizedString("schedule_breaks_admin_tasks", comment: "Schedule breaks or admin tasks during time recommendation"), worstSlot.key.timeRange),
                    impactScore: decline * 80,
                    dataPoints: worstSlot.value.taskCount,
                    trend: .declining
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeTaskDurationPatterns(_ tasks: [Task]) -> [FocusInsight] {
        let durationGroups = Dictionary(grouping: tasks) { task in
            DurationCategory.from(minutes: task.durationMinutes)
        }
        
        var insights: [FocusInsight] = []
        
        // Find optimal task duration
        if let optimalDuration = durationGroups.max(by: { $0.value.averageCompletionRate < $1.value.averageCompletionRate }) {
            let completionRate = optimalDuration.value.averageCompletionRate
            
            if completionRate > 0.8 && optimalDuration.value.count >= 5 {
                insights.append(FocusInsight(
                    type: .taskDuration,
                    title: "⏱️ Sweet Spot Duration",
                                    message: String(format: NSLocalizedString("complete_percentage_duration_tasks", comment: "Complete percentage of duration tasks message"), Int(completionRate * 100), optimalDuration.key.displayName),
                recommendation: String(format: NSLocalizedString("break_longer_tasks_chunks", comment: "Break longer tasks into chunks recommendation"), optimalDuration.key.suggestedDuration),
                    impactScore: completionRate * 90,
                    dataPoints: optimalDuration.value.count,
                    trend: .stable
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeBreakEffectiveness(_ tasks: [Task]) -> [FocusInsight] {
        // Group tasks by whether they followed a break
        let tasksAfterBreaks = tasks.filter { task in
            // Check if there was a break in the previous 30 minutes
            let thirtyMinutesBefore = task.startTime.addingTimeInterval(-30 * 60)
            return tasks.contains { breakTask in
                breakTask.taskType == .relax &&
                breakTask.startTime >= thirtyMinutesBefore &&
                breakTask.startTime < task.startTime
            }
        }
        
        let tasksWithoutBreaks = tasks.filter { !tasksAfterBreaks.contains($0) }
        
        guard tasksAfterBreaks.count >= 3 && tasksWithoutBreaks.count >= 3 else { return [] }
        
        let breakBenefit = tasksAfterBreaks.averageCompletionRate - tasksWithoutBreaks.averageCompletionRate
        
        if breakBenefit > 0.15 {
            return [FocusInsight(
                type: .breakPattern,
                title: "🧘 Break Power Boost",
                message: String(format: NSLocalizedString("tasks_after_breaks_higher_completion", comment: "Tasks after breaks have higher completion rates message"), Int(breakBenefit * 100)),
                recommendation: NSLocalizedString("schedule_breaks_before_important_tasks", comment: "Schedule breaks before important tasks recommendation"),
                impactScore: breakBenefit * 85,
                dataPoints: tasksAfterBreaks.count,
                trend: .improving
            )]
        }
        
        return []
    }
    
    private func analyzeCompletionPatterns(_ tasks: [Task]) -> [FocusInsight] {
        let last7Days = tasks.filter { task in
            task.startTime >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        }
        
        let completionRate = last7Days.averageCompletionRate
        let totalFocusMinutes = last7Days.filter(\.isCompleted).reduce(0) { $0 + $1.durationMinutes }
        
        var insights: [FocusInsight] = []
        
        // Weekly summary
        if last7Days.count >= 5 {
            let weeklyGoal: Double = 0.75 // 75% completion target
            
            if completionRate >= weeklyGoal {
                insights.append(FocusInsight(
                    type: .completion,
                    title: "🎯 Consistency Champion",
                                    message: String(format: NSLocalizedString("completed_percentage_tasks_week", comment: "Completed percentage of tasks this week message"), Int(completionRate * 100), totalFocusMinutes/60),
                recommendation: NSLocalizedString("great_momentum_increase_goals", comment: "Great momentum, consider increasing goals recommendation"),
                    impactScore: completionRate * 70,
                    dataPoints: last7Days.count,
                    trend: .improving
                ))
            } else {
                let shortfall = weeklyGoal - completionRate
                insights.append(FocusInsight(
                    type: .completion,
                    title: "📈 Room for Growth",
                                    message: String(format: NSLocalizedString("away_from_completion_goal", comment: "Away from completion goal message"), Int(shortfall * 100)),
                recommendation: NSLocalizedString("reduce_task_durations_schedule_fewer", comment: "Reduce task durations or schedule fewer recommendation"),
                    impactScore: shortfall * 60,
                    dataPoints: last7Days.count,
                    trend: .needsImprovement
                ))
            }
        }
        
        return insights
    }
    
    private func analyzeDayOfWeekPatterns(_ tasks: [Task]) -> [FocusInsight] {
        let dayGroups = Dictionary(grouping: tasks) { task in
            Calendar.current.component(.weekday, from: task.startTime)
        }
        
        guard dayGroups.count >= 4 else { return [] }
        
        let dayPerformance = dayGroups.mapValues { tasks in
            tasks.averageCompletionRate
        }
        
        if let bestDay = dayPerformance.max(by: { $0.value < $1.value }),
           let worstDay = dayPerformance.min(by: { $0.value < $1.value }) {
            
            let difference = bestDay.value - worstDay.value
            
            if difference > 0.25 {
                return [FocusInsight(
                    type: .dayOfWeek,
                    title: "📅 Weekly Rhythm",
                    message: "\(dayName(bestDay.key)) is your strongest day (\(Int(bestDay.value * 100))% completion)",
                    recommendation: String(format: NSLocalizedString("schedule_challenging_tasks_on_day", comment: "Schedule challenging tasks on specific day recommendation"), dayName(bestDay.key)),
                    impactScore: difference * 75,
                    dataPoints: dayGroups[bestDay.key]?.count ?? 0,
                    trend: .stable
                )]
            }
        }
        
        return []
    }
    
    // MARK: - Helper Functions
    
    private func fetchRecentTasks() async -> [Task]? {
        guard let modelContext = modelContext else { return nil }
        
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.startTime >= thirtyDaysAgo && !task.isGeneratedFromRepeat
            },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching tasks for analysis: \(error)")
            return nil
        }
    }
    
    private func categorizeTasksByTimeOfDay(_ tasks: [Task]) -> [TimeOfDay: TimeSlotMetrics] {
        let grouped = Dictionary(grouping: tasks) { task in
            TimeOfDay.from(date: task.startTime)
        }
        
        return grouped.mapValues { tasks in
            TimeSlotMetrics(
                taskCount: tasks.count,
                averageCompletionRate: tasks.averageCompletionRate,
                totalMinutes: tasks.reduce(0) { $0 + $1.durationMinutes }
            )
        }
    }
    
    private func dayName(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.weekdaySymbols = formatter.weekdaySymbols
        return formatter.weekdaySymbols[weekday - 1]
    }
}

// MARK: - Supporting Models

struct FocusInsight: Identifiable, Codable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let recommendation: String
    let impactScore: Double // 0-100, higher = more important
    let dataPoints: Int // How many tasks this insight is based on
    let trend: Trend
    let createdAt = Date()
}

enum InsightType: String, Codable, CaseIterable {
    case timeOfDay = "timeOfDay"
    case taskDuration = "taskDuration"
    case breakPattern = "breakPattern"
    case completion = "completion"
    case dayOfWeek = "dayOfWeek"
}

enum Trend: String, Codable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    case needsImprovement = "needsImprovement"
}

enum PlannedChange: Identifiable {
    var id: String {
        switch self {
        case let .createBreak(beforeTaskId, minutes): return "break-\(beforeTaskId)-\(minutes)"
        case let .moveTask(taskId, toStart): return "move-\(taskId)-\(toStart.timeIntervalSince1970)"
        case let .splitTask(taskId, chunksMinutes): return "split-\(taskId)-\(chunksMinutes)"
        case let .addFocusBlock(date, durationMinutes, title): return "block-\(title)-\(date.timeIntervalSince1970)-\(durationMinutes)"
        }
    }
    case createBreak(beforeTaskId: UUID, minutes: Int)
    case moveTask(taskId: UUID, toStart: Date)
    case splitTask(taskId: UUID, chunksMinutes: [Int])
    case addFocusBlock(date: Date, durationMinutes: Int, title: String)
}

enum TimeOfDay: String, CaseIterable {
    case earlyMorning = "earlyMorning" // 6-9 AM
    case lateMorning = "lateMorning"   // 9-12 PM
    case earlyAfternoon = "earlyAfternoon" // 12-3 PM
    case lateAfternoon = "lateAfternoon"   // 3-6 PM
    case evening = "evening"               // 6-9 PM
    case night = "night"                   // 9+ PM
    
    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<9: return .earlyMorning
        case 9..<12: return .lateMorning
        case 12..<15: return .earlyAfternoon
        case 15..<18: return .lateAfternoon
        case 18..<21: return .evening
        default: return .night
        }
    }
    
    var displayName: String {
        switch self {
        case .earlyMorning: return NSLocalizedString("early_morning", comment: "Early morning time period")
        case .lateMorning: return NSLocalizedString("late_morning", comment: "Late morning time period")
        case .earlyAfternoon: return NSLocalizedString("early_afternoon", comment: "Early afternoon time period")
        case .lateAfternoon: return NSLocalizedString("late_afternoon", comment: "Late afternoon time period")
        case .evening: return NSLocalizedString("evening", comment: "Evening time period")
        case .night: return NSLocalizedString("night", comment: "Night time period")
        }
    }
    
    var timeRange: String {
        switch self {
        case .earlyMorning: return NSLocalizedString("time_6_9_am", comment: "6-9 AM time range")
        case .lateMorning: return NSLocalizedString("time_9_am_12_pm", comment: "9 AM-12 PM time range")
        case .earlyAfternoon: return NSLocalizedString("time_12_3_pm", comment: "12-3 PM time range")
        case .lateAfternoon: return NSLocalizedString("time_3_6_pm", comment: "3-6 PM time range")
        case .evening: return NSLocalizedString("time_6_9_pm", comment: "6-9 PM time range")
        case .night: return NSLocalizedString("time_9_plus_pm", comment: "9+ PM time range")
        }
    }
}

enum DurationCategory: String, CaseIterable {
    case short = "short"       // 15-30 min
    case medium = "medium"     // 30-60 min
    case long = "long"         // 60-120 min
    case extended = "extended" // 120+ min
    
    static func from(minutes: Int) -> DurationCategory {
        switch minutes {
        case 0..<30: return .short
        case 30..<60: return .medium
        case 60..<120: return .long
        default: return .extended
        }
    }
    
    var displayName: String {
        switch self {
        case .short: return NSLocalizedString("short_15_30_min", comment: "Short duration 15-30 min")
        case .medium: return NSLocalizedString("medium_30_60_min", comment: "Medium duration 30-60 min")
        case .long: return NSLocalizedString("long_1_2_hour", comment: "Long duration 1-2 hour")
        case .extended: return NSLocalizedString("extended_2_plus_hour", comment: "Extended duration 2+ hour")
        }
    }
    
    var suggestedDuration: String {
        switch self {
        case .short: return "25"
        case .medium: return "45"
        case .long: return "90"
        case .extended: return "120"
        }
    }
}

struct TimeSlotMetrics {
    let taskCount: Int
    let averageCompletionRate: Double
    let totalMinutes: Int
}

// MARK: - Array Extensions for Analytics

extension Array where Element == Task {
    var averageCompletionRate: Double {
        guard !isEmpty else { return 0 }
        let completedCount = filter(\.isCompleted).count
        return Double(completedCount) / Double(count)
    }
}

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
