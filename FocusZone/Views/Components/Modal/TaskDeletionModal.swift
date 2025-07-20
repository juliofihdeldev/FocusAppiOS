import SwiftUI

struct TaskDeletionModal: View {
    let task: Task
    let onDeleteInstance: () -> Void
    let onDeleteAllInstances: () -> Void
    let onDeleteFutureInstances: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text(task.icon)
                            .font(.title)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(AppFonts.headline())
                                .foregroundColor(AppColors.textPrimary)
                            
                            if task.isGeneratedFromRepeat || task.isChildTask {
                                Text("Part of repeating series")
                                    .font(AppFonts.caption())
                                    .foregroundColor(.orange)
                            } else if task.isParentTask {
                                Text("Repeating task series")
                                    .font(AppFonts.caption())
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Text("What would you like to delete?")
                        .font(AppFonts.subheadline())
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                }
                
                // Deletion Options
                VStack(spacing: 1) {
                    if task.isGeneratedFromRepeat || task.isChildTask {
                        // Options for repeating task instances
                        DeletionOptionButton(
                            title: "Delete This Instance",
                            subtitle: "Remove only this occurrence",
                            icon: "calendar.badge.minus",
                            color: .orange,
                            action: {
                                onDeleteInstance()
                                dismiss()
                            }
                        )
                        
                        DeletionOptionButton(
                            title: "Delete All Instances",
                            subtitle: "Remove the entire repeating series",
                            icon: "calendar.badge.exclamationmark",
                            color: .red,
                            action: {
                                onDeleteAllInstances()
                                dismiss()
                            }
                        )
                        
                        DeletionOptionButton(
                            title: "Delete Future Instances",
                            subtitle: "Keep past, remove upcoming occurrences",
                            icon: "calendar.badge.clock",
                            color: .purple,
                            action: {
                                onDeleteFutureInstances()
                                dismiss()
                            }
                        )
                    } else if task.isParentTask {
                        // Options for parent tasks
                        DeletionOptionButton(
                            title: "Delete Entire Series",
                            subtitle: "Remove this task and all its instances",
                            icon: "trash.circle.fill",
                            color: .red,
                            action: {
                                onDeleteAllInstances()
                                dismiss()
                            }
                        )
                        
                        DeletionOptionButton(
                            title: "Delete Future Instances Only",
                            subtitle: "Keep completed instances, remove future ones",
                            icon: "calendar.badge.clock",
                            color: .purple,
                            action: {
                                onDeleteFutureInstances()
                                dismiss()
                            }
                        )
                    } else {
                        // Simple task deletion
                        DeletionOptionButton(
                            title: "Delete Task",
                            subtitle: "This action cannot be undone",
                            icon: "trash.circle.fill",
                            color: .red,
                            action: {
                                onDeleteInstance()
                                dismiss()
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                
                Spacer()
            }
            .background(AppColors.background)
            .navigationTitle("Delete Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
}
