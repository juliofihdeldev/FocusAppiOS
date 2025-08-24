import SwiftUI

struct TaskConflictIndicator: View {
    let conflict: TaskConflictService.TaskConflict
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: conflict.type.icon)
                .foregroundColor(conflict.severity.color)
                .font(.caption)
            
            Text(conflict.message)
                .font(AppFonts.caption())
                .foregroundColor(conflict.severity.color)
                .lineLimit(2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(conflict.severity.color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(conflict.severity.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        TaskConflictIndicator(
            conflict: TaskConflictService.TaskConflict(
                type: .timeOverlap,
                severity: .critical,
                message: "Starts at same time as 'Team Meeting'",
                conflictingTaskId: UUID(),
                conflictingTaskTitle: "Team Meeting"
            )
        )
        
        TaskConflictIndicator(
            conflict: TaskConflictService.TaskConflict(
                type: .noBuffer,
                severity: .low,
                message: "Only 3m buffer with 'Email Check'",
                conflictingTaskId: UUID(),
                conflictingTaskTitle: "Email Check"
            )
        )
        
        TaskConflictIndicator(
            conflict: TaskConflictService.TaskConflict(
                type: .timeOverlap,
                severity: .high,
                message: "Overlaps with 'Project Review'",
                conflictingTaskId: UUID(),
                conflictingTaskTitle: "Project Review"
            )
        )
    }
    .padding()
    .background(Color.black)
}
