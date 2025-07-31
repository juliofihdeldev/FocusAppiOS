import SwiftUI
import Foundation

// MARK: - Enhanced Break Suggestion Model with Impact Scoring
struct BreakSuggestion: Identifiable {
    let id = UUID()
    let type: BreakType
    let suggestedDuration: Int // in minutes
    let reason: String
    let icon: String
    let timeUntilOptimal: Int // minutes until suggested time
    let insertAfterTaskId: UUID?
    let suggestedStartTime: Date
    let impactScore: Double // 0-100, higher = more beneficial
    let priority: SuggestionPriority
    
    init(
        type: BreakType,
        suggestedDuration: Int,
        reason: String,
        icon: String,
        timeUntilOptimal: Int,
        insertAfterTaskId: UUID?,
        suggestedStartTime: Date,
        impactScore: Double = 50.0,
        priority: SuggestionPriority = .medium
    ) {
        self.type = type
        self.suggestedDuration = suggestedDuration
        self.reason = reason
        self.icon = icon
        self.timeUntilOptimal = timeUntilOptimal
        self.insertAfterTaskId = insertAfterTaskId
        self.suggestedStartTime = suggestedStartTime
        self.impactScore = impactScore
        self.priority = priority
    }
    
    // Computed properties for better UX
    var isHighPriority: Bool {
        return priority == .high || impactScore >= 80
    }
    
    var isTimeRelevant: Bool {
        let now = Date()
        let timeUntilStart = suggestedStartTime.timeIntervalSince(now)
        return timeUntilStart > 0 && timeUntilStart <= 4 * 3600 // Next 4 hours
    }
    
    var formattedTimeUntil: String {
        if timeUntilOptimal <= 0 {
            return "now"
        } else if timeUntilOptimal < 60 {
            return "\(timeUntilOptimal)m"
        } else {
            let hours = timeUntilOptimal / 60
            let minutes = timeUntilOptimal % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
    
    var impactDescription: String {
        switch impactScore {
        case 80...100:
            return "High impact"
        case 60...79:
            return "Medium impact"
        case 40...59:
            return "Low impact"
        default:
            return "Minimal impact"
        }
    }
}

// MARK: - Suggestion Priority Levels
enum SuggestionPriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Optional"
        case .medium: return "Recommended"
        case .high: return "Important"
        case .critical: return "Essential"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}


extension BreakSuggestion {
    init(
        type: BreakType,
        suggestedDuration: Int,
        reason: String,
        icon: String,
        timeUntilOptimal: Int,
        insertAfterTaskId: UUID?,
        suggestedStartTime: Date,
        impactScore: Double
    ) {
        self.init(
            type: type,
            suggestedDuration: suggestedDuration,
            reason: reason,
            icon: icon,
            timeUntilOptimal: timeUntilOptimal,
            insertAfterTaskId: insertAfterTaskId,
            suggestedStartTime: suggestedStartTime
        )
//        self.impactScore = impactScore
    }
    
    // Add impact score property to the existing model
//    private(set) var impactScore: Double = 50.0
}

// MARK: - Enhanced Break Types with More Context
enum BreakType: String, CaseIterable {
    case snack = "snack"
    case hydration = "hydration"
    case movement = "movement"
    case rest = "rest"
    case fresh_air = "fresh_air"
    case eye_rest = "eye_rest"
    case social = "social"
    
    var displayName: String {
        switch self {
        case .snack: return "Snack Break"
        case .hydration: return "Hydration"
        case .movement: return "Movement"
        case .rest: return "Rest"
        case .fresh_air: return "Fresh Air"
        case .eye_rest: return "Eye Rest"
        case .social: return "Social Break"
        }
    }
    
    var icon: String {
        switch self {
        case .snack: return "🍎"
        case .hydration: return "💧"
        case .movement: return "🚶"
        case .rest: return "😌"
        case .fresh_air: return "🌬️"
        case .eye_rest: return "👁️"
        case .social: return "👥"
        }
    }
    
    var color: Color {
        switch self {
        case .snack: return .orange
        case .hydration: return .blue
        case .movement: return .green
        case .rest: return .purple
        case .fresh_air: return .mint
        case .eye_rest: return .cyan
        case .social: return .pink
        }
    }
    
    var typicalDuration: Int {
        switch self {
        case .snack: return 15
        case .hydration: return 2
        case .movement: return 10
        case .rest: return 20
        case .fresh_air: return 15
        case .eye_rest: return 5
        case .social: return 10
        }
    }
    
    var healthBenefit: String {
        switch self {
        case .snack: return "Maintains energy levels"
        case .hydration: return "Prevents dehydration and fatigue"
        case .movement: return "Improves circulation and reduces tension"
        case .rest: return "Prevents mental fatigue and burnout"
        case .fresh_air: return "Increases oxygen levels and alertness"
        case .eye_rest: return "Reduces eye strain from screens"
        case .social: return "Reduces isolation and improves mood"
        }
    }
}

// MARK: - Suggestion Context Information
struct SuggestionContext {
    let triggerTask: Task?
    let nextTask: Task?
    let currentWorkStreak: TimeInterval // How long user has been working
    let lastBreakTime: Date?
    let timeOfDay: TimeOfDay
    let workloadIntensity: WorkloadIntensity
    
    enum WorkloadIntensity {
        case light, moderate, heavy, intense
    }
    
    enum TimeOfDay {
        case morning, midday, afternoon, evening
        
        static func from(date: Date) -> TimeOfDay {
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 6..<12: return .morning
            case 12..<14: return .midday
            case 14..<18: return .afternoon
            default: return .evening
            }
        }
    }
}
