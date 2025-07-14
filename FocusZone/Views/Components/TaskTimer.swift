import SwiftUI
import SwiftData

struct TaskTimer: View {
    @StateObject private var timerService = TaskTimerService()
    @Environment(\.modelContext) private var modelContext
    let task: Task
    
    var body: some View {
        VStack(spacing: 20) {
            // Task Info
            VStack(spacing: 8) {
                Text(task.title)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Image(systemName: task.icon)
                        .foregroundColor(task.color)
                    Text("Planned: \(task.durationMinutes)m")
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                }
            }
            
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: timerService.currentProgressPercentage)
                    .stroke(
                        timerService.isOvertime ? Color.red : task.color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: timerService.currentProgressPercentage)
                
                VStack(spacing: 4) {
                    Text(timerService.formattedElapsedTime)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(timerService.isOvertime ? .red : AppColors.textPrimary)
                    
                    Text(timerService.isOvertime ? "Overtime" : "Remaining: \(timerService.formattedRemainingTime)")
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                }
            }
            
            // Control Buttons
            HStack(spacing: 20) {
                if timerService.currentTask == nil {
                    // Start button
                    Button(action: {
                        timerService.startTask(task)
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start")
                        }
                        .font(AppFonts.subheadline())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(task.color)
                        .cornerRadius(25)
                    }
                } else if timerService.currentTask?.isActive ?? false {
                    // Pause button
                    Button(action: {
                        timerService.pauseTask()
                    }) {
                        HStack {
                            Image(systemName: "pause.fill")
                            Text("Pause")
                        }
                        .font(AppFonts.subheadline())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(25)
                    }
                    
                    // Complete button
                    Button(action: {
                        timerService.completeTask()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete")
                        }
                        .font(AppFonts.subheadline())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(25)
                    }
                } else if timerService.currentTask?.isPaused ?? false {
                    // Resume button
                    Button(action: {
                        timerService.resumeTask()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .font(AppFonts.subheadline())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(task.color)
                        .cornerRadius(25)
                    }
                    
                    // Stop button
                    Button(action: {
                        timerService.stopCurrentTask()
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .font(AppFonts.subheadline())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(25)
                    }
                }
            }
            
            // Task Status
            if let currentTask = timerService.currentTask {
                VStack(spacing: 8) {
                    Text("Status: \(statusText(for: currentTask.status))")
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                    
                    if currentTask.timeSpentMinutes > 0 {
                        Text("Total time spent: \(currentTask.timeSpentMinutes)m")
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .shadow(radius: 4)
        )
//        .onAppear {
//            timerService.setModelContext(modelContext)
//        }
    }
    
    private func statusText(for status: TaskStatus) -> String {
        switch status {
        case .scheduled:
            return "Scheduled"
        case .inProgress:
            return "In Progress"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
}

#Preview {
    TaskTimer(task: Task(
        id: UUID(),
        title: "Sample Task",
        icon: "clock",
        startTime: Date(),
        durationMinutes: 30,
        color: .blue,
        isCompleted: false,
        taskType: .work
    ))
}
