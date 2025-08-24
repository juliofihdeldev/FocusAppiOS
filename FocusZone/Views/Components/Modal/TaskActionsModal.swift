import SwiftUI

struct TaskActionsModal: View {
    let task: Task
    let onStart: () -> Void
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: (DeletionType) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingTimer = false
    @State private var showingDeletionOptions = false
    @StateObject private var timerService = TaskTimerService()
    
    enum DeletionType {
        case instance
        case allInstances
        case futureInstances
    }
    
    var body: some View {
        ZStack {
            // Transparent background with subtle blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 16) {
                    // Task Info Header Card
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Text(task.icon)
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.title)
                                    .font(AppFonts.headline())
                                    .foregroundColor(AppColors.textPrimary)
                                    .multilineTextAlignment(.leading)
                                
                                if let taskType = task.taskType {
                                    Text(taskType.displayName)
                                        .font(AppFonts.caption())
                                        .foregroundColor(.gray)
                                }
                                
                                // Show task type indicator
                                if task.isGeneratedFromRepeat {
                                    Text("Repeating task instance")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.orange)
                                } else if task.isParentTask {
                                    Text("Repeating task series")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(task.durationMinutes)m")
                                .font(AppFonts.subheadline())
                                .foregroundColor(task.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(task.color.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Progress if any
                        if timerService._minutesRemain(for: task) > 0 {
                            VStack(spacing: 6) {
                                HStack {
                                    Text("Progress")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(timerService.calculateSmartElapsedTime(for: task))/\(task.durationMinutes)m")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.gray)
                                }
                                
                                ProgressView(
                                    value: Double(timerService.calculateSmartElapsedTime(for: task)) / Double(task.durationMinutes),
                                    label: {
                                        Text("")
                                    }
                                )
                                .progressViewStyle(LinearProgressViewStyle(tint: task.color))
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.card)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    
                    // Action Buttons Card
                    VStack(spacing: 1) {
                        if !task.isCompleted || timerService._minutesRemain(for: task) < 0 {
                            TaskActionButton(
                                title: "Launch timer",
                                icon: "play.fill",
                                color: task.color,
                                action: {
                                    showingTimer = true
                                }
                            )
                        }
                        
                        if !task.isCompleted {
                            TaskActionButton(
                                title: "Mark Complete",
                                icon: "checkmark.circle",
                                color: .green,
                                action: {
                                    onComplete()
                                    dismiss()
                                }
                            )
                        }
                        
                        TaskActionButton(
                            title: "Edit Task",
                            icon: "pencil",
                            color: .blue,
                            action: {
                                onEdit()
                                dismiss()
                            }
                        )
                        
                        TaskActionButton(
                            title: "Duplicate Task",
                            icon: "doc.on.doc",
                            color: .orange,
                            action: {
                                onDuplicate()
                                dismiss()
                            }
                        )
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        TaskActionButton(
                            title: "Delete Task",
                            icon: "trash",
                            color: .red,
                            isDestructive: true,
                            action: {
                                if task.isGeneratedFromRepeat || task.isChildTask || task.isParentTask {
                                    showingDeletionOptions = true
                                } else {
                                    onDelete(.instance)
                                    dismiss()
                                }
                            }
                        )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.card)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    
                    // Cancel Button
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(AppFonts.body())
                            .foregroundColor(.gray)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34) // Add safe area padding for bottom
            }
        }
        .fullScreenCover(isPresented: $showingTimer, onDismiss: {
            onStart()
            dismiss()
        }) {
            TaskTimer(task: task)
        }
        .sheet(isPresented: $showingDeletionOptions) {
            TaskDeletionModal(
                task: task,
                onDeleteInstance: {
                    onDelete(.instance)
                },
                onDeleteAllInstances: {
                    onDelete(.allInstances)
                },
                onDeleteFutureInstances: {
                    onDelete(.futureInstances)
                },
                onCancel: {
                    showingDeletionOptions = false
                }
            )
        }
    }
}

struct TaskActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : color)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(isDestructive ? .red : AppColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - TaskDeletionModal

struct DeletionOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.textPrimary)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(AppColors.card)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TaskActionsModal(
        task: Task(
            id: UUID(),
            title: "Sample Task",
            icon: "💻",
            startTime: Date(),
            durationMinutes: 60,
            color: .blue,
            isCompleted: false,
            taskType: .work
        ),
        onStart: {},
        onComplete: {},
        onEdit: {},
        onDuplicate: {  },
        onDelete: { _ in }
    )
}
