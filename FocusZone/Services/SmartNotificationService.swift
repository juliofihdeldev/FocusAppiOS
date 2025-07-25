//
//  SmartNotificationService.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/24/25.
//

import UserNotifications
import Foundation

// MARK: - Smart Notification Service for AI Insights
class SmartNotificationService: ObservableObject {
    static let shared = SmartNotificationService()
    
    private init() {}
    
    // MARK: - Weekly Insights Notifications
    
    func scheduleWeeklyInsightsNotification(insights: [FocusInsight]) {
        guard !insights.isEmpty else { return }
        
        // Send notification every Monday at 9 AM
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "🧠 Your Weekly Focus Insights"
        
        let topInsight = insights.max(by: { $0.impactScore < $1.impactScore })
        if let insight = topInsight {
            content.body = insight.message
            content.subtitle = "Tap to see all \(insights.count) insights"
        } else {
            content.body = "New productivity insights are ready for you"
        }
        
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_INSIGHTS"
        content.userInfo = [
            "type": "weeklyInsights",
            "insightCount": insights.count
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "weekly_insights",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling weekly insights notification: \(error)")
            } else {
                print("Scheduled weekly insights notification")
            }
        }
    }
    
    // MARK: - Smart Performance Nudges
    
    func schedulePerformanceNudge(for insight: FocusInsight) {
        guard insight.impactScore >= 70 else { return } // Only high-impact insights
        
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.categoryIdentifier = "PERFORMANCE_NUDGE"
        
        var scheduleTime: DateComponents
        
        switch insight.type {
        case .timeOfDay:
            // Schedule 15 minutes before optimal time
            content.title = "⏰ Peak Performance Time"
            content.body = "Your most productive time is starting soon"
            
            scheduleTime = extractOptimalTimeFromInsight(insight)
            scheduleTime.minute = (scheduleTime.minute ?? 0) - 15
            
        case .breakPattern:
            // Schedule during typical work hours
            content.title = "🧘 Break Reminder"
            content.body = "Taking a break now could boost your next task by 25%"
            
            scheduleTime = DateComponents()
            scheduleTime.hour = 14 // 2 PM
            scheduleTime.minute = 30
            
        case .taskDuration:
            // Schedule when user typically plans tasks
            content.title = "📝 Task Planning Tip"
            content.body = insight.recommendation
            
            scheduleTime = DateComponents()
            scheduleTime.hour = 8 // 8 AM
            scheduleTime.minute = 0
            
        default:
            return // Don't send nudges for other insight types
        }
        
        content.userInfo = [
            "type": "performanceNudge",
            "insightType": insight.type.rawValue,
            "recommendation": insight.recommendation
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: scheduleTime,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "nudge_\(insight.type.rawValue)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling performance nudge: \(error)")
            } else {
                print("Scheduled performance nudge for \(insight.type)")
            }
        }
    }
    
    // MARK: - Achievement Notifications
    
    func sendAchievementNotification(for milestone: FocusAchievement) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Focus Achievement Unlocked!"
        content.body = milestone.description
        content.sound = UNNotificationSound(named: UNNotificationSoundName("achievement.wav"))
        content.categoryIdentifier = "ACHIEVEMENT"
        content.userInfo = [
            "type": "achievement",
            "achievementId": milestone.id
        ]
        
        let request = UNNotificationRequest(
            identifier: "achievement_\(milestone.id)",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending achievement notification: \(error)")
            } else {
                print("Sent achievement notification: \(milestone.title)")
            }
        }
    }
    
    // MARK: - Weekly Review Reminder
    
    func scheduleWeeklyReviewReminder() {
        let content = UNMutableNotificationContent()
        content.title = "📊 Weekly Focus Review"
        content.body = "Take 2 minutes to review your productivity wins and areas for growth"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_REVIEW"
        
        // Schedule for Friday at 5 PM
        var dateComponents = DateComponents()
        dateComponents.weekday = 6 // Friday
        dateComponents.hour = 17
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "weekly_review",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling weekly review: \(error)")
            } else {
                print("Scheduled weekly review reminder")
            }
        }
    }
    
    // MARK: - Smart Break Suggestions
    
    func suggestSmartBreak(after completedTask: Task, nextTask: Task?) {
        let content = UNMutableNotificationContent()
        content.title = "✨ Smart Break Suggestion"
        content.sound = .default
        content.categoryIdentifier = "SMART_BREAK"
        
        if let nextTask = nextTask {
            let timeUntilNext = Int(nextTask.startTime.timeIntervalSince(Date()) / 60)
            
            if timeUntilNext >= 15 && timeUntilNext <= 45 {
                content.body = "You have \(timeUntilNext) minutes until '\(nextTask.title)'. Perfect time for a focused break!"
                
                // Schedule in 2 minutes
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: 120,
                    repeats: false
                )
                
                let request = UNNotificationRequest(
                    identifier: "smart_break_\(Date().timeIntervalSince1970)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractOptimalTimeFromInsight(_ insight: FocusInsight) -> DateComponents {
        // Parse time from insight message (this is simplified)
        // In a real implementation, you'd store structured data
        let timePattern = #"(\d{1,2})-(\d{1,2}) (AM|PM)"#
        
        do {
            let regex = try NSRegularExpression(pattern: timePattern)
            let range = NSRange(insight.message.startIndex..., in: insight.message)
            
            if let match = regex.firstMatch(in: insight.message, range: range) {
                let startHour = Int(String(insight.message[Range(match.range(at: 1), in: insight.message)!])) ?? 9
                
                var components = DateComponents()
                components.hour = startHour
                components.minute = 0
                return components
            }
        } catch {
            print("Error parsing time from insight: \(error)")
        }
        
        // Default to 9 AM
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return components
    }
    
    // MARK: - Notification Categories Setup
    
    func setupNotificationCategories() {
        let insightsCategory = UNNotificationCategory(
            identifier: "WEEKLY_INSIGHTS",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_INSIGHTS",
                    title: "View Insights",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "REMIND_LATER",
                    title: "Remind Later",
                    options: []
                )
            ],
            intentIdentifiers: []
        )
        
        let nudgeCategory = UNNotificationCategory(
            identifier: "PERFORMANCE_NUDGE",
            actions: [
                UNNotificationAction(
                    identifier: "APPLY_TIP",
                    title: "Apply Now",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DISMISS_TIP",
                    title: "Dismiss",
                    options: []
                )
            ],
            intentIdentifiers: []
        )
        
        let achievementCategory = UNNotificationCategory(
            identifier: "ACHIEVEMENT",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_ACHIEVEMENT",
                    title: "View Details",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            insightsCategory,
            nudgeCategory,
            achievementCategory
        ])
    }
}

// MARK: - Focus Achievement Model
struct FocusAchievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let unlockedAt: Date
}

enum AchievementCategory {
    case consistency
    case efficiency
    case balance
    case growth
}
