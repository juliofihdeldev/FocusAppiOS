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
                                Text(NSLocalizedString("part_of_repeating_series", comment: "Part of repeating series label"))
                                    .font(AppFonts.caption())
                                    .foregroundColor(.orange)
                            } else if task.isParentTask {
                                Text(NSLocalizedString("repeating_task_series", comment: "Repeating task series label"))
                                    .font(AppFonts.caption())
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Text(NSLocalizedString("what_would_you_like_to_delete", comment: "What would you like to delete question"))
                        .font(AppFonts.subheadline())
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                }
                
                // Deletion Options
                VStack(spacing: 1) {
                    if task.isGeneratedFromRepeat || task.isChildTask {
                        // Options for repeating task instances
                        DeletionOptionButton(
                            title: NSLocalizedString("delete_this_instance", comment: "Delete this instance button"),
                            subtitle: NSLocalizedString("remove_only_this_occurrence", comment: "Remove only this occurrence subtitle"),
                            icon: "calendar.badge.minus",
                            color: .orange,
                            action: {
                                onDeleteInstance()
                                dismiss()
                            }
                        )
                        
                        DeletionOptionButton(
                            title: NSLocalizedString("delete_all_instances", comment: "Delete all instances button"),
                            subtitle: NSLocalizedString("remove_the_entire_repeating_series", comment: "Remove the entire repeating series subtitle"),
                            icon: "calendar.badge.exclamationmark",
                            color: .red,
                            action: {
                                onDeleteAllInstances()
                                dismiss()
                            }
                        )
                        
                        DeletionOptionButton(
                            title: NSLocalizedString("delete_future_instances", comment: "Delete future instances button"),
                            subtitle: NSLocalizedString("keep_past_remove_upcoming_occurrences", comment: "Keep past, remove upcoming occurrences subtitle"),
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
                            title: NSLocalizedString("delete_entire_series", comment: "Delete entire series button"),
                            subtitle: NSLocalizedString("remove_this_task_and_all_its_instances", comment: "Remove this task and all its instances subtitle"),
                            icon: "trash.circle.fill",
                            color: .red,
                            action: {
                                onDeleteAllInstances()
                                dismiss()
                            }
                        )
                        
                        DeletionOptionButton(
                            title: NSLocalizedString("delete_future_instances", comment: "Delete future instances button"),
                            subtitle: NSLocalizedString("keep_completed_instances_remove_future_ones", comment: "Keep completed instances, remove future ones subtitle"),
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
                            title: NSLocalizedString("delete_task", comment: "Delete task button"),
                            subtitle: NSLocalizedString("this_action_cannot_be_undone", comment: "This action cannot be undone warning"),
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
            .navigationTitle(NSLocalizedString("delete_task_navigation_title", comment: "Delete task navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
}
