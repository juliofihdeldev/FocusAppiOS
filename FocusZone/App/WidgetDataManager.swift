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

// MARK: - Updated WidgetDataManager with better Task support

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // ⚠️ IMPORTANT: Make sure this matches your actual App Group ID
    private let appGroupID = "group.com.jf.FocusZone"
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
        
        // Debug: Check if UserDefaults is working
        if userDefaults == nil {
            print("❌ CRITICAL: UserDefaults with app group '\(appGroupID)' failed to initialize")
            print("❌ Check if App Group is properly configured in target settings")
        } else {
            print("✅ WidgetDataManager initialized with app group: \(appGroupID)")
        }
        
        cleanupStaleData()
    }
    
    // MARK: - Simplified Task-specific update method
    
    func updateWidgetData(tasks: [Task]) {
        guard let userDefaults = userDefaults else {
            print("❌ WidgetDataManager: UserDefaults not available")
            return
        }
        
        print("🔄 Updating widget data with \(tasks.count) tasks")
        
        let now = Date()
        let calendar = Calendar.current
        
        // Filter today's tasks
        let todayTasks = tasks.filter { task in
            let isToday = calendar.isDateInToday(task.startTime)
            print("📅 Task '\(task.title)' - Start: \(task.startTime), IsToday: \(isToday)")
            return isToday
        }
        
        print("📋 Today's tasks: \(todayTasks.count)")
        
        // Find current task (active now)
        let currentTask = todayTasks.first { task in
            let endTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
            let isCurrent = now >= task.startTime && now <= endTime && !task.isCompleted
            print("⏰ Task '\(task.title)' - Current: \(isCurrent), Start: \(task.startTime), End: \(endTime)")
            return isCurrent
        }
        
        // Find upcoming tasks
        let upcomingTasks = todayTasks.filter { task in
            let isUpcoming = task.startTime > now && !task.isCompleted
            print("⏭️ Task '\(task.title)' - Upcoming: \(isUpcoming)")
            return isUpcoming
        }.sorted { $0.startTime < $1.startTime }.prefix(3)
        
        let completedCount = todayTasks.filter { $0.isCompleted }.count
        
        print("📊 Widget summary: Current: \(currentTask?.title ?? "None"), Upcoming: \(upcomingTasks.count), Completed: \(completedCount)")
        
        // Store data
        do {
            // Store current task
            if let currentTask = currentTask {
                let widgetTask = createWidgetTask(from: currentTask)
                let data = try JSONEncoder().encode(widgetTask)
                userDefaults.set(data, forKey: Keys.currentTask)
                print("✅ Stored current task: \(widgetTask.title)")
            } else {
                userDefaults.removeObject(forKey: Keys.currentTask)
                print("🚫 No current task")
            }
            
            // Store upcoming tasks
            let widgetUpcomingTasks = Array(upcomingTasks).map { createWidgetTask(from: $0) }
            let upcomingData = try JSONEncoder().encode(widgetUpcomingTasks)
            userDefaults.set(upcomingData, forKey: Keys.upcomingTasks)
            print("✅ Stored \(widgetUpcomingTasks.count) upcoming tasks")
            
            // Store metadata
            userDefaults.set(todayTasks.count, forKey: Keys.todayTaskCount)
            userDefaults.set(completedCount, forKey: Keys.completedCount)
            userDefaults.set(now.timeIntervalSince1970, forKey: Keys.lastUpdate)
            userDefaults.set(calendar.startOfDay(for: now).timeIntervalSince1970, forKey: Keys.lastUpdateDate)
            
            print("✅ Widget data updated successfully")
            
            // Force widget refresh
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            print("❌ Error storing widget data: \(error)")
        }
    }
    
    // MARK: - Create WidgetTask from Task
    
    private func createWidgetTask(from task: Task) -> WidgetTask {
        return WidgetTask(
            id: task.id.uuidString,
            title: task.title,
            icon: task.icon,
            startTime: task.startTime,
            durationMinutes: task.durationMinutes,
            isCompleted: task.isCompleted,
            colorHex: task.colorHex,
            taskTypeRawValue: task.taskTypeRawValue,
            statusRawValue: task.statusRawValue
        )
    }
    
    // MARK: - Get Widget Data
    
    func getCurrentTask() -> WidgetTask? {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: Keys.currentTask) else {
            print("🚫 No current task data")
            return nil
        }
        
        do {
            let task = try JSONDecoder().decode(WidgetTask.self, from: data)
            
            // Validate that task is still current
            let now = Date()
            if task.isCurrentlyActive {
                print("✅ Current task: \(task.title)")
                return task
            } else {
                // Task is no longer current, remove it
                userDefaults.removeObject(forKey: Keys.currentTask)
                print("🚫 Current task expired, removed")
                return nil
            }
        } catch {
            print("❌ Error decoding current task: \(error)")
            return nil
        }
    }
    
    func getUpcomingTasks() -> [WidgetTask] {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: Keys.upcomingTasks) else {
            print("🚫 No upcoming tasks data")
            return []
        }
        
        do {
            let tasks = try JSONDecoder().decode([WidgetTask].self, from: data)
            let now = Date()
            let validTasks = tasks.filter { $0.startTime > now && !$0.isCompleted }
            
            print("✅ Upcoming tasks: \(validTasks.count)")
            return validTasks
        } catch {
            print("❌ Error decoding upcoming tasks: \(error)")
            return []
        }
    }
    
    func getTodayTaskCount() -> Int {
        let count = userDefaults?.integer(forKey: Keys.todayTaskCount) ?? 0
        print("📋 Today task count: \(count)")
        return count
    }
    
    func getCompletedCount() -> Int {
        let count = userDefaults?.integer(forKey: Keys.completedCount) ?? 0
        print("✅ Completed count: \(count)")
        return count
    }
    
    // MARK: - Debug methods
    
    func debugWidgetData() {
        print("\n🔍 WIDGET DEBUG:")
        print("App Group ID: \(appGroupID)")
        print("UserDefaults available: \(userDefaults != nil)")
        
        let current = getCurrentTask()
        let upcoming = getUpcomingTasks()
        let todayCount = getTodayTaskCount()
        let completedCount = getCompletedCount()
        
        print("Current task: \(current?.title ?? "None")")
        print("Upcoming tasks: \(upcoming.count)")
        print("Today total: \(todayCount)")
        print("Completed: \(completedCount)")
        
        if let userDefaults = userDefaults {
            let lastUpdate = userDefaults.double(forKey: Keys.lastUpdate)
            print("Last update: \(Date(timeIntervalSince1970: lastUpdate))")
        }
    }
    
    // MARK: - Helper methods
    
    private func cleanupStaleData() {
        guard let userDefaults = userDefaults else { return }
        
        let now = Date()
        let calendar = Calendar.current
        
        let lastUpdateDate = userDefaults.double(forKey: Keys.lastUpdateDate)
        let lastUpdateDateObj = Date(timeIntervalSince1970: lastUpdateDate)
        
        if !calendar.isDate(lastUpdateDateObj, inSameDayAs: now) {
            print("🧹 Cleaning up stale widget data")
            clearWidgetData()
        }
    }
    
    func clearWidgetData() {
        guard let userDefaults = userDefaults else { return }
        
        userDefaults.removeObject(forKey: Keys.currentTask)
        userDefaults.removeObject(forKey: Keys.upcomingTasks)
        userDefaults.removeObject(forKey: Keys.todayTaskCount)
        userDefaults.removeObject(forKey: Keys.completedCount)
        userDefaults.removeObject(forKey: Keys.lastUpdate)
        userDefaults.removeObject(forKey: Keys.lastUpdateDate)
        
        print("🧹 Cleared all widget data")
    }
    
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 Requested widget reload")
    }
}

// MARK: - Updated TimelineViewModel

