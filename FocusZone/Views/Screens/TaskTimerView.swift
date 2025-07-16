import SwiftUI
import SwiftData

struct TaskTimerView: View {
    let task: Task
    @StateObject private var timerService = TaskTimerService()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Task Info
                VStack(spacing: 16) {
                    Text(task.icon)
                        .font(.system(size: 60))
                    
                    Text(task.title)
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    if let taskType = task.taskType {
                        HStack(spacing: 8) {
                            Text(taskType.icon)
                                .font(.title3)
                            Text(taskType.displayName)
                                .font(AppFonts.subheadline())
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text("Planned: \(task.durationMinutes) minutes")
                        .font(AppFonts.subheadline())
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 280, height: 280)
                    
                    Circle()
                        .trim(from: 0, to: timerService.currentProgressPercentage)
                        .stroke(
                            timerService.isOvertime ? Color.red : task.color,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: timerService.currentProgressPercentage)
                    
                    VStack(spacing: 8) {
                        Text(timerService.formattedElapsedTime)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(timerService.isOvertime ? .red : AppColors.textPrimary)
                        
                        Text(timerService.isOvertime ? "Overtime!" : "Remaining: \(timerService.formattedRemainingTime)")
                            .font(AppFonts.subheadline())
                            .foregroundColor(.gray)
                        
                        if timerService.currentTask?.status == .paused {
                            Text("PAUSED")
                                .font(AppFonts.caption())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Control Buttons
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        if timerService.currentTask == nil {
                            // Start button
                            Button(action: {
                                timerService.startTask(task)
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.fill")
                                        .font(.title2)
                                    Text("Start")
                                        .font(AppFonts.headline())
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(task.color)
                                .cornerRadius(25)
                            }
                        } else if timerService.currentTask?.isActive ?? false {
                            // Pause and Complete buttons
                            Button(action: {
                                timerService.pauseTask()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "pause.fill")
                                    Text("Pause")
                                }
                                .font(AppFonts.subheadline())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.orange)
                                .cornerRadius(20)
                            }
                            
                            Button(action: {
                                timerService.completeTask()
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Complete")
                                }
                                .font(AppFonts.subheadline())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.green)
                                .cornerRadius(20)
                            }
                        } else if timerService.currentTask?.isPaused ?? false {
                            // Resume and Stop buttons
                            Button(action: {
                                timerService.resumeTask()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                    Text("Resume")
                                }
                                .font(AppFonts.subheadline())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(task.color)
                                .cornerRadius(20)
                            }
                            
                            Button(action: {
                                timerService.stopCurrentTask()
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "stop.fill")
                                    Text("Stop")
                                }
                                .font(AppFonts.subheadline())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red)
                                .cornerRadius(20)
                            }
                        }
                    }
                    
                    // Statistics
                    if let currentTask = timerService.currentTask {
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Time Spent")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.gray)
                                    Text("\(timerService.currentElapsedMinutes)m")
                                        .font(AppFonts.subheadline())
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Progress")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.gray)
                                    Text("\(Int(timerService.currentProgressPercentage * 100))%")
                                        .font(AppFonts.subheadline())
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(AppColors.card)
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Focus Timer")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if timerService.currentTask != nil {
                            timerService.stopCurrentTask()
                        }
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear {
            // Set model context and auto-start the timer when view appears
            timerService.setModelContext(modelContext)
            if timerService.currentTask == nil {
                timerService.startTask(task)
            }
        }
    }
}

#Preview {
    TaskTimerView(task: Task(
        id: UUID(),
        title: "Focus Session",
        icon: "💻",
        startTime: Date(),
        durationMinutes: 60,
        color: .blue,
        isCompleted: false,
        taskType: .work
    ))
}
