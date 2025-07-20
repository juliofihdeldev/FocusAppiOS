import Foundation
import WidgetKit

// MARK: - WidgetTask Model (Shared between app and widget)

struct WidgetTask: Codable, Identifiable {
    let id: String
    let title: String
    let icon: String
    let startTime: Date
    let durationMinutes: Int
    let isCompleted: Bool
    let colorHex: String
    let taskTypeRawValue: String?
    let statusRawValue: String
    
    // Computed properties for easier access
    var color: String {
        return colorHex
    }
    
    var taskType: String? {
        return taskTypeRawValue
    }
    
    var endTime: Date {
        return startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }
    
    var isCurrentlyActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime && !isCompleted && statusRawValue != "cancelled"
    }
    
    var progress: Double {
        guard isCurrentlyActive else { return 0.0 }
        
        let now = Date()
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsed = now.timeIntervalSince(startTime)
        
        return min(1.0, max(0.0, elapsed / totalDuration))
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
    
    var timeUntilStart: String {
        let now = Date()
        let interval = startTime.timeIntervalSince(now)
        let minutes = Int(interval / 60)
        
        if minutes < 0 {
            return "Started"
        } else if minutes == 0 {
            return "Starting now"
        } else if minutes < 60 {
            return "in \(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "in \(hours)h \(remainingMinutes)m" : "in \(hours)h"
        }
    }
    
    var timeRemaining: String {
        guard isCurrentlyActive else { return "" }
        
        let now = Date()
        let remaining = endTime.timeIntervalSince(now)
        let minutes = Int(remaining / 60)
        
        if minutes <= 0 {
            return "Ending soon"
        } else if minutes < 60 {
            return "\(minutes)m left"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m left" : "\(hours)h left"
        }
    }
}

// MARK: - WidgetDataManager

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // IMPORTANT: Replace with your actual App Group ID
    private let appGroupID = "group.focus.jf.com.FocusZone"
    private let userDefaults: UserDefaults?
    
    // Keys for UserDefaults
    private enum Keys {
        static let currentTask = "currentTask"
        static let upcomingTasks = "upcomingTasks"
        static let todayTaskCount = "todayTaskCount"
        static let completedCount = "completedCount"
        static let lastUpdate = "lastUpdate"
        static let lastUpdateDate = "lastUpdateDate"
    }
    
    private init() {
        self.userDefaults = UserDefaults(suiteName: appGroupID)
        cleanupStaleData()
    }
    
    // MARK: - Update Widget Data (Generic approach)
    
    func updateWidgetData<T>(tasks: [T]) where T: AnyObject {
        guard let userDefaults = userDefaults else {
            print("WidgetDataManager: Failed to initialize UserDefaults with app group")
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Filter today's tasks using reflection to access properties
        let todayTasks = tasks.filter { task in
            if let startTime = getValue(from: task, key: "startTime") as? Date {
                return calendar.isDateInToday(startTime)
            }
            return false
        }
        
        // Find current task
        let currentTask = todayTasks.first { task in
            guard let startTime = getValue(from: task, key: "startTime") as? Date,
                  let durationMinutes = getValue(from: task, key: "durationMinutes") as? Int,
                  let isCompleted = getValue(from: task, key: "isCompleted") as? Bool else {
                return false
            }
            
            let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
            return now >= startTime && now <= endTime && !isCompleted
        }
        
        // Find upcoming tasks
        let upcomingTasks = todayTasks.filter { task in
            guard let startTime = getValue(from: task, key: "startTime") as? Date,
                  let isCompleted = getValue(from: task, key: "isCompleted") as? Bool else {
                return false
            }
            return startTime > now && !isCompleted
        }.sorted { task1, task2 in
            guard let startTime1 = getValue(from: task1, key: "startTime") as? Date,
                  let startTime2 = getValue(from: task2, key: "startTime") as? Date else {
                return false
            }
            return startTime1 < startTime2
        }.prefix(3)
        
        let completedCount = todayTasks.filter { task in
            if let isCompleted = getValue(from: task, key: "isCompleted") as? Bool {
                return isCompleted
            }
            return false
        }.count
        
        // Store data with error handling
        do {
            // Store current task
            if let currentTask = currentTask {
                let widgetTask = createWidgetTask(from: currentTask)
                let currentTaskData = try JSONEncoder().encode(widgetTask)
                userDefaults.set(currentTaskData, forKey: Keys.currentTask)
            } else {
                userDefaults.removeObject(forKey: Keys.currentTask)
            }
            
            // Store upcoming tasks
            let widgetUpcomingTasks = Array(upcomingTasks).map { createWidgetTask(from: $0) }
            let upcomingTasksData = try JSONEncoder().encode(widgetUpcomingTasks)
            userDefaults.set(upcomingTasksData, forKey: Keys.upcomingTasks)
            
            // Store counts and metadata
            userDefaults.set(todayTasks.count, forKey: Keys.todayTaskCount)
            userDefaults.set(completedCount, forKey: Keys.completedCount)
            userDefaults.set(now.timeIntervalSince1970, forKey: Keys.lastUpdate)
            userDefaults.set(calendar.startOfDay(for: now).timeIntervalSince1970, forKey: Keys.lastUpdateDate)
            
            print("WidgetDataManager: Updated data - Upcoming: \(upcomingTasks.count), Completed: \(completedCount)/\(todayTasks.count)")
            
        } catch {
            print("WidgetDataManager: Error encoding data: \(error)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func getValue(from object: AnyObject, key: String) -> Any? {
        let mirror = Mirror(reflecting: object)
        for child in mirror.children {
            if child.label == key {
                return child.value
            }
        }
        return nil
    }
    
    private func createWidgetTask(from task: AnyObject) -> WidgetTask {
        let id = getValue(from: task, key: "id") as? UUID
        let title = getValue(from: task, key: "title") as? String
        let icon = getValue(from: task, key: "icon") as? String
        let startTime = getValue(from: task, key: "startTime") as? Date
        let durationMinutes = getValue(from: task, key: "durationMinutes") as? Int
        let isCompleted = getValue(from: task, key: "isCompleted") as? Bool
        let colorHex = getValue(from: task, key: "colorHex") as? String
        let taskTypeRawValue = getValue(from: task, key: "taskTypeRawValue") as? String
        let statusRawValue = getValue(from: task, key: "statusRawValue") as? String
        
        return WidgetTask(
            id: id?.uuidString ?? UUID().uuidString,
            title: title ?? "Unknown Task",
            icon: icon ?? "📝",
            startTime: startTime ?? Date(),
            durationMinutes: durationMinutes ?? 30,
            isCompleted: isCompleted ?? false,
            colorHex: colorHex ?? "#0066CC",
            taskTypeRawValue: taskTypeRawValue,
            statusRawValue: statusRawValue ?? "scheduled"
        )
    }
    
    private func cleanupStaleData() {
        guard let userDefaults = userDefaults else { return }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Check if data is from today
        let lastUpdateDate = userDefaults.double(forKey: Keys.lastUpdateDate)
        let lastUpdateDateObj = Date(timeIntervalSince1970: lastUpdateDate)
        
        if !calendar.isDate(lastUpdateDateObj, inSameDayAs: now) {
            print("WidgetDataManager: Cleaning up stale data from previous day")
            clearWidgetData()
        }
    }
    
    // MARK: - Get Widget Data
    
    func getCurrentTask() -> WidgetTask? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: Keys.currentTask) else {
            return nil
        }
        
        do {
            let task = try JSONDecoder().decode(WidgetTask.self, from: data)
            
            // Validate that task is still current
            let now = Date()
            if now >= task.startTime && now <= task.endTime && !task.isCompleted {
                return task
            } else {
                // Task is no longer current, remove it
                userDefaults.removeObject(forKey: Keys.currentTask)
                return nil
            }
        } catch {
            print("WidgetDataManager: Error decoding current task: \(error)")
            return nil
        }
    }
    
    func getUpcomingTasks() -> [WidgetTask] {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: Keys.upcomingTasks) else {
            return []
        }
        
        do {
            let tasks = try JSONDecoder().decode([WidgetTask].self, from: data)
            
            // Filter out past tasks
            let now = Date()
            let validTasks = tasks.filter { $0.startTime > now && !$0.isCompleted }
            
            // If filtered list is different, update UserDefaults
            if validTasks.count != tasks.count {
                let validTasksData = try JSONEncoder().encode(validTasks)
                userDefaults.set(validTasksData, forKey: Keys.upcomingTasks)
            }
            
            return validTasks
        } catch {
            print("WidgetDataManager: Error decoding upcoming tasks: \(error)")
            return []
        }
    }
    
    func getTodayTaskCount() -> Int {
        return userDefaults?.integer(forKey: Keys.todayTaskCount) ?? 0
    }
    
    func getCompletedCount() -> Int {
        return userDefaults?.integer(forKey: Keys.completedCount) ?? 0
    }
    
    func getLastUpdateTime() -> Date {
        let timestamp = userDefaults?.double(forKey: Keys.lastUpdate) ?? 0
        return Date(timeIntervalSince1970: timestamp)
    }
    
    // MARK: - Clear Data
    
    func clearWidgetData() {
        guard let userDefaults = userDefaults else { return }
        
        userDefaults.removeObject(forKey: Keys.currentTask)
        userDefaults.removeObject(forKey: Keys.upcomingTasks)
        userDefaults.removeObject(forKey: Keys.todayTaskCount)
        userDefaults.removeObject(forKey: Keys.completedCount)
        userDefaults.removeObject(forKey: Keys.lastUpdate)
        userDefaults.removeObject(forKey: Keys.lastUpdateDate)
        
        print("WidgetDataManager: Cleared all widget data")
    }
    
    // MARK: - Utility Methods
    
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func isDataFresh(maxAge: TimeInterval = 300) -> Bool { // 5 minutes
        let lastUpdate = getLastUpdateTime()
        return Date().timeIntervalSince(lastUpdate) < maxAge
    }
}
