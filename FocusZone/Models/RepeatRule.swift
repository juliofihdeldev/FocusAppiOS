import Foundation

enum RepeatRule: String, CaseIterable, Identifiable, Codable {
    case none = "none"
    case once = "once" // Added this case since it was referenced in DataManager
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .once: return "Once"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
