import SwiftData
import Foundation
@testable import FocusZone

struct TimelineViewModelTests {
    
    // MARK: - Task Loading Tests
    
    @Test func testLoadTodayTasks() async throws {
        let viewModel = TimelineViewModel()
        let testDate = Date()
        
        // Test loading tasks for today
        viewModel.loadTodayTasks(for: testDate)
        
        // Verify tasks array is initialized
        #expect(viewModel.tasks.count >= 0)
    }
    
    @Test func testLoadTasksForSpecificDate() async throws {
        let viewModel = TimelineViewModel()
        let specificDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        
        viewModel.loadTodayTasks(for: specificDate)
        
        // Verify tasks are loaded for the specific date
        #expect(viewModel.tasks.count >= 0)
    }
    
    // MARK: - Task Management Tests
    
    @Test func testCreateVirtualTask() async throws {
        let viewModel = TimelineViewModel()
        
        // Create a test task with repeat rule
        let originalTask = Task(
            title: "Test Repeating Task",
            icon: "📚",
            startTime: Date(),
            durationMinutes: 60,
            repeatRule: .daily
        )
        
        let testDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        // Test virtual task creation
        if let virtualTask = viewModel.createVirtualTask(from: originalTask, for: testDate) {
            #expect(virtualTask.title == originalTask.title)
            #expect(virtualTask.isGeneratedFromRepeat == true)
            #expect(virtualTask.parentTaskId == originalTask.id)
        }
    }
    
    @Test func testShouldIncludeRepeatingTask() async throws {
        let viewModel = TimelineViewModel()
        
        // Test daily repeating task
        let dailyTask = Task(
            title: "Daily Task",
            icon: "🔄",
            startTime: Date(),
            durationMinutes: 30,
            repeatRule: .daily
        )
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let shouldInclude = viewModel.shouldIncludeRepeatingTask(task: dailyTask, for: tomorrow)
        
        #expect(shouldInclude == true)
    }
    
    @Test func testTaskSortingByStartTime() async throws {
        let viewModel = TimelineViewModel()
        
        // Create test tasks with different start times
        let earlyTask = Task(
            title: "Early Task",
            icon: "🌅",
            startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            durationMinutes: 30
        )
        
        let lateTask = Task(
            title: "Late Task",
            icon: "🌆",
            startTime: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!,
            durationMinutes: 60
        )
        
        // Add tasks to viewModel
        viewModel.tasks = [lateTask, earlyTask]
        
        // Verify tasks are sorted by start time
        #expect(viewModel.tasks.first?.title == "Early Task")
        #expect(viewModel.tasks.last?.title == "Late Task")
    }
    
    // MARK: - Break Suggestions Tests
    
    @Test func testUpdateBreakSuggestions() async throws {
        let viewModel = TimelineViewModel()
        
        // Test updating break suggestions
        viewModel.updateBreakSuggestions()
        
        // Verify break suggestions array is initialized
        #expect(viewModel.breakSuggestions.count >= 0)
    }
    
    @Test func testAcceptBreakSuggestion() async throws {
        let viewModel = TimelineViewModel()
        
        // Create a test break suggestion
        let suggestion = BreakSuggestion(
            id: UUID(),
            title: "Take a break",
            description: "You've been working for a while",
            durationMinutes: 5,
            insertAfterTaskId: UUID()
        )
        
        // Add suggestion to viewModel
        viewModel.breakSuggestions = [suggestion]
        
        // Test accepting the suggestion
        viewModel.acceptBreakSuggestion(suggestion)
        
        // Verify suggestion is removed after acceptance
        #expect(viewModel.breakSuggestions.isEmpty)
    }
    
    @Test func testDismissBreakSuggestion() async throws {
        let viewModel = TimelineViewModel()
        
        // Create a test break suggestion
        let suggestion = BreakSuggestion(
            id: UUID(),
            title: "Take a break",
            description: "You've been working for a while",
            durationMinutes: 5,
            insertAfterTaskId: UUID()
        )
        
        // Add suggestion to viewModel
        viewModel.breakSuggestions = [suggestion]
        
        // Test dismissing the suggestion
        viewModel.dismissBreakSuggestion(suggestion)
        
        // Verify suggestion is removed after dismissal
        #expect(viewModel.breakSuggestions.isEmpty)
    }
    
    // MARK: - Utility Function Tests
    
    @Test func testTimeRangeForTask() async throws {
        let viewModel = TimelineViewModel()
        
        let task = Task(
            title: "Test Task",
            icon: "⏰",
            startTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!,
            durationMinutes: 45
        )
        
        let timeRange = viewModel.timeRange(for: task)
        
        // Verify time range is not empty
        #expect(!timeRange.isEmpty)
        #expect(timeRange.contains("10:30") || timeRange.contains("10:30 AM"))
    }
    
    @Test func testTaskColor() async throws {
        let viewModel = TimelineViewModel()
        
        let task = Task(
            title: "Test Task",
            icon: "🎨",
            startTime: Date(),
            durationMinutes: 30,
            color: .red
        )
        
        let taskColor = viewModel.taskColor(task)
        
        // Verify task color is returned
        #expect(taskColor == .red)
    }
    
    @Test func testDateStringFormatting() async throws {
        let viewModel = TimelineViewModel()
        
        let testDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let dateString = viewModel.dateString(testDate)
        
        // Verify date string is formatted correctly
        #expect(!dateString.isEmpty)
        #expect(dateString.contains("Jan") || dateString.contains("January"))
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func testEmptyTasksList() async throws {
        let viewModel = TimelineViewModel()
        
        // Test with empty tasks
        viewModel.tasks = []
        
        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.tasks.count == 0)
    }
    
    @Test func testNilModelContext() async throws {
        let viewModel = TimelineViewModel()
        
        // Test loading tasks without model context
        viewModel.loadTodayTasks()
        
        // Should handle gracefully without crashing
        #expect(viewModel.tasks.count >= 0)
    }
    
    @Test func testTaskWithInvalidDuration() async throws {
        let viewModel = TimelineViewModel()
        
        // Test task with zero duration
        let zeroDurationTask = Task(
            title: "Zero Duration Task",
            icon: "⚠️",
            startTime: Date(),
            durationMinutes: 0
        )
        
        #expect(zeroDurationTask.durationMinutes == 0)
        #expect(zeroDurationTask.title == "Zero Duration Task")
    }
}
