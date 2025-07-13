import SwiftUI

 struct TaskCard: View {
    var title: String
    var time: String
    var icon: String
    var color: Color
    var isCompleted: Bool
    var durationMinutes: Int = 60
    var task: Task? = nil // Optional task for advanced progress tracking
    
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        let minHeight: CGFloat = 50
        let maxHeight: CGFloat = 200
        // Scale height based on duration (15min = minHeight, 240min+ = maxHeight)
        let scaledHeight = minHeight + (CGFloat(durationMinutes) / 240.0) * (maxHeight - minHeight)
        let height = isCompleted ? minHeight : max(minHeight, min(maxHeight, scaledHeight))
        
        // Calculate progress based on task timing
        let progressInfo = calculateProgress()
        let shouldShowProgress = progressInfo.shouldShow
        let progressPercentage = progressInfo.percentage
        let progressColor = progressInfo.color
        let taskState = getTaskState()
    
        HStack(alignment: .center, spacing: 12) {
               ZStack {
                   if !isCompleted  &&  shouldShowProgress  {
                        Rectangle()
                               .fill(LinearGradient(
                               gradient: Gradient(colors: [
                                   taskState.progressColor.opacity(0.8),
                                   taskState.progressColor.opacity(0.8),
                                   Color.clear
                               ]),
                               startPoint: .top,
                               endPoint: .bottom
                           ))
                           .frame(width: 50, height: height * 0.7)
                           .cornerRadius(2)
                           .offset(y:-20)
                   }
                   
                   Text(icon)
                       .frame(width: 50, height: height)
                    
               }
               .background(isCompleted ? color : AppColors.lightGray)
               .cornerRadius(40)
               .overlay(
                   RoundedRectangle(cornerRadius: 40)
                    .stroke(isCompleted ? color  : AppColors.accent.opacity(0.2), lineWidth: 1)
               )
                        
               VStack(alignment: .leading, spacing: 4) {
                   Text(time)
                       .font(AppFonts.caption())
                       .foregroundColor(AppColors.textSecondary)
                   
                   Text(title)
                       .font(AppFonts.headline())
                       .foregroundColor(AppColors.textPrimary)
               }

               Spacer()
               
               if isCompleted {
                   Image(systemName: "checkmark.circle.fill")
                       .foregroundColor(AppColors.accent)
               } else {
                   EmptyView()
               }
           }
           .padding(
               .horizontal, 16
           )

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
            
            // Color based on progress and task status
            let progressColor: Color
            if task.isActive {
                progressColor = .green // Currently running
            } else if progress > 0.8 {
                progressColor = .orange // Almost overdue
            } else {
                progressColor = color // Normal progress
            }
            
            return (true, progress, progressColor)
        }
        
        // If task is overdue (past end time)
        if now > taskEndTime {
            let progressColor: Color = task.isActive ? .red : .orange
            return (true, 1.0, progressColor)
        }
        
        return (false, 0.0, color)
    }
    
    // MARK: - Task State and Formatting
    private func getTaskState() -> (backgroundColor: Color, progressColor: Color, textColor: Color) {
        guard let task = task else {
            return (AppColors.lightGray, color, .gray)
        }
        
        let now = currentTime
        let taskStartTime = task.startTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        if task.isCompleted {
            return (color.opacity(0.2), .green, .white)
        } else if task.isActive {
            return (.green.opacity(0.2), .green, .white)
        } else if now >= taskStartTime && now <= taskEndTime {
            // Should be active but isn't
            return (.orange.opacity(0.2), .orange, .white)
        } else if now > taskEndTime {
            // Overdue
            return (.red.opacity(0.2), .red, .white)
        } else {
            // Not started yet
            return (AppColors.lightGray, color, .gray)
        }
    }
    
    private func formatTaskTime(_ task: Task) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let now = currentTime
        let taskStartTime = task.startTime
        let taskEndTime = task.startTime.addingTimeInterval(TimeInterval(task.durationMinutes * 60))
        
        if task.isActive {
            return "LIVE"
        } else if now < taskStartTime {
            return formatter.string(from: taskStartTime)
        } else if now >= taskStartTime && now <= taskEndTime {
            return "NOW"
        } else if now > taskEndTime {
            return "LATE"
        } else {
            return formatter.string(from: taskStartTime)
        }
    }
}


#Preview {
    TaskCard(title: "Task 1", time: "1h 30m", icon: "⏰", color: .blue, isCompleted: true , durationMinutes:220
    )
    TaskCard(title: "Task 1", time: "1h 30m", icon: "⏰", color: .red, isCompleted: false , durationMinutes:120)

}
