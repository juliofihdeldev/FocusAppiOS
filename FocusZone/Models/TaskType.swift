
import SwiftUI

enum TaskType: String, CaseIterable, Identifiable, Codable {
    case work
    case exercise
    case study
    case relax
    case meal
    case sleep
    case custom

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .work: return "💼"
        case .exercise: return "🏃‍♂️"
        case .study: return "📚"
        case .relax: return "🧘"
        case .meal: return "🍽"
        case .sleep: return "🌙"
        case .custom: return "🛠"
        }
    }

    var color: Color {
        switch self {
        case .work: return .green
        case .exercise: return .yellow
        case .study: return .blue
        case .relax: return .purple
        case .meal: return .orange
        case .sleep: return .indigo
        case .custom: return .gray
        }
    }

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .exercise: return "Exercise"
        case .study: return "Study"
        case .relax: return "Relax"
        case .meal: return "Meal"
        case .sleep: return "Sleep"
        case .custom: return "Custom"
        }
    }
}
