import SwiftUI

struct TaskPreviewGrid: View {
    @Binding var taskTitle: String
    @Binding var selectedColor: Color
    @Binding var duration: Int
    @Binding var showingPreviewTasks: Bool
    
    let previewTasks = [
        PreviewTask(title: "Morning workout", color: .green, duration: 45, icon: "figure.run"),
        PreviewTask(title: "Team meeting", color: .blue, duration: 30, icon: "person.3"),
        PreviewTask(title: "Lunch break", color: .orange, duration: 60, icon: "fork.knife"),
        PreviewTask(title: "Code review", color: .purple, duration: 30, icon: "laptopcomputer"),
        PreviewTask(title: "Grocery shopping", color: .yellow, duration: 45, icon: "cart"),
        PreviewTask(title: "Call mom", color: .pink, duration: 15, icon: "phone"),
        PreviewTask(title: "Read book", color: .teal, duration: 30, icon: "book"),
        PreviewTask(title: "Take a walk", color: .green, duration: 20, icon: "figure.walk")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a task to get started")
                .font(AppFonts.caption())
                .foregroundColor(.gray)
                .padding(.top, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(previewTasks, id: \.title) { task in
                    Button(action: {
                        withAnimation(.spring()) {
                            taskTitle = task.title
                            selectedColor = task.color
                            duration = task.duration
                            showingPreviewTasks = false
                        }
                    }) {
                        HStack {
                            Image(systemName: task.icon)
                                .foregroundColor(task.color)
                                .font(.system(size: 16))
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.textPrimary)
                                Text("\(task.duration)m")
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(task.color.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(task.color.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.bottom, 12)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

#Preview {
    @State var title = ""
    @State var color = Color.pink
    @State var duration = 15
    @State var showing = true
    
    return TaskPreviewGrid(
        taskTitle: $title,
        selectedColor: $color,
        duration: $duration,
        showingPreviewTasks: $showing
    )
}