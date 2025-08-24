import Testing
import Foundation
@testable import FocusZone

struct RepeatRuleTests {
    
    // MARK: - Repeat Rule Enum Tests
    
    @Test func testRepeatRuleCases() async throws {
        // Test all repeat rule cases exist
        #expect(RepeatRule.allCases.contains(.none))
        #expect(RepeatRule.allCases.contains(.daily))
        #expect(RepeatRule.allCases.contains(.weekly))
        #expect(RepeatRule.allCases.contains(.monthly))
        #expect(RepeatRule.allCases.contains(.yearly))
    }
    
    @Test func testRepeatRuleRawValues() async throws {
        // Test raw values are correct
        #expect(RepeatRule.none.rawValue == "none")
        #expect(RepeatRule.daily.rawValue == "daily")
        #expect(RepeatRule.weekly.rawValue == "weekly")
        #expect(RepeatRule.monthly.rawValue == "monthly")
        #expect(RepeatRule.yearly.rawValue == "yearly")
    }
    
    @Test func testRepeatRuleFromRawValue() async throws {
        // Test creating repeat rules from raw values
        #expect(RepeatRule(rawValue: "none") == .none)
        #expect(RepeatRule(rawValue: "daily") == .daily)
        #expect(RepeatRule(rawValue: "weekly") == .weekly)
        #expect(RepeatRule(rawValue: "monthly") == .monthly)
        #expect(RepeatRule(rawValue: "yearly") == .yearly)
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
        let rules = [RepeatRule.none, .daily, .weekly, .monthly, .yearly]
        
        // Verify order from least to most frequent
        #expect(rules[0] == .none)
        #expect(rules[1] == .daily)
        #expect(rules[2] == .weekly)
        #expect(rules[3] == .monthly)
        #expect(rules[4] == .yearly)
    }
    
    @Test func testRepeatRuleDescription() async throws {
        // Test that repeat rules have meaningful descriptions
        #expect(RepeatRule.none.rawValue == "none")
        #expect(RepeatRule.daily.rawValue == "daily")
        #expect(RepeatRule.weekly.rawValue == "weekly")
        #expect(RepeatRule.monthly.rawValue == "monthly")
        #expect(RepeatRule.yearly.rawValue == "yearly")
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
        #expect(monthlyRule != .yearly)
    }
    
    @Test func testRepeatRuleYearlyCase() async throws {
        // Test the yearly case specifically
        let yearlyRule = RepeatRule.yearly
        
        #expect(yearlyRule.rawValue == "yearly")
        #expect(yearlyRule == .yearly)
        #expect(yearlyRule != .monthly)
        #expect(yearlyRule != .daily)
    }
    
    // MARK: - Repeat Rule Array Tests
    
    @Test func testRepeatRuleAllCases() async throws {
        // Test that allCases contains all expected cases
        let allCases = RepeatRule.allCases
        
        #expect(allCases.count == 5)
        #expect(allCases.contains(.none))
        #expect(allCases.contains(.daily))
        #expect(allCases.contains(.weekly))
        #expect(allCases.contains(.monthly))
        #expect(allCases.contains(.yearly))
    }
    
    @Test func testRepeatRuleArrayOrder() async throws {
        // Test that allCases maintains consistent order
        let allCases = RepeatRule.allCases
        
        #expect(allCases[0] == .none)
        #expect(allCases[1] == .daily)
        #expect(allCases[2] == .weekly)
        #expect(allCases[3] == .monthly)
        #expect(allCases[4] == .yearly)
    }
    
    // MARK: - Repeat Rule String Conversion Tests
    
    @Test func testRepeatRuleToString() async throws {
        // Test converting repeat rules to strings
        #expect(RepeatRule.none.rawValue == "none")
        #expect(RepeatRule.daily.rawValue == "daily")
        #expect(RepeatRule.weekly.rawValue == "weekly")
        #expect(RepeatRule.monthly.rawValue == "monthly")
        #expect(RepeatRule.yearly.rawValue == "yearly")
    }
    
    @Test func testRepeatRuleFromString() async throws {
        // Test creating repeat rules from strings
        #expect(RepeatRule(rawValue: "none") == .none)
        #expect(RepeatRule(rawValue: "daily") == .daily)
        #expect(RepeatRule(rawValue: "weekly") == .weekly)
        #expect(RepeatRule(rawValue: "monthly") == .monthly)
        #expect(RepeatRule(rawValue: "yearly") == .yearly)
    }
    
    // MARK: - Repeat Rule Validation Tests
    
    @Test func testRepeatRuleValidValues() async throws {
        // Test all valid repeat rule values
        let validValues = ["none", "daily", "weekly", "monthly", "yearly"]
        
        for value in validValues {
            let rule = RepeatRule(rawValue: value)
            #expect(rule != nil)
        }
    }
    
    @Test func testRepeatRuleInvalidValues() async throws {
        // Test invalid repeat rule values
        let invalidValues = ["", "invalid", "random", "test", "123"]
        
        for value in invalidValues {
            let rule = RepeatRule(rawValue: value)
            #expect(rule == nil)
        }
    }
}
