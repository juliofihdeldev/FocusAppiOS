import Foundation

enum RepeatRule: String, CaseIterable, Identifiable, Codable {
    case none = "none"
    case daily = "daily"
    case weekdays = "weekdays"
    case weekends = "weekends"
    case weekly = "weekly"
    case monthly = "monthly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
