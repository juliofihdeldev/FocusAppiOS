
import Foundation
import SwiftUI

class TimelineViewModel: ObservableObject {
    @Published var tasks: [Task] = []

    func loadTodayTasks() {
        // Mock data for now
        tasks = [
            
            Task(id: UUID(), title: "Focus Time", icon: "💻", startTime: Date().addingTimeInterval(-3600), durationMinutes: 60, color: .blue,  isCompleted:true, taskType: .work),
            
            Task(id: UUID(), title: "Learn AI with Deep Learning", icon: "🏋️‍♀️", startTime: Date(), durationMinutes: 120, color: .orange , isCompleted: false, taskType: .study),
            
            Task(id: UUID(), title: "Focus Time", icon: "💻", startTime: Date().addingTimeInterval(3600), durationMinutes: 90, color: .blue,  isCompleted:false, taskType: .work),
            
            Task(id: UUID(), title: "Lunch Break", icon: "🍽", startTime: Date().addingTimeInterval(7200), durationMinutes: 160, color: .orange,  isCompleted:false, taskType: .meal)
        ]
    }
    
    func timeRange(for task: Task) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let endTime = task.startTime.addingTimeInterval(Double(task.durationMinutes) * 60)
        return "\(formatter.string(from: task.startTime)) - \(formatter.string(from: endTime))"
    }
    
    func taskColor(_ task: Task) -> Color {
        // if task start we set a color
        // let isTaskStarted =  !task.isCompleted  //&& Date().timeIntervalSince(task.startTime) < Double(task.durationMinutes) * 60
        return  task.color //isTaskStarted ? task.color : .gray
    }
    
    func timeSpentOnTask (for task: Task) -> Double {
        let isTaskStarted =  !task.isCompleted
        return isTaskStarted ? Date().timeIntervalSince(task.startTime) : 0
    }
    
    func scrollToNow() {
        // Placeholder: implement time-based scrolling when timeline uses ID-based anchors
        print("Scroll to current time")
    }
    
    // MARK: - Task Management Actions
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func duplicateTask(_ task: Task) {
        // Create a new Task instance with modified properties
        var duplicatedTask = Task(
            id: UUID(),
            title: "\(task.title) (Copy)",
            icon: task.icon,
            startTime: task.startTime.addingTimeInterval(3600), // Add 1 hour
            durationMinutes: task.durationMinutes,
            color: task.color,
            isCompleted: false,
            taskType: task.taskType
        )
        duplicatedTask.status = .scheduled
        duplicatedTask.timeSpentMinutes = 0
        duplicatedTask.actualStartTime = nil
        
        tasks.append(duplicatedTask)
        sortTasks()
    }
    
    func completeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            // Create a new Task instance with completed status
            var completedTask = Task(
                id: task.id,
                title: task.title,
                icon: task.icon,
                startTime: task.startTime,
                durationMinutes: task.durationMinutes,
                color: task.color,
                isCompleted: true,
                taskType: task.taskType
            )
            completedTask.status = .completed(timeSpent: task.timeSpentMinutes, completedAt: Date())
            completedTask.timeSpentMinutes = task.timeSpentMinutes
            completedTask.actualStartTime = task.actualStartTime
            tasks[index] = completedTask
        }
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        sortTasks()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            sortTasks()
        }
    }
    
    private func sortTasks() {
        tasks.sort { $0.startTime < $1.startTime }
    }
}

