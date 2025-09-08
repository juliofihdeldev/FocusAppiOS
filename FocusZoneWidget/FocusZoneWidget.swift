import WidgetKit
import SwiftUI

// MARK: - iOS Version Compatibility

extension View {
    @ViewBuilder
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            self.background(backgroundView)
        }
    }
}

// MARK: - Widget Entry
struct FocusZoneEntry: TimelineEntry {
    let date: Date
    let currentTask: WidgetTask?
    let upcomingTasks: [WidgetTask]
    let todayTaskCount: Int
    let completedCount: Int
    let dataFreshness: DataFreshness
    
    enum DataFreshness {
        case fresh, stale, noData
    }
}

// MARK: - Widget Provider
struct FocusZoneProvider: TimelineProvider {
    
    // IMPORTANT: Replace with your actual App Group ID
    private let appGroupID = "group.com.jf.Focus"
    
    func placeholder(in context: Context) -> FocusZoneEntry {
        FocusZoneEntry(
            date: Date(),
            currentTask: sampleWidgetTask(),
            upcomingTasks: [sampleWidgetTask(), sampleWidgetTask()],
            todayTaskCount: 5,
            completedCount: 2,
            dataFreshness: .fresh
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FocusZoneEntry) -> ()) {
        let entry = FocusZoneEntry(
            date: Date(),
            currentTask: sampleWidgetTask(),
            upcomingTasks: [sampleWidgetTask()],
            todayTaskCount: 3,
            completedCount: 1,
            dataFreshness: .fresh
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        _Concurrency.Task {
            let entries = await generateEntries()
            
            // Update timeline more frequently during active tasks
            let policy: TimelineReloadPolicy
            if hasActiveTask(entries.first) {
                policy = .after(Date().addingTimeInterval(60)) // 1 minute for active tasks
            } else {
                policy = .after(Date().addingTimeInterval(300)) // 5 minutes for inactive
            }
            
            let timeline = Timeline(entries: entries, policy: policy)
            completion(timeline)
        }
    }
    
    private func generateEntries() async -> [FocusZoneEntry] {
        let now = Date()
        var entries: [FocusZoneEntry] = []
        
        // Get data from UserDefaults
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            print("FocusZoneWidget: Failed to access App Group UserDefaults")
            return [createNoDataEntry(at: now)]
        }
        
        let currentTask = getCurrentTaskFromDefaults(userDefaults)
        let upcomingTasks = getUpcomingTasksFromDefaults(userDefaults)
        let todayTaskCount = userDefaults.integer(forKey: "todayTaskCount")
        let completedCount = userDefaults.integer(forKey: "completedCount")
        let lastUpdate = Date(timeIntervalSince1970: userDefaults.double(forKey: "lastUpdate"))
        
        // Determine data freshness
        let dataAge = now.timeIntervalSince(lastUpdate)
        let dataFreshness: FocusZoneEntry.DataFreshness
        if dataAge > 3600 { // 1 hour
            dataFreshness = .noData
        } else if dataAge > 300 { // 5 minutes
            dataFreshness = .stale
        } else {
            dataFreshness = .fresh
        }
        
        // Generate entries for different time periods
        let timeIntervals = generateTimeIntervals(hasActiveTask: currentTask?.isCurrentlyActive == true)
        
        for interval in timeIntervals {
            let entryDate = now.addingTimeInterval(interval)
            
            let entry = FocusZoneEntry(
                date: entryDate,
                currentTask: getCurrentTaskAtTime(
                    currentTask: currentTask,
                    upcomingTasks: upcomingTasks,
                    targetTime: entryDate
                ),
                upcomingTasks: getUpcomingTasksAtTime(
                    tasks: upcomingTasks,
                    targetTime: entryDate
                ),
                todayTaskCount: todayTaskCount,
                completedCount: completedCount,
                dataFreshness: dataFreshness
            )
            
            entries.append(entry)
        }
        
        // Ensure we have at least one entry
        if entries.isEmpty {
            entries.append(createNoDataEntry(at: now))
        }
        
        return entries
    }
    
    private func generateTimeIntervals(hasActiveTask: Bool) -> [TimeInterval] {
        var intervals: [TimeInterval] = [0] // Now
        
        if hasActiveTask {
            // More frequent updates during active tasks
            for minutes in [1, 2, 5, 10, 15, 20, 30, 45, 60] {
                intervals.append(TimeInterval(minutes * 60))
            }
        } else {
            // Less frequent updates when no active task
            for minutes in [5, 15, 30, 60, 120, 240] {
                intervals.append(TimeInterval(minutes * 60))
            }
        }
        
        return intervals
    }
    
    private func getCurrentTaskFromDefaults(_ userDefaults: UserDefaults) -> WidgetTask? {
        guard let data = userDefaults.data(forKey: "currentTask") else { return nil }
        
        do {
            let task = try JSONDecoder().decode(WidgetTask.self, from: data)
            
            // Validate task is still current
            let now = Date()
            if now >= task.startTime && now <= task.endTime && !task.isCompleted {
                return task
            }
            return nil
        } catch {
            print("FocusZoneWidget: Error decoding current task: \(error)")
            return nil
        }
    }
    
    private func getUpcomingTasksFromDefaults(_ userDefaults: UserDefaults) -> [WidgetTask] {
        guard let data = userDefaults.data(forKey: "upcomingTasks") else { return [] }
        
        do {
            let tasks = try JSONDecoder().decode([WidgetTask].self, from: data)
            
            // Filter future tasks only
            let now = Date()
            return tasks.filter { $0.startTime > now && !$0.isCompleted }
        } catch {
            print("FocusZoneWidget: Error decoding upcoming tasks: \(error)")
            return []
        }
    }
    
    private func getCurrentTaskAtTime(currentTask: WidgetTask?, upcomingTasks: [WidgetTask], targetTime: Date) -> WidgetTask? {
        // Check if current task is still active at target time
        if let current = currentTask,
           targetTime >= current.startTime && targetTime <= current.endTime {
            return current
        }
        
        // Check if any upcoming task becomes current at target time
        return upcomingTasks.first { task in
            targetTime >= task.startTime && targetTime <= task.endTime
        }
    }
    
    private func getUpcomingTasksAtTime(tasks: [WidgetTask], targetTime: Date) -> [WidgetTask] {
        return tasks
            .filter { $0.startTime > targetTime }
            .prefix(3)
            .map { $0 }
    }
    
    private func hasActiveTask(_ entry: FocusZoneEntry?) -> Bool {
        return entry?.currentTask?.isCurrentlyActive == true
    }
    
    private func createNoDataEntry(at date: Date) -> FocusZoneEntry {
        return FocusZoneEntry(
            date: date,
            currentTask: nil,
            upcomingTasks: [],
            todayTaskCount: 0,
            completedCount: 0,
            dataFreshness: .noData
        )
    }
    
    private func sampleWidgetTask() -> WidgetTask {
        return WidgetTask(
            id: UUID().uuidString,
            title: "Focus Session",
            icon: "💻",
            startTime: Date(),
            durationMinutes: 60,
            isCompleted: false,
            colorHex: "#0066CC",
            taskTypeRawValue: "work",
            statusRawValue: "scheduled"
        )
    }
}

// MARK: - Widget Views

struct FocusZoneWidgetSmall: View {
    let entry: FocusZoneEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with data freshness indicator
            HStack {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text("Focus")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 2) {
                    dataFreshnessIndicator
                    Text("\(entry.completedCount)/\(entry.todayTaskCount)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Main content
            mainContent
            
            Spacer()
        }
        .padding(12)
        .widgetBackground(backgroundGradient)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if let currentTask = entry.currentTask {
            currentTaskView(currentTask)
        } else if let nextTask = entry.upcomingTasks.first {
            upcomingTaskView(nextTask)
        } else if entry.todayTaskCount > 0 {
            allCompletedView
        } else {
            noTasksView
        }
    }
    
    private func currentTaskView(_ task: WidgetTask) -> some View {
        VStack(spacing: 4) {
            Text(task.icon)
                .font(.title2)
            
            Text(task.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 4, height: 4)
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.2))
            .cornerRadius(4)
            
            if !task.timeRemaining.isEmpty {
                Text(task.timeRemaining)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private func upcomingTaskView(_ task: WidgetTask) -> some View {
        VStack(spacing: 4) {
            Text(task.icon)
                .font(.title2)
            
            Text(task.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text(task.timeUntilStart)
                .font(.caption2)
                .foregroundColor(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(4)
        }
    }
    
    private var allCompletedView: some View {
        VStack(spacing: 4) {
            Text("✅")
                .font(.title2)
            
            Text("All Done!")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("Great work today")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var noTasksView: some View {
        VStack(spacing: 4) {
            Text("📋")
                .font(.title2)
            
            Text("No Tasks")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("Add some tasks")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var dataFreshnessIndicator: some View {
        Group {
            switch entry.dataFreshness {
            case .fresh:
                Circle().fill(Color.green).frame(width: 4, height: 4)
            case .stale:
                Circle().fill(Color.orange).frame(width: 4, height: 4)
            case .noData:
                Circle().fill(Color.red).frame(width: 4, height: 4)
            }
        }
    }
    
    private var backgroundGradient: LinearGradient {
        switch entry.dataFreshness {
        case .fresh:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.8),
                    Color.blue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .stale:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.6),
                    Color.yellow.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .noData:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.6),
                    Color.gray.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct FocusZoneWidgetMedium: View {
    let entry: FocusZoneEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with enhanced progress
            headerSection
            
            // Progress bar with percentage
//            progressSection
            
            // Current task section
            if let currentTask = entry.currentTask {
                currentTaskSection(currentTask)
            }
            
            // Upcoming tasks section
            if !entry.upcomingTasks.isEmpty {
                upcomingTasksSection
            }
            
            Spacer()
        }
        .padding(4)
        .widgetBackground(backgroundGradient)
    }
    
    private var headerSection: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text("Today's Focus")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                dataFreshnessIndicator
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(entry.completedCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("/ \(entry.todayTaskCount)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text("tasks")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(entry.completedCount), total: Double(max(1, entry.todayTaskCount)))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(y: 0.8)
            
            if entry.todayTaskCount > 0 {
                let percentage = Int((Double(entry.completedCount) / Double(entry.todayTaskCount)) * 100)
                Text("\(percentage)% complete")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private func currentTaskSection(_ task: WidgetTask) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("NOW")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Spacer()
                
                if task.isCurrentlyActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 4, height: 4)
                        Text("LIVE")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            
            HStack(spacing: 8) {
                Text(task.icon)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(task.formattedTimeRange)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        if !task.timeRemaining.isEmpty {
                            Text("• \(task.timeRemaining)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Progress indicator for current task
                if task.isCurrentlyActive {
                    CircularProgressView(progress: task.progress)
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            ForEach(Array(entry.upcomingTasks.prefix(1).enumerated()), id: \.offset) { index, task in
                HStack(spacing: 8) {
                    Text(task.icon)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(task.title)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                        
                        Text(task.timeUntilStart)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text(task.formattedStartTime)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(index == 0 ? 1.0 : 0.7)
            }
        }
    }
    
    private var dataFreshnessIndicator: some View {
        Group {
            switch entry.dataFreshness {
            case .fresh:
                Circle().fill(Color.green).frame(width: 4, height: 4)
            case .stale:
                Circle().fill(Color.orange).frame(width: 4, height: 4)
            case .noData:
                Circle().fill(Color.red).frame(width: 4, height: 4)
            }
        }
    }
    
    private var backgroundGradient: LinearGradient {
        switch entry.dataFreshness {
        case .fresh:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.8),
                    Color.blue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .stale:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.6),
                    Color.yellow.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .noData:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.6),
                    Color.gray.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Supporting Views

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.green, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

// MARK: - Widget Configuration

struct FocusZoneWidget: Widget {
    let kind: String = "FocusZoneWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusZoneProvider()) { entry in
            FocusZoneWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focus Tracker")
        .description("Stay focused with your current and upcoming tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FocusZoneWidgetEntryView: View {
    var entry: FocusZoneProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            FocusZoneWidgetSmall(entry: entry)
        case .systemMedium:
            FocusZoneWidgetMedium(entry: entry)
        default:
            FocusZoneWidgetSmall(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct FocusZoneWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusZoneWidget()
        FocusZoneWidgetLiveActivity()
    }
}

// MARK: - Previews

struct FocusZoneWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Active task preview
            FocusZoneWidgetEntryView(entry: FocusZoneEntry(
                date: Date(),
                currentTask: WidgetTask(
                    id: UUID().uuidString,
                    title: "Deep Work Session",
                    icon: "💻",
                    startTime: Date().addingTimeInterval(-900), // Started 15 min ago
                    durationMinutes: 90,
                    isCompleted: false,
                    colorHex: "#0066CC",
                    taskTypeRawValue: "work",
                    statusRawValue: "inProgress"
                ),
                upcomingTasks: [
                    WidgetTask(
                        id: UUID().uuidString,
                        title: "Team Meeting",
                        icon: "👥",
                        startTime: Date().addingTimeInterval(3600),
                        durationMinutes: 30,
                        isCompleted: false,
                        colorHex: "#00CC66",
                        taskTypeRawValue: "work",
                        statusRawValue: "scheduled"
                    ),
                 
                ],
                todayTaskCount: 5,
                completedCount: 2,
                dataFreshness: .fresh
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small - Active Task")
            
            // Upcoming task preview
            FocusZoneWidgetEntryView(entry: FocusZoneEntry(
                date: Date(),
                currentTask: nil,
                upcomingTasks: [
                    WidgetTask(
                        id: UUID().uuidString,
                        title: "Morning Exercise",
                        icon: "🏃‍♂️",
                        startTime: Date().addingTimeInterval(1800), // In 30 minutes
                        durationMinutes: 45,
                        isCompleted: false,
                        colorHex: "#FF6600",
                        taskTypeRawValue: "exercise",
                        statusRawValue: "scheduled"
                    ),
                    WidgetTask(
                        id: UUID().uuidString,
                        title: "Code Review ",
                        icon: "👥",
                        startTime: Date().addingTimeInterval(3600),
                        durationMinutes: 30,
                        isCompleted: false,
                        colorHex: "#00CC66",
                        taskTypeRawValue: "work",
                        statusRawValue: "scheduled"
                    )
                ],
                todayTaskCount: 4,
                completedCount: 1,
                dataFreshness: .fresh
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium - Upcoming Tasks")
            
            // No data preview
            FocusZoneWidgetEntryView(entry: FocusZoneEntry(
                date: Date(),
                currentTask: nil,
                upcomingTasks: [],
                todayTaskCount: 0,
                completedCount: 0,
                dataFreshness: .noData
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small - No Data")
        }
    }
}
