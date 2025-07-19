import SwiftUI

struct TaskActionsModal: View {
    let task: Task
    let onStart: () -> Void
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingTimer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Task Info Header
            VStack(spacing: 12) {
                HStack {
                    Text(task.icon)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                        
                        if let taskType = task.taskType {
                            Text(taskType.displayName)
                                .font(AppFonts.caption())
                                .foregroundColor(.gray)
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
                if task.timeSpentMinutes > 0 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Progress")
                                .font(AppFonts.caption())
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(task.timeSpentMinutes)/\(task.durationMinutes)m")
                                .font(AppFonts.caption())
                                .foregroundColor(.gray)
                        }
                        
                        ProgressView(value: task.progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: task.color))
                    }
                }
            }
            .padding(20)
            .background(AppColors.card)
            
            // Action Buttons
            VStack(spacing: 1) {
                if !task.isCompleted {
                    TaskActionButton(
                        title: "Launch timer",
                        icon: "play.fill",
                        color: task.color,
                        action: {
                            // Don't call onStart() here - just show the timer
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
                        onDelete()
                        dismiss()
                    }
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(AppColors.background)
        .navigationTitle("Task Actions")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(AppColors.accent)
            }
        }
        .fullScreenCover(isPresented: $showingTimer, onDismiss: {
            // Call onStart() when the timer is dismissed to update the task state
            onStart()
            dismiss()
        }) {
            TaskTimer(task: task)
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
            HStack(spacing: 12) {
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
        onDuplicate: {},
        onDelete: {}
    )
}
