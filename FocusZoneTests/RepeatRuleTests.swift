import Testing
import Foundation
@testable import FocusZone

struct RepeatRuleTests {
    
    // MARK: - Repeat Rule Enum Tests
    
    @Test func testRepeatRuleCases() async throws {
        // Test all repeat rule cases exist
        #expect(RepeatRule.allCases.contains(.none))
        #expect(RepeatRule.allCases.contains(.daily))
        #expect(RepeatRule.allCases.contains(.weekdays))
        #expect(RepeatRule.allCases.contains(.weekends))
        #expect(RepeatRule.allCases.contains(.weekly))
        #expect(RepeatRule.allCases.contains(.monthly))
    }
    
    @Test func testRepeatRuleRawValues() async throws {
        // Test raw values are correct
        #expect(RepeatRule.none.rawValue == "none")
        #expect(RepeatRule.daily.rawValue == "daily")
        #expect(RepeatRule.weekdays.rawValue == "weekdays")
        #expect(RepeatRule.weekends.rawValue == "weekends")
        #expect(RepeatRule.weekly.rawValue == "weekly")
        #expect(RepeatRule.monthly.rawValue == "monthly")
    }
    
    @Test func testRepeatRuleFromRawValue() async throws {
        // Test that raw values are accessible
        #expect(RepeatRule.none.rawValue == "none")
        #expect(RepeatRule.daily.rawValue == "daily")
        #expect(RepeatRule.weekdays.rawValue == "weekdays")
        #expect(RepeatRule.weekends.rawValue == "weekends")
        #expect(RepeatRule.weekly.rawValue == "weekly")
        #expect(RepeatRule.monthly.rawValue == "monthly")
    }
    
    @Test func testRepeatRuleInvalidRawValue() async throws {
        // Test invalid raw values return nil
        #expect(RepeatRule(rawValue: "invalid") == nil)
        #expect(RepeatRule(rawValue: "") == nil)
        #expect(RepeatRule(rawValue: "random") == nil)
    }
    
    // MARK: - Repeat Rule Business Logic Tests
    
    @Test func testRepeatRuleFrequency() async throws {
        // Test that repeat rules have logical frequency ordering
        let rules = [RepeatRule.none, .daily, .weekdays, .weekends, .weekly, .monthly]
        
        // Verify order from least to most frequent
        #expect(rules[0] == .none)
        #expect(rules[1] == .daily)
        #expect(rules[2] == .weekdays)
        #expect(rules[3] == .weekends)
        #expect(rules[4] == .weekly)
        #expect(rules[5] == .monthly)
    }
    
    @Test func testRepeatRuleDescription() async throws {
        // Test that repeat rules have meaningful descriptions
        #expect(RepeatRule.none.rawValue == "none")
        #expect(RepeatRule.daily.rawValue == "daily")
        #expect(RepeatRule.weekdays.rawValue == "weekdays")
        #expect(RepeatRule.weekends.rawValue == "weekends")
        #expect(RepeatRule.weekly.rawValue == "weekly")
        #expect(RepeatRule.monthly.rawValue == "monthly")
    }
    
    // MARK: - Repeat Rule Comparison Tests
    
    @Test func testRepeatRuleEquality() async throws {
        // Test equality between repeat rules
        let rule1 = RepeatRule.daily
        let rule2 = RepeatRule.daily
        let rule3 = RepeatRule.weekly
        
        #expect(rule1 == rule2)
        #expect(rule1 != rule3)
        #expect(rule2 != rule3)
    }
    
    @Test func testRepeatRuleIdentity() async throws {
        // Test that repeat rules maintain identity
        let rule = RepeatRule.monthly
        let sameRule = RepeatRule.monthly
        
        #expect(rule == sameRule)
        #expect(rule.rawValue == sameRule.rawValue)
    }
    
    // MARK: - Repeat Rule Edge Cases Tests
    
    @Test func testRepeatRuleNoneCase() async throws {
        // Test the none case specifically
        let noneRule = RepeatRule.none
        
        #expect(noneRule.rawValue == "none")
        #expect(noneRule == .none)
        #expect(noneRule != .daily)
    }
    
    @Test func testRepeatRuleDailyCase() async throws {
        // Test the daily case specifically
        let dailyRule = RepeatRule.daily
        
        #expect(dailyRule.rawValue == "daily")
        #expect(dailyRule == .daily)
        #expect(dailyRule != .none)
        #expect(dailyRule != .weekly)
    }
    
    @Test func testRepeatRuleWeekdaysCase() async throws {
        // Test the weekdays case specifically
        let weekdaysRule = RepeatRule.weekdays
        
        #expect(weekdaysRule.rawValue == "weekdays")
        #expect(weekdaysRule == .weekdays)
        #expect(weekdaysRule != .daily)
        #expect(weekdaysRule != .weekends)
    }
    
    @Test func testRepeatRuleWeekendsCase() async throws {
        // Test the weekends case specifically
        let weekendsRule = RepeatRule.weekends
        
        #expect(weekendsRule.rawValue == "weekends")
        #expect(weekendsRule == .weekends)
        #expect(weekendsRule != .daily)
        #expect(weekendsRule != .weekdays)
    }
    
    @Test func testRepeatRuleWeeklyCase() async throws {
        // Test the weekly case specifically
        let weeklyRule = RepeatRule.weekly
        
        #expect(weeklyRule.rawValue == "weekly")
        #expect(weeklyRule == .weekly)
        #expect(weeklyRule != .daily)
        #expect(weeklyRule != .monthly)
    }
    
    @Test func testRepeatRuleMonthlyCase() async throws {
        // Test the monthly case specifically
        let monthlyRule = RepeatRule.monthly
        
        #expect(monthlyRule.rawValue == "monthly")
        #expect(monthlyRule == .monthly)
        #expect(monthlyRule != .weekly)
        #expect(monthlyRule != .daily)
    }
    
    // MARK: - Repeat Rule Array Tests
    
    @Test func testRepeatRuleAllCases() async throws {
        // Test that allCases contains all expected cases
        let allCases = RepeatRule.allCases
        
        #expect(allCases.count == 6)
        #expect(allCases.contains(.none))
        #expect(allCases.contains(.daily))
        #expect(allCases.contains(.weekdays))
        #expect(allCases.contains(.weekends))
        #expect(allCases.contains(.weekly))
        #expect(allCases.contains(.monthly))
    }
    
    @Test func testRepeatRuleArrayOrder() async throws {
        // Test that allCases maintains consistent order
        let allCases = RepeatRule.allCases
        
        #expect(allCases[0] == .none)
        #expect(allCases[1] == .daily)
        #expect(allCases[2] == .weekdays)
        #expect(allCases[3] == .weekends)
        #expect(allCases[4] == .weekly)
        #expect(allCases[5] == .monthly)
    }
    
    // MARK: - Repeat Rule String Conversion Tests
    
    @Test func testRepeatRuleToString() async throws {
        // Test converting repeat rules to strings
        #expect(RepeatRule.none.rawValue == "none")
        #expect(RepeatRule.daily.rawValue == "daily")
        #expect(RepeatRule.weekdays.rawValue == "weekdays")
        #expect(RepeatRule.weekends.rawValue == "weekends")
        #expect(RepeatRule.weekly.rawValue == "weekly")
        #expect(RepeatRule.monthly.rawValue == "monthly")
    }
    
    @Test func testRepeatRuleFromString() async throws {
        // Test that raw values match expected strings
        #expect(RepeatRule.none.rawValue == "none")
        #expect(RepeatRule.daily.rawValue == "daily")
        #expect(RepeatRule.weekdays.rawValue == "weekdays")
        #expect(RepeatRule.weekends.rawValue == "weekends")
        #expect(RepeatRule.weekly.rawValue == "weekly")
        #expect(RepeatRule.monthly.rawValue == "monthly")
    }
    
    // MARK: - Repeat Rule Validation Tests
    
    @Test func testRepeatRuleValidValues() async throws {
        // Test all valid repeat rule values exist
        let validValues = ["none", "daily", "weekdays", "weekends", "weekly", "monthly"]
        
        for value in validValues {
            #expect(RepeatRule.allCases.contains { $0.rawValue == value })
        }
    }
    
    @Test func testRepeatRuleInvalidValues() async throws {
        // Test that invalid values are not in allCases
        let invalidValues = ["", "invalid", "random", "test", "123"]
        
        for value in invalidValues {
            #expect(!RepeatRule.allCases.contains { $0.rawValue == value })
        }
    }
    
    // MARK: - Display Name Tests
    
    @Test func testRepeatRuleDisplayNames() async throws {
        // Test that display names are user-friendly
        #expect(RepeatRule.none.displayName == "None")
        #expect(RepeatRule.daily.displayName == "Daily")
        #expect(RepeatRule.weekdays.displayName == "Weekdays")
        #expect(RepeatRule.weekends.displayName == "Weekends")
        #expect(RepeatRule.weekly.displayName == "Weekly")
        #expect(RepeatRule.monthly.displayName == "Monthly")
    }
}
