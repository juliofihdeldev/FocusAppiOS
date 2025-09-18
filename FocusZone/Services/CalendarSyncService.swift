import Foundation
import EventKit
import SwiftData

@MainActor
class CalendarSyncService: ObservableObject {
    static let shared = CalendarSyncService()
    
    private let eventStore = EKEventStore()
    @Published var isAuthorized = false
    @Published var syncEnabled = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestCalendarAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized, .fullAccess:
            isAuthorized = true
            return true
        case .notDetermined:
            let granted = try? await eventStore.requestFullAccessToEvents()
            isAuthorized = granted ?? false
            return isAuthorized
        case .denied, .restricted, .writeOnly:
            isAuthorized = false
            return false
        @unknown default:
            isAuthorized = false
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = status == .authorized || status == .fullAccess
    }
    
    // MARK: - Task to Calendar Sync
    
    func createCalendarEvent(from task: Task) -> String? {
        guard isAuthorized else { return nil }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "🎯 \(task.title)"
        event.startDate = task.startTime
        event.endDate = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        event.notes = "Focus session: \(task.title)\nDuration: \(task.durationMinutes) minutes"
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Add task type as a category
        if let taskType = task.taskType {
            event.notes?.append("\nType: \(taskType.displayName)")
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Calendar event created: \(event.title ?? "Unknown")")
            return event.eventIdentifier
        } catch {
            print("❌ Failed to create calendar event: \(error)")
            return nil
        }
    }
    
    func updateCalendarEvent(eventId: String, from task: Task) {
        guard isAuthorized else { return }
        
        if let event = eventStore.event(withIdentifier: eventId) {
            event.title = "🎯 \(task.title)"
            event.startDate = task.startTime
            event.endDate = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
            event.notes = "Focus session: \(task.title)\nDuration: \(task.durationMinutes) minutes"
            
            if let taskType = task.taskType {
                event.notes?.append("\nType: \(taskType.displayName)")
            }
            
            do {
                try eventStore.save(event, span: .thisEvent)
                print("✅ Calendar event updated: \(event.title ?? "Unknown")")
            } catch {
                print("❌ Failed to update calendar event: \(error)")
            }
        }
    }
    
    func deleteCalendarEvent(eventId: String) {
        guard isAuthorized else { return }
        
        if let event = eventStore.event(withIdentifier: eventId) {
            do {
                try eventStore.remove(event, span: .thisEvent)
                print("✅ Calendar event deleted: \(event.title ?? "Unknown")")
            } catch {
                print("❌ Failed to delete calendar event: \(error)")
            }
        }
    }
    
    // MARK: - Calendar to Task Sync
    
    func createTaskFromCalendarEvent(_ event: EKEvent) -> Task? {
        // Only process events that look like focus sessions
        guard let title = event.title,
              title.hasPrefix("🎯") || title.lowercased().contains("focus") else {
            return nil
        }
        
        let cleanTitle = title.replacingOccurrences(of: "🎯 ", with: "")
        let duration = Int(event.endDate.timeIntervalSince(event.startDate) / 60)
        
        let task = Task(
            title: cleanTitle,
            icon: "🎯",
            startTime: event.startDate,
            durationMinutes: duration,
            color: .blue,
            taskType: .work
        )
        
        // Store the calendar event ID for future updates
        task.calendarEventId = event.eventIdentifier
        
        print("✅ Task created from calendar event: \(task.title)")
        return task
    }
    
    func syncCalendarEventsToTasks(modelContext: ModelContext) {
        guard isAuthorized else { return }
        
        guard let calendar = eventStore.defaultCalendarForNewEvents else { return }
        let predicate = eventStore.predicateForEvents(
            withStart: Date().addingTimeInterval(-7 * 24 * 60 * 60), // Last 7 days
            end: Date().addingTimeInterval(30 * 24 * 60 * 60), // Next 30 days
            calendars: [calendar]
        )
        
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            if let task = createTaskFromCalendarEvent(event) {
                modelContext.insert(task)
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Synced \(events.count) calendar events to tasks")
        } catch {
            print("❌ Failed to save synced tasks: \(error)")
        }
    }
    
    // MARK: - Sync Management
    
    func enableSync() {
        syncEnabled = true
        UserDefaults.standard.set(true, forKey: "calendar_sync_enabled")
    }
    
    func disableSync() {
        syncEnabled = false
        UserDefaults.standard.set(false, forKey: "calendar_sync_enabled")
    }
    
    func loadSyncSettings() {
        syncEnabled = UserDefaults.standard.bool(forKey: "calendar_sync_enabled")
    }
}
