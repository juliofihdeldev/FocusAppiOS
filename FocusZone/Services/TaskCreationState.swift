import Foundation
import SwiftUI

/// Stores UX state about task creation to improve defaults for the next task.
/// Persists across launches for the current day; clears automatically on the next day.
@MainActor
final class TaskCreationState: ObservableObject {
    static let shared = TaskCreationState()
    @Published var nextSuggestedStartTime: Date? {
        didSet { persistSuggestedTime() }
    }
    
    private let defaults = UserDefaults.standard
    private let timeKey = "TaskCreationState.nextSuggestedStartTime"
    
    private init() {
        loadPersistedSuggestedTime()
        // Clear at midnight when the calendar day changes
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.clearSuggestedTime()
        }
    }
    
    private func loadPersistedSuggestedTime() {
        guard let timestamp = defaults.object(forKey: timeKey) as? TimeInterval else {
            nextSuggestedStartTime = nil
            return
        }
        let stored = Date(timeIntervalSince1970: timestamp)
        // Keep only if it's still the same calendar day
        if Calendar.current.isDate(stored, inSameDayAs: Date()) {
            nextSuggestedStartTime = stored
        } else {
            clearSuggestedTime()
        }
    }
    
    private func persistSuggestedTime() {
        if let date = nextSuggestedStartTime {
            // Persist only if it's today; otherwise clear
            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                defaults.set(date.timeIntervalSince1970, forKey: timeKey)
            } else {
                clearSuggestedTime()
            }
        } else {
            defaults.removeObject(forKey: timeKey)
        }
    }
    
    func clearSuggestedTime() {
        nextSuggestedStartTime = nil
        defaults.removeObject(forKey: timeKey)
    }

}


