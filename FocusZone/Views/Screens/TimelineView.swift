
import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    @StateObject private var timerService = TaskTimerService()
    @State private var selectedDate: Date = Date()
    @State private var showAddTaskForm = false
    @State private var editingTask: Task?
    @State private var selectedTaskForActions: Task?

    var body: some View {
        VStack {
            DateHeader(selectedDate: $selectedDate )
            ScrollViewReader { proxy in
                ScrollView {
                    
                    VStack(spacing: 12) {
                        ForEach(viewModel.tasks) { task in
                            VStack(spacing: 8) {
                                TaskCard(
                                    title: task.title,
                                    time: viewModel.timeRange(for: task),
                                    icon: task.icon,
                                    color: viewModel.taskColor(task),
                                    isCompleted: task.isCompleted, 
                                    durationMinutes: task.durationMinutes,
                                    task: task
                                )
                                .onTapGesture {
                                    selectedTaskForActions = task
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    viewModel.loadTodayTasks()
                }
            }
            HStack(alignment: .center) {
                Spacer() // Pushes the button to the right
                
                Button(action: {
                    showAddTaskForm = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .padding()
                }
                .sheet(isPresented: $showAddTaskForm) {
                   TaskFormView()
                }
                
            }
           
        }
        .sheet(item: $editingTask) { task in
            TaskFormView() // In real implementation, pass the task to edit
        }
        .sheet(item: $selectedTaskForActions) { task in
            TaskActionsModal(
                task: task,
                onStart: { startTask(task) },
                onComplete: { completeTask(task) },
                onEdit: { editTask(task) },
                onDuplicate: { duplicateTask(task) },
                onDelete: { deleteTask(task) }
            )
        }
    }
    
    // MARK: - Task Actions
    private func deleteTask(_ task: Task) {
        viewModel.deleteTask(task)
    }
    
    private func duplicateTask(_ task: Task) {
        viewModel.duplicateTask(task)
    }
    
    private func completeTask(_ task: Task) {
        viewModel.completeTask(task)
    }
    
    private func editTask(_ task: Task) {
        editingTask = task
    }
    
    private func startTask(_ task: Task) {
        timerService.startTask(task)
    }
}

#Preview {
    TimelineView()
        .environmentObject(ThemeManager())
}
