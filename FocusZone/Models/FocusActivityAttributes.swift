import Foundation
import ActivityKit

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var taskTitle: String
        var taskDescription: String?
        var startTime: Date
        var endTime: Date
        var isActive: Bool
        var timeRemaining: TimeInterval
        var progress: Double // 0.0 to 1.0
        var currentPhase: FocusPhase
        var totalSessions: Int
        var completedSessions: Int
    }
    
    // Fixed non-changing properties about your activity go here!
    var taskId: String
    var taskType: String
    var focusMode: String
    var sessionDuration: TimeInterval
    var breakDuration: TimeInterval?
}

enum FocusPhase: String, CaseIterable, Codable {
    case focus = "focus"
    case shortBreak = "short_break"
    case longBreak = "long_break"
    case completed = "completed"
    case paused = "paused"
    
    var displayName: String {
        switch self {
        case .focus:
            return NSLocalizedString("focus_phase", comment: "Focus phase")
        case .shortBreak:
            return NSLocalizedString("short_break_phase", comment: "Short break phase")
        case .longBreak:
            return NSLocalizedString("long_break_phase", comment: "Long break phase")
        case .completed:
            return NSLocalizedString("completed_phase", comment: "Completed phase")
        case .paused:
            return NSLocalizedString("paused_phase", comment: "Paused phase")
        }
    }
    
    var icon: String {
        switch self {
        case .focus:
            return "brain.head.profile"
        case .shortBreak:
            return "cup.and.saucer"
        case .longBreak:
            return "bed.double"
        case .completed:
            return "checkmark.circle.fill"
        case .paused:
            return "pause.circle.fill"
        }
    }
}
