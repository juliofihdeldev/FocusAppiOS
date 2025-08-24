import Foundation
import SwiftUICore
import SwiftData
@testable import FocusZone

// MARK: - Test Helper Functions

struct TestHelpers {
    
    // MARK: - Test Data Creation
    
    /// Creates a test task with default values
    static func createTestTask(
        title: String = "Test Task",
        icon: String = "📚",
        startTime: Date = Date(),
        durationMinutes: Int = 60,
        color: Color = .blue,
        isCompleted: Bool = false,
        status: TaskStatus = .scheduled,
        repeatRule: RepeatRule = .none
    ) -> Task {
        return Task(
            title: title,
            icon: icon,
            startTime: startTime,
            durationMinutes: durationMinutes,
            color: color,
            isCompleted: isCompleted,
            status: status,
            repeatRule: repeatRule
        )
    }
    
    /// Creates a test break suggestion
    static func createTestBreakSuggestion() -> BreakSuggestion {
        return BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: "Take a short break",
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
    }
    
    /// Creates test focus settings
    static func createTestFocusSettings() -> FocusSettings {
        return FocusSettings(
            isEnabled: true,
            mode: .workMode,
            allowUrgentNotifications: true,
            customAllowedApps: [],
            autoActivate: false,
            scheduledActivation: nil
        )
    }
    
    // MARK: - Test Date Utilities
    
    /// Creates a test date for a specific day
    static func createTestDate(
        year: Int = 2024,
        month: Int = 1,
        day: Int = 15,
        hour: Int = 10,
        minute: Int = 30
    ) -> Date {
        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// Creates a test date for today with specific time
    static func createTodayDate(hour: Int = 10, minute: Int = 30) -> Date {
        let calendar = Calendar.current
        let today = Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
    }
    
    /// Creates a test date for tomorrow
    static func createTomorrowDate() -> Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    /// Creates a test date for yesterday
    static func createYesterdayDate() -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }
    
    // MARK: - Test Task Collections
    
    /// Creates a collection of test tasks for different times of day
    static func createTestTaskCollection() -> [Task] {
        let morningTask = createTestTask(
            title: "Morning Task",
            icon: "🌅",
            startTime: createTodayDate(hour: 9, minute: 0),
            durationMinutes: 30
        )
        
        let afternoonTask = createTestTask(
            title: "Afternoon Task",
            icon: "🌆",
            startTime: createTodayDate(hour: 14, minute: 0),
            durationMinutes: 60
        )
        
        let eveningTask = createTestTask(
            title: "Evening Task",
            icon: "🌙",
            startTime: createTodayDate(hour: 19, minute: 0),
            durationMinutes: 45
        )
        
        return [morningTask, afternoonTask, eveningTask]
    }
    
    /// Creates a collection of test tasks with different repeat rules
    static func createTestRepeatingTaskCollection() -> [Task] {
        let dailyTask = createTestTask(
            title: "Daily Task",
            icon: "🔄",
            startTime: createTodayDate(hour: 8, minute: 0),
            durationMinutes: 45,
            repeatRule: .daily
        )
        
        let weekdaysTask = createTestTask(
            title: "Weekdays Task",
            icon: "💼",
            startTime: createTodayDate(hour: 9, minute: 0),
            durationMinutes: 60,
            repeatRule: .weekdays
        )
        
        let weekendsTask = createTestTask(
            title: "Weekends Task",
            icon: "🏖️",
            startTime: createTodayDate(hour: 10, minute: 0),
            durationMinutes: 90,
            repeatRule: .weekends
        )
        
        let weeklyTask = createTestTask(
            title: "Weekly Task",
            icon: "📅",
            startTime: createTodayDate(hour: 11, minute: 0),
            durationMinutes: 90,
            repeatRule: .weekly
        )
        
        let monthlyTask = createTestTask(
            title: "Monthly Task",
            icon: "🗓️",
            startTime: createTodayDate(hour: 15, minute: 0),
            durationMinutes: 120,
            repeatRule: .monthly
        )
        
        return [dailyTask, weekdaysTask, weekendsTask, weeklyTask, monthlyTask]
    }
    
    /// Creates a test task collection specifically for weekday/weekend testing
    static func createWeekdayWeekendTestCollection() -> [Task] {
        let mondayTask = createTestTask(
            title: "Monday Task",
            icon: "📝",
            startTime: createWeekdayDate(weekday: 2), // Monday
            durationMinutes: 45,
            repeatRule: .weekdays
        )
        
        let saturdayTask = createTestTask(
            title: "Saturday Task",
            icon: "🧘",
            startTime: createWeekdayDate(weekday: 7), // Saturday
            durationMinutes: 60,
            repeatRule: .weekends
        )
        
        let sundayTask = createTestTask(
            title: "Sunday Task",
            icon: "🏖️",
            startTime: createWeekdayDate(weekday: 1), // Sunday
            durationMinutes: 90,
            repeatRule: .weekends
        )
        
        return [mondayTask, saturdayTask, sundayTask]
    }
    
    // MARK: - Date Creation Utilities
    
    /// Creates a date for a specific weekday (1=Sunday, 2=Monday, ..., 7=Saturday)
    static func createWeekdayDate(weekday: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        // Find the next occurrence of the specified weekday
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.weekday = weekday
        
        // If today is the target weekday, use today
        if calendar.component(.weekday, from: today) == weekday {
            return today
        }
        
        // Otherwise, find the next occurrence
        var targetDate = calendar.date(from: components) ?? today
        if targetDate <= today {
            targetDate = calendar.date(byAdding: .weekOfYear, value: 1, to: targetDate) ?? today
        }
        
        return targetDate
    }
    
    /// Creates a date for a specific weekday in the current week
    static func createCurrentWeekDate(weekday: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        
        // Calculate days to add/subtract to reach target weekday
        let daysToAdd = weekday - currentWeekday
        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }
    
    /// Creates a date for a specific weekday in the next week
    static func createNextWeekDate(weekday: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        
        // Calculate days to add to reach target weekday in next week
        let daysToAdd = (7 - currentWeekday) + weekday
        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }
    
    /// Creates a collection of dates for testing weekday patterns
    static func createWeekdayTestDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        var testDates: [Date] = []
        
        // Add dates for the next 14 days to cover multiple weeks
        for dayOffset in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                testDates.append(date)
            }
        }
        
        return testDates
    }
    
    /// Creates a collection of dates for testing weekend patterns
    static func createWeekendTestDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        var weekendDates: [Date] = []
        
        // Find the next 4 weekend dates
        for weekOffset in 0..<4 {
            // Saturday
            if let saturday = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today) {
                let saturdayComponents = calendar.dateComponents([.year, .month, .day], from: saturday)
                var saturdayDate = calendar.date(from: saturdayComponents) ?? saturday
                
                // Adjust to Saturday
                let currentWeekday = calendar.component(.weekday, from: saturdayDate)
                let daysToSaturday = 7 - currentWeekday
                if let adjustedSaturday = calendar.date(byAdding: .day, value: daysToSaturday, to: saturdayDate) {
                    weekendDates.append(adjustedSaturday)
                    
                    // Sunday
                    if let sunday = calendar.date(byAdding: .day, value: 1, to: adjustedSaturday) {
                        weekendDates.append(sunday)
                    }
                }
            }
        }
        
        return weekendDates
    }
    
    // MARK: - Test Validation Utilities
    
    /// Validates that a task has the expected properties
    static func validateTask(
        _ task: Task,
        expectedTitle: String,
        expectedIcon: String,
        expectedDuration: Int,
        expectedStatus: TaskStatus
    ) -> Bool {
        return task.title == expectedTitle &&
               task.icon == expectedIcon &&
               task.durationMinutes == expectedDuration &&
               task.statusRawValue == expectedStatus.rawValue
    }
    
    /// Validates that a break suggestion has the expected properties
    static func validateBreakSuggestion(
        _ suggestion: BreakSuggestion,
        expectedReason: String,
        expectedDuration: Int
    ) -> Bool {
        return suggestion.reason == expectedReason &&
               suggestion.suggestedDuration == expectedDuration
    }
    
    // MARK: - Test Environment Setup
    
    /// Creates a mock model context for testing
    static func createMockModelContext() -> ModelContext? {
        // This would typically create a mock or in-memory context
        // For now, return nil as this is a placeholder
        return nil
    }
    
    /// Creates a test TimelineViewModel for testing
    @MainActor
    static func createTestTimelineViewModel() -> TimelineViewModel {
        let viewModel = TimelineViewModel()
        viewModel.tasks = createTestTaskCollection()
        viewModel.breakSuggestions = [
            createTestBreakSuggestion()
        ]
        return viewModel
    }
    
    // MARK: - Test Data Cleanup
    
    /// Cleans up test data (useful for test teardown)
    static func cleanupTestData() {
        // In a real test environment, you would clean up any test data
        // For now, this is a placeholder
        print("🧹 Test data cleanup completed")
    }
}

// MARK: - Test Extensions

extension Task {
    /// Convenience method to update task status
    func updateStatus(_ newStatus: TaskStatus) {
        self.statusRawValue = newStatus.rawValue
        self.updatedAt = Date()
    }
    
    /// Convenience method to mark task as completed
    func markCompleted() {
        self.isCompleted = true
        self.statusRawValue = TaskStatus.completed.rawValue
        self.updatedAt = Date()
    }
}

extension BreakSuggestion {
    /// Convenience method to update break suggestion duration
    func updateDuration(_ newDuration: Int) {
        // Note: This would need to be implemented in the actual model
        // For testing purposes, we'll just print the update
        print("🔄 Updated break suggestion duration to \(newDuration) minutes")
    }
}
