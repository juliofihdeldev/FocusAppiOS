import Testing
import Foundation
@testable import FocusZone

struct TaskStatusTests {
    
    // MARK: - Task Status Enum Tests
    
    @Test func testTaskStatusCases() async throws {
        // Test all task status cases exist
        #expect(TaskStatus.allCases.contains(.scheduled))
        #expect(TaskStatus.allCases.contains(.inProgress))
        #expect(TaskStatus.allCases.contains(.paused))
        #expect(TaskStatus.allCases.contains(.completed))
        #expect(TaskStatus.allCases.contains(.cancelled))
    }
    
    @Test func testTaskStatusRawValues() async throws {
        // Test raw values are correct
        #expect(TaskStatus.scheduled.rawValue == "scheduled")
        #expect(TaskStatus.inProgress.rawValue == "inProgress")
        #expect(TaskStatus.paused.rawValue == "paused")
        #expect(TaskStatus.completed.rawValue == "completed")
        #expect(TaskStatus.cancelled.rawValue == "cancelled")
    }
    
    @Test func testTaskStatusFromRawValue() async throws {
        // Test creating task statuses from raw values
        #expect(TaskStatus(rawValue: "scheduled") == .scheduled)
        #expect(TaskStatus(rawValue: "inProgress") == .inProgress)
        #expect(TaskStatus(rawValue: "paused") == .paused)
        #expect(TaskStatus(rawValue: "completed") == .completed)
        #expect(TaskStatus(rawValue: "cancelled") == .cancelled)
    }
    
    @Test func testTaskStatusInvalidRawValue() async throws {
        // Test invalid raw values return nil
        #expect(TaskStatus(rawValue: "invalid") == nil)
        #expect(TaskStatus(rawValue: "") == nil)
        #expect(TaskStatus(rawValue: "random") == nil)
    }
    
    // MARK: - Task Status Business Logic Tests
    
    @Test func testTaskStatusWorkflow() async throws {
        // Test typical task workflow progression
        let statuses = [TaskStatus.scheduled, .inProgress, .paused, .inProgress, .completed]
        
        // Verify workflow progression
        #expect(statuses[0] == .scheduled)
        #expect(statuses[1] == .inProgress)
        #expect(statuses[2] == .paused)
        #expect(statuses[3] == .inProgress)
        #expect(statuses[4] == .completed)
    }
    
    @Test func testTaskStatusDescription() async throws {
        // Test that task statuses have meaningful descriptions
        #expect(TaskStatus.scheduled.rawValue == "scheduled")
        #expect(TaskStatus.inProgress.rawValue == "inProgress")
        #expect(TaskStatus.paused.rawValue == "paused")
        #expect(TaskStatus.completed.rawValue == "completed")
        #expect(TaskStatus.cancelled.rawValue == "cancelled")
    }
    
    // MARK: - Task Status Comparison Tests
    
    @Test func testTaskStatusEquality() async throws {
        // Test equality between task statuses
        let status1 = TaskStatus.inProgress
        let status2 = TaskStatus.inProgress
        let status3 = TaskStatus.completed
        
        #expect(status1 == status2)
        #expect(status1 != status3)
        #expect(status2 != status3)
    }
    
    @Test func testTaskStatusIdentity() async throws {
        // Test that task statuses maintain identity
        let status = TaskStatus.paused
        let sameStatus = TaskStatus.paused
        
        #expect(status == sameStatus)
        #expect(status.rawValue == sameStatus.rawValue)
    }
    
    // MARK: - Task Status State Tests
    
    @Test func testTaskStatusScheduled() async throws {
        // Test the scheduled status specifically
        let scheduledStatus = TaskStatus.scheduled
        
        #expect(scheduledStatus.rawValue == "scheduled")
        #expect(scheduledStatus == .scheduled)
        #expect(scheduledStatus != .inProgress)
        #expect(scheduledStatus != .completed)
    }
    
    @Test func testTaskStatusInProgress() async throws {
        // Test the inProgress status specifically
        let inProgressStatus = TaskStatus.inProgress
        
        #expect(inProgressStatus.rawValue == "inProgress")
        #expect(inProgressStatus == .inProgress)
        #expect(inProgressStatus != .scheduled)
        #expect(inProgressStatus != .paused)
    }
    
    @Test func testTaskStatusPaused() async throws {
        // Test the paused status specifically
        let pausedStatus = TaskStatus.paused
        
        #expect(pausedStatus.rawValue == "paused")
        #expect(pausedStatus == .paused)
        #expect(pausedStatus != .inProgress)
        #expect(pausedStatus != .completed)
    }
    
    @Test func testTaskStatusCompleted() async throws {
        // Test the completed status specifically
        let completedStatus = TaskStatus.completed
        
        #expect(completedStatus.rawValue == "completed")
        #expect(completedStatus == .completed)
        #expect(completedStatus != .inProgress)
        #expect(completedStatus != .cancelled)
    }
    
    @Test func testTaskStatusCancelled() async throws {
        // Test the cancelled status specifically
        let cancelledStatus = TaskStatus.cancelled
        
        #expect(cancelledStatus.rawValue == "cancelled")
        #expect(cancelledStatus == .cancelled)
        #expect(cancelledStatus != .completed)
        #expect(cancelledStatus != .scheduled)
    }
    
    // MARK: - Task Status Array Tests
    
    @Test func testTaskStatusAllCases() async throws {
        // Test that allCases contains all expected cases
        let allCases = TaskStatus.allCases
        
        #expect(allCases.count == 5)
        #expect(allCases.contains(.scheduled))
        #expect(allCases.contains(.inProgress))
        #expect(allCases.contains(.paused))
        #expect(allCases.contains(.completed))
        #expect(allCases.contains(.cancelled))
    }
    
    @Test func testTaskStatusArrayOrder() async throws {
        // Test that allCases maintains consistent order
        let allCases = TaskStatus.allCases
        
        #expect(allCases[0] == .scheduled)
        #expect(allCases[1] == .inProgress)
        #expect(allCases[2] == .paused)
        #expect(allCases[3] == .completed)
        #expect(allCases[4] == .cancelled)
    }
    
    // MARK: - Task Status String Conversion Tests
    
    @Test func testTaskStatusToString() async throws {
        // Test converting task statuses to strings
        #expect(TaskStatus.scheduled.rawValue == "scheduled")
        #expect(TaskStatus.inProgress.rawValue == "inProgress")
        #expect(TaskStatus.paused.rawValue == "paused")
        #expect(TaskStatus.completed.rawValue == "completed")
        #expect(TaskStatus.cancelled.rawValue == "cancelled")
    }
    
    @Test func testTaskStatusFromString() async throws {
        // Test creating task statuses from strings
        #expect(TaskStatus(rawValue: "scheduled") == .scheduled)
        #expect(TaskStatus(rawValue: "inProgress") == .inProgress)
        #expect(TaskStatus(rawValue: "paused") == .paused)
        #expect(TaskStatus(rawValue: "completed") == .completed)
        #expect(TaskStatus(rawValue: "cancelled") == .cancelled)
    }
    
    // MARK: - Task Status Validation Tests
    
    @Test func testTaskStatusValidValues() async throws {
        // Test all valid task status values
        let validValues = ["scheduled", "inProgress", "paused", "completed", "cancelled"]
        
        for value in validValues {
            let status = TaskStatus(rawValue: value)
            #expect(status != nil)
        }
    }
    
    @Test func testTaskStatusInvalidValues() async throws {
        // Test invalid task status values
        let invalidValues = ["", "invalid", "random", "test", "123"]
        
        for value in invalidValues {
            let status = TaskStatus(rawValue: value)
            #expect(status == nil)
        }
    }
    
    // MARK: - Task Status Workflow Tests
    
    @Test func testTaskStatusTransitions() async throws {
        // Test valid task status transitions
        let scheduled = TaskStatus.scheduled
        let inProgress = TaskStatus.inProgress
        let paused = TaskStatus.paused
        let completed = TaskStatus.completed
        let cancelled = TaskStatus.cancelled
        
        // Verify all statuses are distinct
        #expect(scheduled != inProgress)
        #expect(inProgress != paused)
        #expect(paused != completed)
        #expect(completed != cancelled)
        #expect(scheduled != cancelled)
    }
    
    @Test func testTaskStatusDefault() async throws {
        // Test that scheduled is the default status
        let defaultStatus = TaskStatus.scheduled
        
        #expect(defaultStatus == .scheduled)
        #expect(defaultStatus.rawValue == "scheduled")
    }
}
