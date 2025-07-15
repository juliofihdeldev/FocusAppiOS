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
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.clear
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Bottom sheet
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Drag handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 36, height: 6)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    
                    // Task Info Header
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            // Task icon
                            ZStack {
                                Circle()
                                    .fill(task.color.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                
                                Text(task.icon)
                                    .font(.title2)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(AppFonts.headline())
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                                    .multilineTextAlignment(.leading)
                                
                                HStack(spacing: 12) {
                                    if let taskType = task.taskType {
                                        HStack(spacing: 4) {
                                            Text(taskType.icon)
                                                .font(.caption)
                                            Text(taskType.displayName)
                                                .font(AppFonts.caption())
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                    
                                    Text("\(task.durationMinutes) min")
                                        .font(AppFonts.caption())
                                        .foregroundColor(task.color)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(task.color.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                            
                            // Status indicator
                            if task.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            } else if task.timeSpentMinutes > 0 {
                                VStack(spacing: 2) {
                                    Text("\(Int(task.progressPercentage * 100))%")
                                        .font(AppFonts.caption())
                                        .fontWeight(.semibold)
                                        .foregroundColor(task.color)
                                    
                                    ProgressView(value: task.progressPercentage)
                                        .progressViewStyle(LinearProgressViewStyle(tint: task.color))
                                        .frame(width: 40)
                                }
                            }
                        }
                        
                        // Progress bar if task has been started
                        if task.timeSpentMinutes > 0 && !task.isCompleted {
                            VStack(spacing: 6) {
                                HStack {
                                    Text("Progress")
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                    Spacer()
                                    Text("\(task.timeSpentMinutes)/\(task.durationMinutes) min")
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                ProgressView(value: task.progressPercentage)
                                    .progressViewStyle(LinearProgressViewStyle(tint: task.color))
                                    .frame(height: 6)
                                    .cornerRadius(3)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    // Divider
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // Action Buttons Section
                    VStack(spacing: 0) {
                        // Primary Actions
                        if !task.isCompleted {
                            TaskActionButton(
                                title: "Start Focus Timer",
                                icon: "play.circle.fill",
                                iconColor: task.color,
                                isPrimary: true,
                                action: {
                                    onStart()
                                    showingTimer = true
                                }
                            )
                            
                            TaskActionButton(
                                title: "Mark as Complete",
                                icon: "checkmark.circle.fill",
                                iconColor: .green,
                                action: {
                                    onComplete()
                                    dismiss()
                                }
                            )
                        }
                        
                        // Secondary Actions
                        TaskActionButton(
                            title: "Edit Task",
                            icon: "pencil.circle.fill",
                            iconColor: .blue,
                            action: {
                                onEdit()
                                dismiss()
                            }
                        )
                        
                        TaskActionButton(
                            title: "Duplicate Task",
                            icon: "doc.on.doc.fill",
                            iconColor: .orange,
                            action: {
                                onDuplicate()
                                dismiss()
                            }
                        )
                        
                        // Destructive Action
                        Divider()
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        
                        TaskActionButton(
                            title: "Delete Task",
                            icon: "trash.circle.fill",
                            iconColor: .red,
                            isDestructive: true,
                            action: {
                                onDelete()
                                dismiss()
                            }
                        )
                    }
                    .padding(.top, 16)
                    
                    // Cancel Button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(AppFonts.body())
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.card)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppColors.background)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
                )
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                dismiss()
                            } else {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
        
        .fullScreenCover(isPresented: $showingTimer, onDismiss: {
            dismiss()
        }) {
            TaskTimerView(task: task)
        }
    }
}

struct TaskActionButton: View {
    let title: String
    let icon: String
    let iconColor: Color
    var isPrimary: Bool = false
    var isDestructive: Bool = false
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 28)
                
                // Title
                Text(title)
                    .font(isPrimary ? AppFonts.headline() : AppFonts.body())
                    .fontWeight(isPrimary ? .semibold : .medium)
                    .foregroundColor(isDestructive ? .red : AppColors.textPrimary)
                
                Spacer()
                
                // Arrow (only for non-destructive actions)
                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(isPressed ? AppColors.card.opacity(0.5) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 50) {
            // Action performed on tap
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}

// MARK: - Alternative Compact Version

struct CompactTaskActionsModal: View {
    let task: Task
    let onStart: () -> Void
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingTimer = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
            
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Handle
                    Capsule()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 36, height: 5)
                        .padding(.top, 12)
                    
                    // Task Summary
                    HStack(spacing: 12) {
                        Text(task.icon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(task.color.opacity(0.15))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(AppFonts.subheadline())
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("\(task.durationMinutes) minutes")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    
                    Divider()
                    
                    // Quick Actions Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        if !task.isCompleted {
                            QuickActionButton(
                                title: "Start Timer",
                                icon: "play.fill",
                                color: task.color,
                                action: { onStart(); showingTimer = true }
                            )
                            
                            QuickActionButton(
                                title: "Complete",
                                icon: "checkmark",
                                color: .green,
                                action: { onComplete(); dismiss() }
                            )
                        }
                        
                        QuickActionButton(
                            title: "Edit",
                            icon: "pencil",
                            color: .blue,
                            action: { onEdit(); dismiss() }
                        )
                        
                        QuickActionButton(
                            title: "Duplicate",
                            icon: "doc.on.doc",
                            color: .orange,
                            action: { onDuplicate(); dismiss() }
                        )
                        
                        if !task.isCompleted {
                            QuickActionButton(
                                title: "Delete",
                                icon: "trash",
                                color: .red,
                                action: { onDelete(); dismiss() }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    
                    // Cancel
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.bottom, 32)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppColors.background)
                        .shadow(radius: 20)
                )
            }
        }
        .fullScreenCover(isPresented: $showingTimer) {
            TaskTimerView(task: task)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Text(title)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.card)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TaskActionsModal(
        task: Task(
            id: UUID(),
            title: "Review Project Documentation",
            icon: "📖",
            startTime: Date(),
            durationMinutes: 45,
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

#Preview("Compact Version") {
    CompactTaskActionsModal(
        task: Task(
            id: UUID(),
            title: "Morning Workout",
            icon: "🏃‍♂️",
            startTime: Date(),
            durationMinutes: 30,
            color: .orange,
            isCompleted: false,
            taskType: .exercise
        ),
        onStart: {},
        onComplete: {},
        onEdit: {},
        onDuplicate: {},
        onDelete: {}
    )
}
