import SwiftUI
import SwiftData

struct TaskTimer: View {
    @ObservedObject private var timerService = TaskTimerService.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss: DismissAction
    let task: Task

    @State private var showCompletionAlert = false
    @State private var showCelebration = false
    @State private var isAutoCompleted = false
    @StateObject private var focusManager = FocusModeManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                // Task Info Header
                VStack(spacing: 12) {
                    Text(task.icon)
                        .font(.system(size: 60))
                    
                    Text(task.title)
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        if let taskType = task.taskType {
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
                .padding(.top, 20)
                
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
                        .animation(.easeInOut(duration: 0.3), value: timerService.currentProgressPercentage)
                    
                    VStack(spacing: 8) {
                        Text(timerService.formattedElapsedTime)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(timerService.isOvertime ? .red : AppColors.textPrimary)
                        
                        if timerService.currentTask?.isCompleted == true {
                            Text("COMPLETED!")
                                .font(AppFonts.headline())
                                .foregroundColor(.green)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        } else if timerService.isOvertime {
                            Text("OVERTIME!")
                                .font(AppFonts.subheadline())
                                .foregroundColor(.red)
                        } else if timerService.currentRemainingMinutes > 0 {
                            Text("Remaining: \(timerService.formattedRemainingTime)")
                                .font(AppFonts.subheadline())
                                .foregroundColor(.gray)
                        } else {
                            Text("Time's up!")
                                .font(AppFonts.subheadline())
                                .foregroundColor(.orange)
                        }
                        
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
                
                // Task Controls
                VStack(spacing: 16) {
                    if timerService.currentTask == nil || timerService.currentTask?.isCompleted == true {
                        // Start/Restart button
                        Button(action: {
                            if timerService.currentTask?.isCompleted == true {
                                // Reset and restart
                                timerService.stopCurrentTask()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    timerService.startTask(task)
                                }
                            } else {
                                timerService.startTask(task)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: timerService.currentTask?.isCompleted == true ? "arrow.clockwise" : "play.fill")
                                    .font(.title2)
                                Text(timerService.currentTask?.isCompleted == true ? "Restart" : "Start")
                                    .font(AppFonts.headline())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(task.color)
                            .cornerRadius(25)
                        }
                    } else if timerService.currentTask?.isActive ?? false {
                        // Active task controls
                        HStack(spacing: 16) {
                            
                            // Complete button
                            Button(action: {
                                timerService.completeTask()
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
                        }
                    }
                    
                    // Focus Status Banner
                    if focusManager.isActiveFocus {
                        FocusStatusBanner(
                            mode: focusManager.currentFocusMode,
                            blockedNotifications: focusManager.blockedNotifications
                        )
                    }
                }
                
                
                // Statistics Card
                if let currentTask = timerService.currentTask {
                    VStack(spacing: 12) {
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
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("Progress")
                                    .font(AppFonts.caption())
                                    .foregroundColor(.gray)
                                Text("\(Int(timerService.currentProgressPercentage * 100))%")
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Status")
                                    .font(AppFonts.caption())
                                    .foregroundColor(.gray)
                                Text(statusText(for: currentTask.status))
                                    .font(AppFonts.caption())
                                    .foregroundColor(statusColor(for: currentTask.status))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(statusColor(for: currentTask.status).opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppColors.card)
                    .cornerRadius(12)
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
                       
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear {
            timerService.setModelContext(modelContext)
            // Auto-start the timer when view appears
            if timerService.currentTask == nil {
                timerService.startTask(task)
            }

            if ((task.focusSettings?.isEnabled) != nil) {
                focusManager.blockedNotifications = 1
                _Concurrency.Task {
                    await focusManager.activateFocus(mode: .deepWork, duration: TimeInterval(timerService.currentRemainingMinutes * 60), task: task)
                }
            }
        }
        .onChange(of: timerService.currentTask?.isCompleted) { _, isCompleted in
            if isCompleted == true && !isAutoCompleted {
                // Task was auto-completed by timer
                isAutoCompleted = true
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    showCelebration = true
                    timerService.completeTask()
                }
            }
        }
        .overlay {
            if showCelebration {
                ConfettiCelebrationView(
                    isPresented: $showCelebration,
                    title: "Nice work!",
                    subtitle: "You completed \(task.title)",
                    accent: task.color,
                    duration: 5
                ) {
                    timerService.completeTask()
                    timerService.stopCurrentTask()
                    dismiss()
                }
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func statusText(for status: TaskStatus) -> String {
        switch status {
        case .scheduled:
            return "Scheduled"
        case .inProgress:
            return "Active"
        case .paused:
            return "Paused"
        case .completed:
            return "Done"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    private func statusColor(for status: TaskStatus) -> Color {
        switch status {
        case .scheduled:
            return .blue
        case .inProgress:
            return .green
        case .paused:
            return .orange
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
}

#Preview {
    TaskTimer(task: Task(
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

