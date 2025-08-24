import Testing
import Foundation
@testable import FocusZone

struct BreakSuggestionTests {
    
    // MARK: - Break Suggestion Creation Tests
    
    @Test func testBreakSuggestionInitialization() async throws {
        let suggestion = BreakSuggestion(
            id: UUID(),
            title: "Take a Break",
            description: "You've been working for a while",
            durationMinutes: 5,
            insertAfterTaskId: UUID()
        )
        
        #expect(suggestion.title == "Take a Break")
        #expect(suggestion.description == "You've been working for a while")
        #expect(suggestion.durationMinutes == 5)
        #expect(suggestion.insertAfterTaskId != nil)
    }
    
    @Test func testBreakSuggestionWithCustomValues() async throws {
        let customId = UUID()
        let taskId = UUID()
        
        let suggestion = BreakSuggestion(
            id: customId,
            title: "Custom Break",
            description: "Custom break description",
            durationMinutes: 15,
            insertAfterTaskId: taskId
        )
        
        #expect(suggestion.id == customId)
        #expect(suggestion.title == "Custom Break")
        #expect(suggestion.description == "Custom break description")
        #expect(suggestion.durationMinutes == 15)
        #expect(suggestion.insertAfterTaskId == taskId)
    }
    
    // MARK: - Break Suggestion Properties Tests
    
    @Test func testBreakSuggestionDuration() async throws {
        let shortBreak = BreakSuggestion(
            id: UUID(),
            title: "Short Break",
            description: "Quick rest",
            durationMinutes: 2,
            insertAfterTaskId: UUID()
        )
        
        let longBreak = BreakSuggestion(
            id: UUID(),
            title: "Long Break",
            description: "Extended rest",
            durationMinutes: 30,
            insertAfterTaskId: UUID()
        )
        
        #expect(shortBreak.durationMinutes == 2)
        #expect(longBreak.durationMinutes == 30)
        #expect(shortBreak.durationMinutes < longBreak.durationMinutes)
    }
    
    @Test func testBreakSuggestionInsertion() async throws {
        let taskId = UUID()
        let suggestion = BreakSuggestion(
            id: UUID(),
            title: "Inserted Break",
            description: "Break after specific task",
            durationMinutes: 10,
            insertAfterTaskId: taskId
        )
        
        #expect(suggestion.insertAfterTaskId == taskId)
        #expect(suggestion.insertAfterTaskId != nil)
    }
    
    // MARK: - Break Suggestion Edge Cases Tests
    
    @Test func testBreakSuggestionWithZeroDuration() async throws {
        let suggestion = BreakSuggestion(
            id: UUID(),
            title: "Zero Duration Break",
            description: "Instant break",
            durationMinutes: 0,
            insertAfterTaskId: UUID()
        )
        
        #expect(suggestion.durationMinutes == 0)
        #expect(suggestion.title == "Zero Duration Break")
    }
    
    @Test func testBreakSuggestionWithLongDuration() async throws {
        let suggestion = BreakSuggestion(
            id: UUID(),
            title: "Long Break",
            description: "Extended rest period",
            durationMinutes: 120, // 2 hours
            insertAfterTaskId: UUID()
        )
        
        #expect(suggestion.durationMinutes == 120)
        #expect(suggestion.durationMinutes > 60)
    }
    
    @Test func testBreakSuggestionWithEmptyTitle() async throws {
        let suggestion = BreakSuggestion(
            id: UUID(),
            title: "",
            description: "Empty title break",
            durationMinutes: 5,
            insertAfterTaskId: UUID()
        )
        
        #expect(suggestion.title.isEmpty)
        #expect(suggestion.description == "Empty title break")
    }
    
    @Test func testBreakSuggestionWithEmptyDescription() async throws {
        let suggestion = BreakSuggestion(
            id: UUID(),
            title: "No Description",
            description: "",
            durationMinutes: 5,
            insertAfterTaskId: UUID()
        )
        
        #expect(suggestion.title == "No Description")
        #expect(suggestion.description.isEmpty)
    }
    
    // MARK: - Break Suggestion Validation Tests
    
    @Test func testBreakSuggestionIdUniqueness() async throws {
        let id1 = UUID()
        let id2 = UUID()
        
        let suggestion1 = BreakSuggestion(
            id: id1,
            title: "First Break",
            description: "First break suggestion",
            durationMinutes: 5,
            insertAfterTaskId: UUID()
        )
        
        let suggestion2 = BreakSuggestion(
            id: id2,
            title: "Second Break",
            description: "Second break suggestion",
            durationMinutes: 10,
            insertAfterTaskId: UUID()
        )
        
        #expect(suggestion1.id != suggestion2.id)
        #expect(suggestion1.id == id1)
        #expect(suggestion2.id == id2)
    }
    
    @Test func testBreakSuggestionTaskAssociation() async throws {
        let taskId1 = UUID()
        let taskId2 = UUID()
        
        let suggestion1 = BreakSuggestion(
            id: UUID(),
            title: "Break After Task 1",
            description: "Break after first task",
            durationMinutes: 5,
            insertAfterTaskId: taskId1
        )
        
        let suggestion2 = BreakSuggestion(
            id: UUID(),
            title: "Break After Task 2",
            description: "Break after second task",
            durationMinutes: 5,
            insertAfterTaskId: taskId2
        )
        
        #expect(suggestion1.insertAfterTaskId == taskId1)
        #expect(suggestion2.insertAfterTaskId == taskId2)
        #expect(suggestion1.insertAfterTaskId != suggestion2.insertAfterTaskId)
    }
    
    // MARK: - Break Suggestion Content Tests
    
    @Test func testBreakSuggestionTitleLength() async throws {
        let shortTitle = "Short"
        let longTitle = "This is a very long break suggestion title that might exceed normal limits"
        
        let shortSuggestion = BreakSuggestion(
            id: UUID(),
            title: shortTitle,
            description: "Short title break",
            durationMinutes: 5,
            insertAfterTaskId: UUID()
        )
        
        let longSuggestion = BreakSuggestion(
            id: UUID(),
            title: longTitle,
            description: "Long title break",
            durationMinutes: 5,
            insertAfterTaskId: UUID()
        )
        
        #expect(shortSuggestion.title.count < longSuggestion.title.count)
        #expect(shortSuggestion.title == shortTitle)
        #expect(longSuggestion.title == longTitle)
    }
    
    @Test func testBreakSuggestionDescriptionLength() async throws {
        let shortDesc = "Short description"
        let longDesc = "This is a very detailed description of the break suggestion that provides comprehensive information about why this break is recommended and what the user should do during this break period"
        
        let shortSuggestion = BreakSuggestion(
            id: UUID(),
            title: "Short Description Break",
            description: shortDesc,
            durationMinutes: 5,
            insertAfterTaskId: UUID()
        )
        
        let longSuggestion = BreakSuggestion(
            id: UUID(),
            title: "Long Description Break",
            description: longDesc,
            durationMinutes: 5,
            insertAfterTaskId: UUID()
        )
        
        #expect(shortSuggestion.description.count < longSuggestion.description.count)
        #expect(shortSuggestion.description == shortDesc)
        #expect(longSuggestion.description == longDesc)
    }
    
    // MARK: - Break Suggestion Business Logic Tests
    
    @Test func testBreakSuggestionDurationValidation() async throws {
        // Test various duration values
        let durations = [1, 5, 15, 30, 60, 120]
        
        for duration in durations {
            let suggestion = BreakSuggestion(
                id: UUID(),
                title: "Duration Test \(duration)",
                description: "Testing duration \(duration) minutes",
                durationMinutes: duration,
                insertAfterTaskId: UUID()
            )
            
            #expect(suggestion.durationMinutes == duration)
            #expect(suggestion.durationMinutes > 0)
        }
    }
    
    @Test func testBreakSuggestionInsertionOrder() async throws {
        let taskId1 = UUID()
        let taskId2 = UUID()
        
        let suggestion1 = BreakSuggestion(
            id: UUID(),
            title: "First Break",
            description: "Break after first task",
            durationMinutes: 5,
            insertAfterTaskId: taskId1
        )
        
        let suggestion2 = BreakSuggestion(
            id: UUID(),
            title: "Second Break",
            description: "Break after second task",
            durationMinutes: 10,
            insertAfterTaskId: taskId2
        )
        
        // Both suggestions should have valid insertion points
        #expect(suggestion1.insertAfterTaskId != nil)
        #expect(suggestion2.insertAfterTaskId != nil)
        #expect(suggestion1.insertAfterTaskId != suggestion2.insertAfterTaskId)
    }
}
