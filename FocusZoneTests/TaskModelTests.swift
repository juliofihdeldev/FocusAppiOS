import Testing
import SwiftUI
import Foundation
@testable import FocusZone

struct TaskModelTests {
    
    // MARK: - Task Creation Tests
    
    @Test func testTaskInitialization() async throws {
        let task = Task(
            title: "Test Task",
            icon: "📚",
            startTime: Date(),
            durationMinutes: 60,
            color: .blue
        )
        
        #expect(task.title == "Test Task")
        #expect(task.icon == "📚")
        #expect(task.durationMinutes == 60)
        #expect(task.isCompleted == false)
        #expect(task.statusRawValue == TaskStatus.scheduled.rawValue)
        #expect(task.repeatRuleRawValue == RepeatRule.none.rawValue)
    }
    
    @Test func testTaskWithCustomValues() async throws {
        let customDate = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15, hour: 10, minute: 30))!
        let task = Task(
            title: "Custom Task",
            icon: "🎯",
            startTime: customDate,
            durationMinutes: 90,
            color: .red,
            isCompleted: true,
            status: .completed,
            repeatRule: .daily
        )
        
        #expect(task.title == "Custom Task")
        #expect(task.icon == "🎯")
        #expect(task.startTime == customDate)
        #expect(task.durationMinutes == 90)
        #expect(task.isCompleted == true)
        #expect(task.statusRawValue == TaskStatus.completed.rawValue)
        #expect(task.repeatRuleRawValue == RepeatRule.daily.rawValue)
    }
    
    // MARK: - Task Properties Tests
    
    @Test func testTaskStatus() async throws {
        let task = Task(
            title: "Status Test Task",
            icon: "📊",
            startTime: Date(),
            durationMinutes: 30
        )
        
        // Test default status
        #expect(task.statusRawValue == TaskStatus.scheduled.rawValue)
        
        // Test status change
        task.statusRawValue = TaskStatus.inProgress.rawValue
        #expect(task.statusRawValue == TaskStatus.inProgress.rawValue)
    }
    
    @Test func testTaskRepeatRule() async throws {
        let task = Task(
            title: "Repeat Test Task",
            icon: "🔄",
            startTime: Date(),
            durationMinutes: 45,
            repeatRule: .weekly
        )
        
        #expect(task.repeatRuleRawValue == RepeatRule.weekly.rawValue)
        
        // Test repeat rule change
        task.repeatRuleRawValue = RepeatRule.monthly.rawValue
        #expect(task.repeatRuleRawValue == RepeatRule.monthly.rawValue)
    }
    
    @Test func testTaskColor() async throws {
        let task = Task(
            title: "Color Test Task",
            icon: "🎨",
            startTime: Date(),
            durationMinutes: 30,
            color: .green
        )
        
        #expect(task.color == .green)
        #expect(task.colorHex == Color.green.toHex())
        
        // Test color change
        task.color = .purple
        #expect(task.color == .purple)
        #expect(task.colorHex == Color.purple.toHex())
    }
    
    // MARK: - Task Relationships Tests
    
    @Test func testTaskParentChildRelationship() async throws {
        let parentTask = Task(
            title: "Parent Task",
            icon: "👨‍👩‍👧‍👦",
            startTime: Date(),
            durationMinutes: 120
        )
        
        let childTask = Task(
            title: "Child Task",
            icon: "👶",
            startTime: Date(),
            durationMinutes: 30,
            parentTaskId: parentTask.id,
            parentTask: parentTask
        )
        
        #expect(childTask.parentTaskId == parentTask.id)
        #expect(childTask.parentTask == parentTask)
        #expect(childTask.isGeneratedFromRepeat == false)
    }
    
    @Test func testVirtualTaskCreation() async throws {
        let originalTask = Task(
            title: "Original Task",
            icon: "📝",
            startTime: Date(),
            durationMinutes: 60,
            repeatRule: .daily
        )
        
        let virtualTask = Task(
            title: "Virtual Task",
            icon: "👻",
            startTime: Date(),
            durationMinutes: 60,
            isGeneratedFromRepeat: true,
            parentTaskId: originalTask.id
        )
        
        #expect(virtualTask.isGeneratedFromRepeat == true)
        #expect(virtualTask.parentTaskId == originalTask.id)
    }
    
    // MARK: - Task Computed Properties Tests
    
    @Test func testTaskFocusSettings() async throws {
        let task = Task(
            title: "Focus Settings Task",
            icon: "🎯",
            startTime: Date(),
            durationMinutes: 45
        )
        
        let focusSettings = FocusSettings(
            focusMode: .work,
            breakDuration: 5,
            longBreakDuration: 15,
            sessionsUntilLongBreak: 4
        )
        
        // Test setting focus settings
        task.focusSettings = focusSettings
        #expect(task.focusSettings != nil)
        #expect(task.focusSettings?.focusMode == .work)
        #expect(task.focusSettings?.breakDuration == 5)
        
        // Test clearing focus settings
        task.focusSettings = nil
        #expect(task.focusSettings == nil)
    }
    
    @Test func testTaskTimestamps() async throws {
        let task = Task(
            title: "Timestamp Test Task",
            icon: "⏰",
            startTime: Date(),
            durationMinutes: 30
        )
        
        // Test that timestamps are set
        #expect(task.createdAt != Date.distantPast)
        #expect(task.updatedAt != Date.distantPast)
        
        // Test that updatedAt changes when properties change
        let originalUpdatedAt = task.updatedAt
        Thread.sleep(forTimeInterval: 0.1) // Small delay to ensure different timestamp
        
        task.title = "Updated Title"
        #expect(task.updatedAt > originalUpdatedAt)
    }
    
    // MARK: - Task Validation Tests
    
    @Test func testTaskWithEmptyTitle() async throws {
        let task = Task(
            title: "",
            icon: "📝",
            startTime: Date(),
            durationMinutes: 30
        )
        
        #expect(task.title.isEmpty)
        #expect(task.icon == "📝")
        #expect(task.durationMinutes == 30)
    }
    
    @Test func testTaskWithZeroDuration() async throws {
        let task = Task(
            title: "Zero Duration Task",
            icon: "⚠️",
            startTime: Date(),
            durationMinutes: 0
        )
        
        #expect(task.durationMinutes == 0)
        #expect(task.title == "Zero Duration Task")
    }
    
    @Test func testTaskWithPastStartTime() async throws {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let task = Task(
            title: "Past Task",
            icon: "📅",
            startTime: pastDate,
            durationMinutes: 60
        )
        
        #expect(task.startTime < Date())
        #expect(task.title == "Past Task")
    }
    
    // MARK: - Task Status Transitions Tests
    
    @Test func testTaskStatusTransitions() async throws {
        let task = Task(
            title: "Status Transition Task",
            icon: "🔄",
            startTime: Date(),
            durationMinutes: 45
        )
        
        // Test status transitions
        #expect(task.statusRawValue == TaskStatus.scheduled.rawValue)
        
        // Start the task
        task.statusRawValue = TaskStatus.inProgress.rawValue
        task.actualStartTime = Date()
        #expect(task.statusRawValue == TaskStatus.inProgress.rawValue)
        #expect(task.actualStartTime != nil)
        
        // Complete the task
        task.statusRawValue = TaskStatus.completed.rawValue
        task.isCompleted = true
        #expect(task.statusRawValue == TaskStatus.completed.rawValue)
        #expect(task.isCompleted == true)
    }
    
    @Test func testTaskCancellation() async throws {
        let task = Task(
            title: "Cancellable Task",
            icon: "❌",
            startTime: Date(),
            durationMinutes: 60
        )
        
        // Cancel the task
        task.statusRawValue = TaskStatus.cancelled.rawValue
        #expect(task.statusRawValue == TaskStatus.cancelled.rawValue)
    }
}
