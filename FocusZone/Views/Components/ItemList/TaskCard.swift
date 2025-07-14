import SwiftUI

struct TaskCard: View {
    var title: String
    var time: String
    var icon: String
    var color: Color
    var isCompleted: Bool
    var durationMinutes: Int = 60
    var task: Task? = nil
    
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        // Calculate height based on duration (1 minute = 2 points, minimum 60pt)
        let baseHeight: CGFloat = max(60, CGFloat(durationMinutes) * 1)
        let progressInfo = calculateProgress()
        let progressHeight = baseHeight * CGFloat(progressInfo.percentage)
        
        HStack(alignment: .top, spacing: 0) {
            // Left side - Timeline with progress
            VStack(spacing: 0) {
                // Timeline pill/capsule
                ZStack(alignment: .bottom) {
                    // Background capsule (total duration)
                    Capsule()
                        .fill(color.opacity(0.3))
                        .frame(width: 60, height: baseHeight)
                    
                    // Progress fill (only for active tasks)
                    if progressInfo.shouldShow && !isCompleted {
                        VStack {
                            Spacer()
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            progressInfo.color,
                                            progressInfo.color.opacity(0.8)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width:60, height: max(60, progressHeight))
                                .animation(.easeInOut(duration: 0.5), value: progressHeight)
                        }
                    }
                    
                    // Completed state - full fill
                    if isCompleted {
                        Capsule()
                            .fill(color)
                            .frame(width: 60, height: baseHeight)
                    }
                    
                    // Icon container
                    ZStack {
                        Circle()
                            .fill(getIconBackgroundColor())
                            .frame(width: 50, height: 0)
                        
                        Text(icon)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .offset(y: -20) // Slightly below center
                    Spacer(minLength: 0)
                }
                
                // Timeline connector (dashed line)
                if shouldShowConnector() {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 30)
                        .overlay(
                            Rectangle()
                                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .frame(width: 2, height: 30)
                        )
                }
            }
            
          
            // Right side - Task content
            VStack(alignment: .leading, spacing: 8) {
                Spacer(minLength: 0)
                // Time and status
                HStack {
                    Text(formatTimeRange())
                        .font(AppFonts.body())
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Status indicator
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else if progressInfo.shouldShow {
                        Circle()
                            .stroke(progressInfo.color, lineWidth: 3)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .trim(from: 0, to: CGFloat(progressInfo.percentage))
                                    .stroke(progressInfo.color, lineWidth: 3)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.5), value: progressInfo.percentage)
                            )
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                            .frame(width: 24, height: 24)
                    }
                }
                
                // Task title
                Text(title)
                    .font(AppFonts.headline())
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Progress text for active tasks
                if progressInfo.shouldShow && !isCompleted {
                    Text(getProgressText())
                        .font(AppFonts.caption())
                        .foregroundColor(progressInfo.color)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(height: baseHeight)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - Progress Calculation
    private func calculateProgress() -> (shouldShow: Bool, percentage: Double, color: Color) {
        guard let task = task else {
            return (false, 0.0, color)
        }
        
        let now = currentTime
        let taskStartTime = task.startTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        // If task hasn't started yet
        if now < taskStartTime {
            return (false, 0.0, color)
        }
        
        // If task is completed
        if task.isCompleted {
            return (false, 1.0, .green)
        }
        
        // If task is currently active (between start and end time)
        if now >= taskStartTime && now <= taskEndTime {
            let totalDuration = taskEndTime.timeIntervalSince(taskStartTime)
            let elapsed = now.timeIntervalSince(taskStartTime)
            let progress = min(1.0, elapsed / totalDuration)
            
            let progressColor: Color
            if progress < 0.7 {
                progressColor = .green
            } else if progress < 0.9 {
                progressColor = .orange
            } else {
                progressColor = .red
            }
            
            return (true, progress, progressColor)
        }
        
        // If task is overdue (past end time)
        if now > taskEndTime {
            return (true, 1.0, .red)
        }
        
        return (false, 0.0, color)
    }
    
    // MARK: - Helper Methods
    private func getIconBackgroundColor() -> Color {
        if isCompleted {
            return .green
        } else if task != nil {
            let progressInfo = calculateProgress()
            if progressInfo.shouldShow {
                return progressInfo.color
            }
        }
        return color
    }
    
    private func shouldShowConnector() -> Bool {
        // Show connector for all tasks except maybe the last one
        return true
    }
    
    private func formatTimeRange() -> String {
        guard let task = task else {
            return time
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let startTime = task.startTime
        let endTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        let startString = formatter.string(from: startTime).lowercased()
        let endString = formatter.string(from: endTime).lowercased()
        
        let duration = formatDuration()
        
        return "\(startString) - \(endString) (\(duration))"
    }
    
    private func formatDuration() -> String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours) hrs, \(minutes) min" : "\(hours) hrs"
        } else {
            return "\(minutes) min"
        }
    }
    private func getProgressText() -> String {
        guard let task = task else { return "" }
        
        let now = currentTime
        let taskStartTime = task.startTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        // If task hasn't started yet
        if now < taskStartTime {
            let timeUntilStart = taskStartTime.timeIntervalSince(now)
            let minutesUntilStart = Int(timeUntilStart / 60)
            if minutesUntilStart > 60 {
                let hours = minutesUntilStart / 60
                let mins = minutesUntilStart % 60
                return "Starts in \(hours)h \(mins)m"
            } else {
                return "Starts in \(minutesUntilStart)m"
            }
        }
        
        // If task is currently active
        if now >= taskStartTime && now <= taskEndTime {
            let remaining = taskEndTime.timeIntervalSince(now)
            let remainingMinutes = Int(remaining / 60)
            
            if remainingMinutes > 60 {
                let hours = remainingMinutes / 60
                let mins = remainingMinutes % 60
                return mins > 0 ? "\(hours)h \(mins)m remaining" : "\(hours)h remaining"
            } else if remainingMinutes > 0 {
                return "\(remainingMinutes)m remaining"
            } else {
                // Less than a minute remaining
                let remainingSeconds = Int(remaining)
                return "\(remainingSeconds)s remaining"
            }
        } else {
            // Task is overdue
            let overdue = now.timeIntervalSince(taskEndTime)
            let overdueMinutes = Int(overdue / 60)
            
            if overdueMinutes > 60 {
                let hours = overdueMinutes / 60
                let mins = overdueMinutes % 60
                return mins > 0 ? "\(hours)h \(mins)m overdue" : "\(hours)h overdue"
            } else {
                return "\(overdueMinutes)m overdue"
            }
        }
    }
    

}

// MARK: - Timeline View Container
struct _TimelineView: View {
    @State private var selectedDate = Date()
    @State private var tasks: [Task] = sampleTasks
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Date Header
                DateHeader(selectedDate: $selectedDate)
                    .padding(.bottom, 20)
                
                // Timeline
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TaskCard(
                                title: task.title,
                                time: "",
                                icon: task.icon,
                                color: task.color,
                                isCompleted: task.isCompleted,
                                durationMinutes: task.durationMinutes,
                                task: task
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

// MARK: - Sample Data
let sampleTasks: [Task] = [
    Task(
        id: UUID(),
        title: "Rise and Shine",
        icon: "🌅",
        startTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
        durationMinutes: 30,
        color: .pink,
        isCompleted: true
    ),
    Task(
        id: UUID(),
        title: "Keep working",
        icon: "💼",
        startTime: Calendar.current.date(bySettingHour: 16, minute: 11, second: 0, of: Date()) ?? Date(),
        durationMinutes: 120, // 2h 30min
        color: .green,
        isCompleted: false
    ),
    Task(
        id: UUID(),
        title: "Go for a Run!",
        icon: "🏃‍♂️",
        startTime: Calendar.current.date(bySettingHour: 19, minute: 15, second: 0, of: Date()) ?? Date(),
        durationMinutes: 90, // 1h 30min
        color: .orange,
        isCompleted: false
    ),
    Task(
        id: UUID(),
        title: "Wind Down",
        icon: "🌙",
        startTime: Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date(),
        durationMinutes: 60,
        color: .blue,
        isCompleted: false
    )
]

#Preview {
    _TimelineView()
}
