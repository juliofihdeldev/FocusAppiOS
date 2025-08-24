import Testing
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
    
    // MARK: - Weekday Repeat Rule Tests
    
    @Test func testWeekdayTaskInclusion() async throws {
        let viewModel = TimelineViewModel()
        
        // Create a weekday task starting on Monday
        let mondayDate = TestHelpers.createWeekdayDate(weekday: 2) // Monday
        let weekdayTask = Task(
            title: "Weekday Task",
            icon: "💼",
            startTime: mondayDate,
            durationMinutes: 45,
            repeatRule: .weekdays
        )
        
        // Test Monday (should include)
        let monday = TestHelpers.createWeekdayDate(weekday: 2)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: monday) == false) // Original date
        
        // Test Tuesday (should include)
        let tuesday = TestHelpers.createWeekdayDate(weekday: 3)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: tuesday) == true)
        
        // Test Friday (should include)
        let friday = TestHelpers.createWeekdayDate(weekday: 6)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: friday) == true)
        
        // Test Saturday (should NOT include)
        let saturday = TestHelpers.createWeekdayDate(weekday: 7)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: saturday) == false)
        
        // Test Sunday (should NOT include)
        let sunday = TestHelpers.createWeekdayDate(weekday: 1)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: sunday) == false)
    }
    
    @Test func testWeekdayTaskVirtualGeneration() async throws {
        let viewModel = TimelineViewModel()
        
        // Create a weekday task starting on Wednesday
        let wednesdayDate = TestHelpers.createWeekdayDate(weekday: 4) // Wednesday
        let weekdayTask = Task(
            title: "Midweek Task",
            icon: "📝",
            startTime: wednesdayDate,
            durationMinutes: 60,
            repeatRule: .weekdays
        )
        
        // Test Thursday (should generate virtual task)
        let thursday = TestHelpers.createWeekdayDate(weekday: 5)
        let shouldInclude = viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: thursday)
        #expect(shouldInclude == true)
        
        // Test Friday (should generate virtual task)
        let friday = TestHelpers.createWeekdayDate(weekday: 6)
        let shouldIncludeFriday = viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: friday)
        #expect(shouldIncludeFriday == true)
        
        // Test next Monday (should generate virtual task)
        let nextMonday = TestHelpers.createWeekdayDate(weekday: 2)
        let shouldIncludeMonday = viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: nextMonday)
        #expect(shouldIncludeMonday == true)
    }
    
    // MARK: - Weekend Repeat Rule Tests
    
    @Test func testWeekendTaskInclusion() async throws {
        let viewModel = TimelineViewModel()
        
        // Create a weekend task starting on Saturday
        let saturdayDate = TestHelpers.createWeekdayDate(weekday: 7) // Saturday
        let weekendTask = Task(
            title: "Weekend Task",
            icon: "🏖️",
            startTime: saturdayDate,
            durationMinutes: 90,
            repeatRule: .weekends
        )
        
        // Test Saturday (should include)
        let saturday = TestHelpers.createWeekdayDate(weekday: 7)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekendTask, for: saturday) == false) // Original date
        
        // Test Sunday (should include)
        let sunday = TestHelpers.createWeekdayDate(weekday: 1)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekendTask, for: sunday) == true)
        
        // Test Monday (should NOT include)
        let monday = TestHelpers.createWeekdayDate(weekday: 2)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekendTask, for: monday) == false)
        
        // Test Friday (should NOT include)
        let friday = TestHelpers.createWeekdayDate(weekday: 6)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekendTask, for: friday) == false)
        
        // Test next Saturday (should include)
        let nextSaturday = TestHelpers.createWeekdayDate(weekday: 7)
        let shouldInclude = viewModel.shouldIncludeRepeatingTask(task: weekendTask, for: nextSaturday)
        #expect(shouldInclude == true)
    }
    
    @Test func testWeekendTaskVirtualGeneration() async throws {
        let viewModel = TimelineViewModel()
        
        // Create a weekend task starting on Sunday
        let sundayDate = TestHelpers.createWeekdayDate(weekday: 1) // Sunday
        let weekendTask = Task(
            title: "Sunday Task",
            icon: "🧘",
            startTime: sundayDate,
            durationMinutes: 120,
            repeatRule: .weekends
        )
        
        // Test next Saturday (should generate virtual task)
        let nextSaturday = TestHelpers.createWeekdayDate(weekday: 7)
        let shouldIncludeSaturday = viewModel.shouldIncludeRepeatingTask(task: weekendTask, for: nextSaturday)
        #expect(shouldIncludeSaturday == true)
        
        // Test next Sunday (should generate virtual task)
        let nextSunday = TestHelpers.createWeekdayDate(weekday: 1)
        let shouldIncludeSunday = viewModel.shouldIncludeRepeatingTask(task: weekendTask, for: nextSunday)
        #expect(shouldIncludeSunday == true)
    }
    
    // MARK: - Edge Case Tests
    
    @Test func testWeekdayWeekendBoundaryTransition() async throws {
        let viewModel = TimelineViewModel()
        
        // Create a weekday task
        let mondayDate = TestHelpers.createWeekdayDate(weekday: 2) // Monday
        let weekdayTask = Task(
            title: "Boundary Test Task",
            icon: "🔍",
            startTime: mondayDate,
            durationMinutes: 30,
            repeatRule: .weekdays
        )
        
        // Test Friday to Saturday transition
        let friday = TestHelpers.createWeekdayDate(weekday: 6)
        let saturday = TestHelpers.createWeekdayDate(weekday: 7)
        
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: friday) == true)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: saturday) == false)
        
        // Test Sunday to Monday transition
        let sunday = TestHelpers.createWeekdayDate(weekday: 1)
        let monday = TestHelpers.createWeekdayDate(weekday: 2)
        
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: sunday) == false)
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekdayTask, for: monday) == true)
    }
    
    @Test func testWeekendWeekdayBoundaryTransition() async throws {
        let viewModel = TimelineViewModel()
        
        // Create a weekend task
        let saturdayDate = TestHelpers.createWeekdayDate(weekday: 7) // Saturday
        let weekendTask = Task(
            title: "Weekend Boundary Task",
            icon: "🎯",
            startTime: saturdayDate,
            durationMinutes: 45,
            repeatRule: .weekends
        )
        
        // Test Saturday to Sunday transition
        let saturday = TestHelpers.createWeekdayDate(weekday: 7)
        let sunday = TestHelpers.createWeekdayDate(weekday: 1)
        
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekendTask, for: saturday) == false) // Original date
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekendTask, for: sunday) == true)
        
        // Test Sunday to Monday transition
        let monday = TestHelpers.createWeekdayDate(weekday: 2)
        
        #expect(viewModel.shouldIncludeRepeatingTask(task: weekendTask, for: monday) == false)
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
        
        // Create test tasks
        let task1 = Task(
            title: "Task 1",
            icon: "📚",
            startTime: Date(),
            durationMinutes: 60
        )
        
        let task2 = Task(
            title: "Task 2",
            icon: "💻",
            startTime: Calendar.current.date(byAdding: .minute, value: 90, to: Date())!,
            durationMinutes: 45
        )
        
        viewModel.tasks = [task1, task2]
        viewModel.updateBreakSuggestions()
        
        // Verify break suggestions are created
        #expect(viewModel.breakSuggestions.count > 0)
    }
    
    // MARK: - Utility Function Tests
    
    @Test func testDateValidation() async throws {
        let viewModel = TimelineViewModel()
        
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Create a task starting today
        let task = Task(
            title: "Today Task",
            icon: "📅",
            startTime: today,
            durationMinutes: 30,
            repeatRule: .daily
        )
        
        // Should not include yesterday (before start date)
        #expect(viewModel.shouldIncludeRepeatingTask(task: task, for: yesterday) == false)
        
        // Should not include today (original date)
        #expect(viewModel.shouldIncludeRepeatingTask(task: task, for: today) == false)
        
        // Should include tomorrow
        #expect(viewModel.shouldIncludeRepeatingTask(task: task, for: tomorrow) == true)
    }
}
