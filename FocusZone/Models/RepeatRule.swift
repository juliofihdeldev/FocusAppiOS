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
        case .none: return NSLocalizedString("repeat_none", comment: "No repeat option")
        case .daily: return NSLocalizedString("repeat_daily", comment: "Comment: Daily repeat option")
        case .weekdays: return NSLocalizedString("repeat_weekdays", comment: "Weekdays repeat option")
        case .weekends: return NSLocalizedString("repeat_weekends", comment: "Weekends repeat option")
        case .weekly: return NSLocalizedString("repeat_weekly", comment: "Weekly repeat option")
        case .monthly: return NSLocalizedString("repeat_monthly", comment: "Monthly repeat option")
        }
    }
}
