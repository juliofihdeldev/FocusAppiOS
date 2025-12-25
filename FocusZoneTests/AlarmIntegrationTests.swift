import Foundation
import SwiftData
import XCTest
@testable import FocusZone

class AlarmIntegrationTests: XCTestCase {
    
    func testTaskAlarmCreation() {
        // Test creating a task with alarm enabled
        let task = Task(
            title: "Test Task",
            icon: "📝",
            startTime: Date().addingTimeInterval(3600), // 1 hour from now
            durationMinutes: 30,
            alarmEnabled: true
        )
        
        XCTAssertTrue(task.alarmEnabled)
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.durationMinutes, 30)
    }
    
    func testAlarmServiceInitialization() {
        let alarmService = AlarmService.shared
        XCTAssertNotNil(alarmService)
    }
    
    func testAlarmToggleSectionCreation() {
        let alarmService = AlarmService.shared
        let binding = Binding<Bool>(
            get: { false },
            set: { _ in }
        )
        
        // This should not crash
        let _ = AlarmToggleSection(
            alarmEnabled: binding,
            alarmService: alarmService
        )
    }
}
