import Foundation
import SwiftUI
import SwiftData

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func loadTodayTasks(for date: Date = Date()) {
        guard let modelContext = modelContext else {
            print("TimelineViewModel: No modelContext available")
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.startTime)]
        )

        do {
            let allTasks = try modelContext.fetch(descriptor)
            var todayTasks: [Task] = []

            // First, get all actual tasks for this specific date
            let actualTasks = allTasks.filter { task in
                task.startTime >= startOfDay && task.startTime < endOfDay
            }
            todayTasks.append(contentsOf: actualTasks)

            // Then, generate virtual tasks from repeating tasks
            let repeatingTasks = allTasks.filter { task in
                task.repeatRule != .none && !task.isGeneratedFromRepeat
            }

            for repeatingTask in repeatingTasks {
                if shouldIncludeRepeatingTask(task: repeatingTask, for: date) {
                    // Check if we already have a real task for this date/time/title
                    let taskExists = todayTasks.contains { existing in
                        calendar.isDate(existing.startTime, inSameDayAs: date) &&
                        existing.title == repeatingTask.title &&
                        calendar.component(.hour, from: existing.startTime) == calendar.component(.hour, from: repeatingTask.startTime) &&
                        calendar.component(.minute, from: existing.startTime) == calendar.component(.minute, from: repeatingTask.startTime)
                    }

                    if !taskExists {
                        let virtualTask = createVirtualTask(from: repeatingTask, for: date)
                        todayTasks.append(virtualTask)
                    }
                }
            }

            // Sort by start time and update the published property
            tasks = todayTasks.sorted { $0.startTime < $1.startTime }

            print("TimelineViewModel: Loaded \(tasks.count) tasks for \(dateString(date))")
            print("  - Actual tasks: \(actualTasks.count)")
            print("  - Virtual tasks: \(todayTasks.count - actualTasks.count)")
            
        } catch {
            print("TimelineViewModel: Error loading tasks: \(error)")
            tasks = []
        }
    }
    
    private func shouldIncludeRepeatingTask(task: Task, for date: Date) -> Bool {
        let calendar = Calendar.current
        let taskStartDate = calendar.startOfDay(for: task.startTime)
        let targetDate = calendar.startOfDay(for: date)
        
        // Don't include if the target date is before the task's start date
        guard targetDate >= taskStartDate else { return false }
        
        // Don't include the original date (that's handled by actual task)
        guard !calendar.isDate(targetDate, inSameDayAs: taskStartDate) else { return false }
        
        switch task.repeatRule {
        case .none:
            return false
            
        case .daily:
            return true // Every day after the start date
            
        case .weekly:
            let taskWeekday = calendar.component(.weekday, from: task.startTime)
            let dateWeekday = calendar.component(.weekday, from: date)
            return dateWeekday == taskWeekday
            
        case .monthly:
            let taskDay = calendar.component(.day, from: task.startTime)
            let dateDay = calendar.component(.day, from: date)
            return dateDay == taskDay
        case .once:
            return false
        }
    }
    
    private func createVirtualTask(from originalTask: Task, for date: Date) -> Task {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: originalTask.startTime)
        
        let newStartTime = calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0,
            of: date
        ) ?? date
        
        return Task(
            id: UUID(), // New unique ID for virtual task
            title: originalTask.title,
            icon: originalTask.icon,
            startTime: newStartTime,
            durationMinutes: originalTask.durationMinutes,
            color: originalTask.color,
            isCompleted: false, // Virtual tasks start as incomplete
            taskType: originalTask.taskType,
            status: .scheduled,
            repeatRule: .none, // Virtual tasks don't repeat themselves
            isGeneratedFromRepeat: true,
            parentTaskId: originalTask.id // Optional: track the original task
        )
    }
    
    func timeRange(for task: Task) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let endTime = task.startTime.addingTimeInterval(Double(task.durationMinutes) * 60)
        return "\(formatter.string(from: task.startTime)) - \(formatter.string(from: endTime))"
    }
    
    func taskColor(_ task: Task) -> Color {
        return task.color
    }
    
    func timeSpentOnTask(for task: Task) -> Double {
        let isTaskStarted = !task.isCompleted
        return isTaskStarted ? Date().timeIntervalSince(task.startTime) : 0
    }
    
    func scrollToNow() {
        print("Scroll to current time")
    }
    
    // MARK: - Task Management Actions
    
    func deleteTask(_ task: Task) {
        guard let modelContext = modelContext else { return }
        
        // If it's a virtual task, just remove from local array
        if task.isGeneratedFromRepeat {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks.remove(at: index)
            }
            return
        }
        
        // For real tasks, delete from persistent storage
        modelContext.delete(task)
        saveContext()
        refreshTasks()
    }
    
    func duplicateTask(_ task: Task) {
        guard let modelContext = modelContext else { return }
        
        let duplicatedTask = Task(
            title: "\(task.title) (Copy)",
            icon: task.icon,
            startTime: task.startTime.addingTimeInterval(3600), // +1 hour
            durationMinutes: task.durationMinutes,
            color: task.color,
            taskType: task.taskType,
            repeatRule: task.repeatRule,
            isGeneratedFromRepeat: false // Duplicated tasks are real tasks
        )
        
        modelContext.insert(duplicatedTask)
        saveContext()
        refreshTasks()
    }
    
    func completeTask(_ task: Task) {
        // If it's a virtual task, convert it to a real completed task
        if task.isGeneratedFromRepeat {
            guard let modelContext = modelContext else { return }
            
            let realTask = Task(
                id: task.id, // Keep the same ID
                title: task.title,
                icon: task.icon,
                startTime: task.startTime,
                durationMinutes: task.durationMinutes,
                color: task.color,
                isCompleted: true,
                taskType: task.taskType,
                status: .completed,
                repeatRule: .none, // Completed instances don't repeat
                isGeneratedFromRepeat: false // Now it's a real task
            )
            
            modelContext.insert(realTask)
            saveContext()
        } else {
            // For real tasks, just update the completion status
            task.isCompleted = true
            task.status = .completed
            task.updatedAt = Date()
            saveContext()
        }
        
        refreshTasks()
    }
    
    func addTask(_ task: Task) {
        print("TimelineViewModel: Adding task - \(task.title)")
        guard let modelContext = modelContext else { return }
        modelContext.insert(task)
        saveContext()
        refreshTasks()
    }
    
    func updateTask(_ task: Task) {
        task.updatedAt = Date()
        saveContext()
        refreshTasks()
    }
    
    func refreshTasks() {
        // Reload tasks for the currently selected date
        // Note: You might want to pass the current date from the view
        loadTodayTasks(for: Date())
    }
    
    func refreshTasks(for date: Date) {
        loadTodayTasks(for: date)
    }
    
    func getTaskDateCounts() -> [Date: Int] {
        guard let modelContext = modelContext else { return [:] }
        
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            let calendar = Calendar.current
            var taskCounts: [Date: Int] = [:]
            
            // Count actual tasks
            for task in allTasks.filter({ !$0.isGeneratedFromRepeat }) {
                let startOfDay = calendar.startOfDay(for: task.startTime)
                taskCounts[startOfDay, default: 0] += 1
            }
            
            // Add counts for repeating tasks (for next 30 days as example)
            let today = Date()
            let endDate = calendar.date(byAdding: .day, value: 30, to: today) ?? today
            let repeatingTasks = allTasks.filter { $0.repeatRule != .none && !$0.isGeneratedFromRepeat }
            
            var currentDate = today
            while currentDate <= endDate {
                for task in repeatingTasks {
                    if shouldIncludeRepeatingTask(task: task, for: currentDate) {
                        let startOfDay = calendar.startOfDay(for: currentDate)
                        taskCounts[startOfDay, default: 0] += 1
                    }
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            return taskCounts
        } catch {
            print("TimelineViewModel: Error getting task counts: \(error)")
            return [:]
        }
    }
    
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
            print("TimelineViewModel: Context saved successfully")
        } catch {
            print("TimelineViewModel: Error saving context: \(error)")
        }
    }
    
    func clearAllTasks() {
        guard let modelContext = modelContext else {
            print("TimelineViewModel: No modelContext available")
            return
        }

        let descriptor = FetchDescriptor<Task>()

        do {
            let allTasks = try modelContext.fetch(descriptor)
            for task in allTasks {
                modelContext.delete(task)
            }

            try modelContext.save()
            tasks = []
            print("TimelineViewModel: Cleared all tasks")
        } catch {
            print("TimelineViewModel: Error clearing tasks: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Sample Data (for testing)
    
    private func createSampleTasks() {
        guard let modelContext = modelContext else { return }
        
        let now = Date()
        let calendar = Calendar.current
        
        let sampleTasks = [
            Task(
                title: "Morning Focus Session",
                icon: "💻",
                startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now,
                durationMinutes: 60,
                color: .blue,
                isCompleted: false,
                taskType: .work,
                repeatRule: .daily
            ),
            Task(
                title: "Team Meeting",
                icon: "👥",
                startTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                durationMinutes: 45,
                color: .green,
                taskType: .work,
                repeatRule: .weekly
            ),
            Task(
                title: "Gym Workout",
                icon: "🏋️",
                startTime: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now,
                durationMinutes: 90,
                color: .red,
                taskType: .exercise,
                repeatRule: .daily
            ),
            Task(
                title: "Weekly Review",
                icon: "📊",
                startTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now,
                durationMinutes: 30,
                color: .purple,
                taskType: .work,
                repeatRule: .weekly
            )
        ]
        
        print("TimelineViewModel: Creating \(sampleTasks.count) sample tasks")
        for task in sampleTasks {
            print("  - \(task.title) at \(task.startTime) (repeats: \(task.repeatRule))")
            modelContext.insert(task)
        }
        
        saveContext()
    }
}
