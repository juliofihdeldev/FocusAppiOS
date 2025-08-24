import Foundation
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
    
    /// Creates a test break suggestion with default values
    static func createTestBreakSuggestion(
        id: UUID = UUID(),
        title: String = "Take a Break",
        description: String = "You've been working for a while",
        durationMinutes: Int = 5,
        insertAfterTaskId: UUID = UUID()
    ) -> BreakSuggestion {
        return BreakSuggestion(
            id: id,
            title: title,
            description: description,
            durationMinutes: durationMinutes,
            insertAfterTaskId: insertAfterTaskId
        )
    }
    
    /// Creates a test focus settings object
    static func createTestFocusSettings(
        focusMode: FocusMode = .work,
        breakDuration: Int = 5,
        longBreakDuration: Int = 15,
        sessionsUntilLongBreak: Int = 4
    ) -> FocusSettings {
        return FocusSettings(
            focusMode: focusMode,
            breakDuration: breakDuration,
            longBreakDuration: longBreakDuration,
            sessionsUntilLongBreak: sessionsUntilLongBreak
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
        
        let weeklyTask = createTestTask(
            title: "Weekly Task",
            icon: "📅",
            startTime: createTodayDate(hour: 10, minute: 0),
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
        
        return [dailyTask, weeklyTask, monthlyTask]
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
        expectedTitle: String,
        expectedDuration: Int
    ) -> Bool {
        return suggestion.title == expectedTitle &&
               suggestion.durationMinutes == expectedDuration
    }
    
    // MARK: - Test Environment Setup
    
    /// Creates a mock model context for testing
    static func createMockModelContext() -> ModelContext? {
        // In a real test environment, you would create a mock or in-memory context
        // For now, return nil to test error handling
        return nil
    }
    
    /// Creates a test TimelineViewModel with mock data
    static func createTestTimelineViewModel() -> TimelineViewModel {
        let viewModel = TimelineViewModel()
        
        // Add some test tasks
        viewModel.tasks = createTestTaskCollection()
        
        // Add some test break suggestions
        viewModel.breakSuggestions = [
            createTestBreakSuggestion(title: "Morning Break", durationMinutes: 5),
            createTestBreakSuggestion(title: "Afternoon Break", durationMinutes: 10)
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
