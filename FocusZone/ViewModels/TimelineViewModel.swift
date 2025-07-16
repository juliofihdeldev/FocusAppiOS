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
            
            tasks = allTasks.filter { task in
                let isToday = task.startTime >= startOfDay && task.startTime < endOfDay
                
                let repeatsToday = shouldIncludeRepeatingTask(task: task, for: date)
                
                return isToday || repeatsToday
            }
            
            print("TimelineViewModel: Loaded \(tasks.count) tasks for \(date)")
            
            if tasks.isEmpty {
    //            createSampleTasks()
                tasks = try modelContext.fetch(descriptor).filter { task in
                    let isToday = task.startTime >= startOfDay && task.startTime < endOfDay
                    let repeatsToday = shouldIncludeRepeatingTask(task: task, for: date)
                    return isToday || repeatsToday
                }
            }
            
        } catch {
            print("TimelineViewModel: Error loading tasks: \(error)")
            tasks = []
        }
    }
    
    private func shouldIncludeRepeatingTask(task: Task, for date: Date) -> Bool {
        let rule = task.repeatRule
        let calendar = Calendar.current
        
        let startOfDay = calendar.startOfDay(for: date)
        
        switch rule {
        case .daily:
            return startOfDay >= calendar.startOfDay(for: task.startTime)
            
        case .weekly:
            let taskWeekday = calendar.component(.weekday, from: task.startTime)
            let dateWeekday = calendar.component(.weekday, from: date)
            return dateWeekday == taskWeekday &&
                   startOfDay >= calendar.startOfDay(for: task.startTime)
            
        case .monthly:
            let taskDay = calendar.component(.day, from: task.startTime)
            let dateDay = calendar.component(.day, from: date)
            return dateDay == taskDay &&
                   startOfDay >= calendar.startOfDay(for: task.startTime)
            
        default:
            return false
        }
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
        modelContext.delete(task)
        saveContext()
        refreshTasks()
    }
    
    func _deleteTask(_ task: Task) {
        guard let modelContext = modelContext else { return }

          // First remove from local array for immediate UI update
          if let index = tasks.firstIndex(where: { $0.id == task.id }) {
              tasks.remove(at: index)
          }
          
          // Then delete from persistent storage
        modelContext.delete(task)

          
          // Force a refresh to ensure consistency
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              self.refreshTasks()
          }
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
            repeatRule: task.repeatRule
        )
        
        modelContext.insert(duplicatedTask)
        saveContext()
        refreshTasks()
    }
    
    func completeTask(_ task: Task) {
        task.isCompleted = true
        task.status = .completed
        task.updatedAt = Date()
        saveContext()
        refreshTasks()
    }
    
    func addTask(_ task: Task) {
        print("Log>>>>>",task.title)
        print("Log>>>>>", task.icon)
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
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.startTime)]
        )
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            let today = Date()
            tasks = allTasks.filter { task in
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: today)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let isToday = task.startTime >= startOfDay && task.startTime < endOfDay
                let repeatsToday = shouldIncludeRepeatingTask(task: task, for: today)
                
                return isToday || repeatsToday
            }
        } catch {
            print("TimelineViewModel: Error refreshing tasks: \(error)")
        }
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
            
            for task in allTasks {
                let startOfDay = calendar.startOfDay(for: task.startTime)
                taskCounts[startOfDay, default: 0] += 1
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
    
    private func createSampleTasks() {
        guard let modelContext = modelContext else { return }
        
        let now = Date()
        
        let sampleTasks = [
            Task(
                title: "Morning Focus Session",
                icon: "💻",
                startTime: Calendar.current.date(byAdding: .hour, value: -1, to: now) ?? now,
                durationMinutes: 60,
                color: .blue,
                isCompleted: true,
                taskType: .work
            ),
            Task(
                title: "Deep Learning Study",
                icon: "🧠",
                startTime: now,
                durationMinutes: 120,
                color: .purple,
                taskType: .study
            ),
            Task(
                title: "Team Meeting",
                icon: "👥",
                startTime: Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now,
                durationMinutes: 45,
                color: .green,
                taskType: .work
            ),
            Task(
                title: "Lunch Break",
                icon: "🍽️",
                startTime: Calendar.current.date(byAdding: .hour, value: 3, to: now) ?? now,
                durationMinutes: 60,
                color: .orange,
                taskType: .meal
            )
        ]
        
        print("TimelineViewModel: Creating \(sampleTasks.count) sample tasks")
        for task in sampleTasks {
            print("  - \(task.title) at \(task.startTime)")
            modelContext.insert(task)
        }
        
        saveContext()
    }
}
