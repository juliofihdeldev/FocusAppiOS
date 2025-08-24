import Testing
import Foundation
@testable import FocusZone

struct BreakSuggestionTests {
    
    // MARK: - Break Suggestion Creation Tests
    
    @Test func testBreakSuggestionInitialization() async throws {
        let suggestion = BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: "Take a Break",
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        #expect(suggestion.reason == "Take a Break")
        #expect(suggestion.suggestedDuration == 5)
        #expect(suggestion.insertAfterTaskId != nil)
    }
    
    @Test func testBreakSuggestionWithCustomValues() async throws {
        let taskId = UUID()
        
        let suggestion = BreakSuggestion(
            type: .movement,
            suggestedDuration: 15,
            reason: "Custom Break",
            icon: "🚶",
            timeUntilOptimal: 10,
            insertAfterTaskId: taskId,
            suggestedStartTime: Date()
        )
        
        #expect(suggestion.reason == "Custom Break")
        #expect(suggestion.suggestedDuration == 15)
        #expect(suggestion.insertAfterTaskId == taskId)
    }
    
    // MARK: - Break Suggestion Properties Tests
    
    @Test func testBreakSuggestionDuration() async throws {
        let shortBreak = BreakSuggestion(
            type: .hydration,
            suggestedDuration: 2,
            reason: "Short Break",
            icon: "💧",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        let longBreak = BreakSuggestion(
            type: .rest,
            suggestedDuration: 30,
            reason: "Long Break",
            icon: "😌",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        #expect(shortBreak.suggestedDuration == 2)
        #expect(longBreak.suggestedDuration == 30)
        #expect(shortBreak.suggestedDuration < longBreak.suggestedDuration)
    }
    
    @Test func testBreakSuggestionInsertion() async throws {
        let taskId = UUID()
        let suggestion = BreakSuggestion(
            type: .snack,
            suggestedDuration: 10,
            reason: "Inserted Break",
            icon: "🍎",
            timeUntilOptimal: 0,
            insertAfterTaskId: taskId,
            suggestedStartTime: Date()
        )
        
        #expect(suggestion.insertAfterTaskId == taskId)
        #expect(suggestion.insertAfterTaskId != nil)
    }
    
    // MARK: - Break Suggestion Edge Cases Tests
    
    @Test func testBreakSuggestionWithZeroDuration() async throws {
        let suggestion = BreakSuggestion(
            type: .eye_rest,
            suggestedDuration: 0,
            reason: "Zero Duration Break",
            icon: "👁️",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        #expect(suggestion.suggestedDuration == 0)
        #expect(suggestion.reason == "Zero Duration Break")
    }
    
    @Test func testBreakSuggestionWithLongDuration() async throws {
        let suggestion = BreakSuggestion(
            type: .fresh_air,
            suggestedDuration: 60,
            reason: "Long Break",
            icon: "🌬️",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        #expect(suggestion.suggestedDuration == 60)
        #expect(suggestion.reason == "Long Break")
    }
    
    @Test func testBreakSuggestionWithEmptyTitle() async throws {
        let suggestion = BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: "",
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        #expect(suggestion.reason.isEmpty)
        #expect(suggestion.reason == "")
    }
    
    @Test func testBreakSuggestionWithEmptyDescription() async throws {
        let suggestion = BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: "",
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        #expect(suggestion.reason == "")
        #expect(suggestion.reason.isEmpty)
    }
    
    // MARK: - Break Suggestion Validation Tests
    
    @Test func testBreakSuggestionIdUniqueness() async throws {
        let suggestion1 = BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: "First Break",
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        let suggestion2 = BreakSuggestion(
            type: .rest,
            suggestedDuration: 10,
            reason: "Second Break",
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        // Test that IDs are unique (they should be since they're generated automatically)
        #expect(suggestion1.id != suggestion2.id)
        // Test that IDs are valid UUIDs
        #expect(suggestion1.id.uuidString.count > 0)
        #expect(suggestion2.id.uuidString.count > 0)
    }
    
    @Test func testBreakSuggestionTaskAssociation() async throws {
        let taskId1 = UUID()
        let taskId2 = UUID()
        
        let suggestion1 = BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: "Break After Task 1",
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: taskId1,
            suggestedStartTime: Date()
        )
        
        let suggestion2 = BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: "Break After Task 2",
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: taskId2,
            suggestedStartTime: Date()
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
            type: .rest,
            suggestedDuration: 5,
            reason: shortTitle,
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        let longSuggestion = BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: longTitle,
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        #expect(shortSuggestion.reason.count < longSuggestion.reason.count)
        #expect(shortSuggestion.reason == shortTitle)
        #expect(longSuggestion.reason == longTitle)
    }
    
    @Test func testBreakSuggestionDescriptionLength() async throws {
        let shortDesc = "Short description"
        let longDesc = "This is a very detailed description of the break suggestion that provides comprehensive information about why this break is recommended and what the user should do during this break period"
        
        let shortSuggestion = BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: shortDesc,
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        let longSuggestion = BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: longDesc,
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: UUID(),
            suggestedStartTime: Date()
        )
        
        #expect(shortSuggestion.reason.count < longSuggestion.reason.count)
        #expect(shortSuggestion.reason == shortDesc)
        #expect(longSuggestion.reason == longDesc)
    }
    
    // MARK: - Break Suggestion Business Logic Tests
    
    @Test func testBreakSuggestionDurationValidation() async throws {
        // Test various duration values
        let durations = [1, 5, 15, 30, 60, 120]
        
        for duration in durations {
            let suggestion = BreakSuggestion(
                type: .rest,
                suggestedDuration: duration,
                reason: "Duration Test \(duration)",
                icon: "⏱️",
                timeUntilOptimal: 0,
                insertAfterTaskId: UUID(),
                suggestedStartTime: Date()
            )
            
            #expect(suggestion.suggestedDuration == duration)
            #expect(suggestion.suggestedDuration > 0)
        }
    }
    
    @Test func testBreakSuggestionInsertionOrder() async throws {
        let taskId1 = UUID()
        let taskId2 = UUID()
        
        let suggestion1 = BreakSuggestion(
            type: .rest,
            suggestedDuration: 5,
            reason: "First Break",
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: taskId1,
            suggestedStartTime: Date()
        )
        
        let suggestion2 = BreakSuggestion(
            type: .rest,
            suggestedDuration: 10,
            reason: "Second Break",
            icon: "☕",
            timeUntilOptimal: 0,
            insertAfterTaskId: taskId2,
            suggestedStartTime: Date()
        )
        
        // Both suggestions should have valid insertion points
        #expect(suggestion1.insertAfterTaskId != nil)
        #expect(suggestion2.insertAfterTaskId != nil)
        #expect(suggestion1.insertAfterTaskId != suggestion2.insertAfterTaskId)
    }
}
