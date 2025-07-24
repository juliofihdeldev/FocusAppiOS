import SwiftUI
import Foundation

// MARK: - Break Suggestion Model
struct BreakSuggestion: Identifiable {
    let id = UUID()
    let type: BreakType
    let suggestedDuration: Int // in minutes
    let reason: String
    let icon: String
    let timeUntilOptimal: Int // minutes until suggested time
    let insertAfterTaskId: UUID?
    let suggestedStartTime: Date
}

// MARK: - Break Types
enum BreakType: String, CaseIterable {
    case snack = "snack"
    case hydration = "hydration"
    case movement = "movement"
    case rest = "rest"
    case fresh_air = "fresh_air"
    
    var displayName: String {
        switch self {
        case .snack: return "Snack Break"
        case .hydration: return "Hydration"
        case .movement: return "Movement"
        case .rest: return "Rest"
        case .fresh_air: return "Fresh Air"
        }
    }
    
    var icon: String {
        switch self {
        case .snack: return "🍎"
        case .hydration: return "💧"
        case .movement: return "🚶"
        case .rest: return "😌"
        case .fresh_air: return "🌬️"
        }
    }
    
    var color: Color {
        switch self {
        case .snack: return .orange
        case .hydration: return .blue
        case .movement: return .green
        case .rest: return .purple
        case .fresh_air: return .mint
        }
    }
}
