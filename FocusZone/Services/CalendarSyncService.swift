import Foundation
import EventKit
import SwiftData
import SwiftUI

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
    
    func getImportableCalendarEvents() async -> [EKEvent] {
        guard isAuthorized else {
            print("CalendarSyncService: Not authorized to access calendar")
            return []
        }
        
        do {
            guard let calendar = eventStore.defaultCalendarForNewEvents else { return [] }
            let predicate = eventStore.predicateForEvents(
                withStart: Date().addingTimeInterval(-7 * 24 * 60 * 60), // Last 7 days
                end: Date().addingTimeInterval(30 * 24 * 60 * 60), // Next 30 days
                calendars: [calendar]
            )
            
            let events = eventStore.events(matching: predicate)
            // Import ALL events, not just focus-related ones
            let allEvents = events.filter { event in
                // Filter out all-day events and very short events (less than 5 minutes)
                guard let title = event.title, !title.isEmpty else { return false }
                let duration = event.endDate.timeIntervalSince(event.startDate)
                return duration >= 300 // At least 5 minutes
            }
            
            print("CalendarSyncService: Found \(allEvents.count) importable events")
            return allEvents
        } catch {
            print("CalendarSyncService: Error fetching calendar events: \(error)")
            return []
        }
    }
    
    func createTaskFromCalendarEvent(_ event: EKEvent) -> Task? {
        // Process ALL events, not just focus-related ones
        guard let title = event.title, !title.isEmpty else { return nil }
        
        let cleanTitle = title.replacingOccurrences(of: "🎯 ", with: "")
        let duration = Int(event.endDate.timeIntervalSince(event.startDate) / 60)
        
        let task = Task(
            title: cleanTitle,
            icon: getIconForEvent(event),
            startTime: event.startDate,
            durationMinutes: duration,
            color: getColorForEvent(event),
            isCompleted: event.endDate < Date(),
            taskType: getTaskTypeForEvent(event),
            status: event.endDate < Date() ? .completed : .scheduled
        )
        
        // Set calendar event ID after creation
        task.calendarEventId = event.eventIdentifier
        
        print("✅ Task created from calendar event: \(task.title)")
        return task
    }
    
    func importCalendarEventsAsTasks(_ events: [EKEvent], modelContext: ModelContext) -> [Task] {
        var importedTasks: [Task] = []
        
        for event in events {
            if let task = createTaskFromCalendarEvent(event) {
                modelContext.insert(task)
                importedTasks.append(task)
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Successfully imported \(importedTasks.count) tasks from calendar")
        } catch {
            print("❌ Failed to save imported tasks: \(error)")
        }
        
        return importedTasks
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
        // Import ALL events, not just focus-related ones
        let allEvents = events.filter { event in
            guard let title = event.title, !title.isEmpty else { return false }
            let duration = event.endDate.timeIntervalSince(event.startDate)
            return duration >= 300 // At least 5 minutes
        }
        
        for event in allEvents {
            if let task = createTaskFromCalendarEvent(event) {
                modelContext.insert(task)
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Synced \(allEvents.count) calendar events to tasks")
        } catch {
            print("❌ Failed to save synced tasks: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func isFocusRelatedEvent(_ event: EKEvent) -> Bool {
        guard let title = event.title?.lowercased() else { return false }
        
        let focusKeywords = [
            "focus", "deep work", "concentration", "study", "work session",
            "pomodoro", "time block", "productive", "task", "project",
            "meeting", "call", "review", "planning", "brainstorming",
            "coding", "development", "design", "writing", "reading"
        ]
        
        return focusKeywords.contains { keyword in
            title.contains(keyword)
        } || title.hasPrefix("🎯")
    }
    
    private func getIconForEvent(_ event: EKEvent) -> String {
        guard let title = event.title?.lowercased() else { return "📅" }
        
        if title.contains("meeting") || title.contains("call") {
            return "📞"
        } else if title.contains("study") || title.contains("learn") || title.contains("reading") {
            return "📚"
        } else if title.contains("work") || title.contains("project") || title.contains("coding") {
            return "💼"
        } else if title.contains("focus") || title.contains("deep work") || title.contains("concentration") {
            return "🎯"
        } else if title.contains("planning") || title.contains("review") || title.contains("design") {
            return "📋"
        } else if title.contains("writing") {
            return "✍️"
        } else {
            return "📅"
        }
    }
    
    private func getColorForEvent(_ event: EKEvent) -> Color {
        guard let title = event.title?.lowercased() else { return .blue }
        
        if title.contains("meeting") || title.contains("call") {
            return .green
        } else if title.contains("study") || title.contains("learn") || title.contains("reading") {
            return .purple
        } else if title.contains("work") || title.contains("project") || title.contains("coding") {
            return .orange
        } else if title.contains("focus") || title.contains("deep work") || title.contains("concentration") {
            return .red
        } else if title.contains("planning") || title.contains("review") || title.contains("design") {
            return .blue
        } else if title.contains("writing") {
            return .indigo
        } else {
            return .gray
        }
    }
    
    private func getTaskTypeForEvent(_ event: EKEvent) -> TaskType? {
        guard let title = event.title?.lowercased() else { return .work }
        
        if title.contains("study") || title.contains("learn") || title.contains("reading") {
            return .study
        } else if title.contains("work") || title.contains("project") || title.contains("coding") || title.contains("meeting") || title.contains("call") {
            return .work
        } else if title.contains("exercise") || title.contains("workout") || title.contains("fitness") {
            return .exercise
        } else if title.contains("relax") || title.contains("break") || title.contains("rest") {
            return .relax
        } else if title.contains("meal") || title.contains("lunch") || title.contains("dinner") || title.contains("breakfast") {
            return .meal
        } else if title.contains("sleep") || title.contains("nap") {
            return .sleep
        } else {
            return .work
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
