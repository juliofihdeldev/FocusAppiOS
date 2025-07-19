import SwiftUI
import SwiftData

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    @StateObject private var timerService = TaskTimerService()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date = Date()
    @State private var showAddTaskForm = false
    @State private var editingTask: Task?
    @State private var selectedTaskForActions: Task?

    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Date Header - Fixed at top
                    DateHeader(
                        selectedDate: $selectedDate
                    )
                    .padding(.bottom, 16)
                    
//                    Button("Clear All Tasks") {
//                        viewModel.clearAllTasks()
//                    }
//                    .foregroundColor(.red)
                    
                    // Main Content Area
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                if viewModel.tasks.isEmpty {
                                    // Empty state
                                    VStack(spacing: 16) {
                                        Image(systemName: "calendar.badge.plus")
                                            .font(.system(size: 48))
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        Text("No tasks for today")
                                            .font(AppFonts.headline())
                                            .foregroundColor(AppColors.textSecondary)
                                        
                                        Text("Tap the + button to create your first task")
                                            .font(AppFonts.body())
                                            .foregroundColor(AppColors.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.top, 100)
                                } else {
                                    // Task Cards
                                    ForEach(viewModel.tasks) { task in
                                        TaskCard(
                                            title: task.title,
                                            time: viewModel.timeRange(for: task),
                                            icon: task.icon,
                                            color: viewModel.taskColor(task),
                                            isCompleted: task.isCompleted,
                                            durationMinutes: task.durationMinutes,
                                            task: task
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .onTapGesture {
                                            selectedTaskForActions = task
                                        }
                                    }
                                }
                                
                                // Bottom padding to prevent content from hiding behind FAB
                                Spacer()
                                    .frame(height: 100)
                            }
                        }
                        .refreshable {
                            viewModel.loadTodayTasks(for: selectedDate)
                        }
                    }
                }
                
                // Floating Action Button - Fixed position
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        FloatingActionButton {
                            showAddTaskForm = true
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupViewModels()
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.loadTodayTasks(for: newDate)
        }
        .sheet(isPresented: $showAddTaskForm) {
            TaskFormView()
        }
        .sheet(item: $editingTask) { task in
            TaskFormView(taskToEdit: task)
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
    
    // MARK: - Setup Methods
    
    private func setupViewModels() {
        viewModel.setModelContext(modelContext)
        timerService.setModelContext(modelContext)
        viewModel.loadTodayTasks(for: selectedDate)
    }
    
    // MARK: - Task Actions
    private func deleteTask(_ task: Task) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.deleteTask(task)
        }
        selectedTaskForActions = nil
    }
    
    private func duplicateTask(_ task: Task) {
        viewModel.duplicateTask(task)
        selectedTaskForActions = nil
    }
    
    private func completeTask(_ task: Task) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.completeTask(task)
        }
        selectedTaskForActions = nil
    }
    
    private func editTask(_ task: Task) {
        selectedTaskForActions = nil
        editingTask = task
    }
    
    private func startTask(_ task: Task) {
        timerService.startTask(task)
        selectedTaskForActions = nil
    }
}

// MARK: - Floating Action Button Component

struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.9),
                            Color.blue.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: isPressed ? 4 : 8,
                    x: 0,
                    y: isPressed ? 2 : 4
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 50) { 
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}

// MARK: - Updated DateHeader Component

struct UpdatedDateHeader: View {
    @Binding var selectedDate: Date
    
    private var currentWeek: [Date] {
        let calendar = Calendar.current
        let today = selectedDate
        let weekday = calendar.component(.weekday, from: today)
        
        let startOfWeek = calendar.date(
            byAdding: .day,
            value: -((weekday - calendar.firstWeekday + 7) % 7),
            to: today
        ) ?? today
        
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startOfWeek)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month and Year
            HStack {
                Text(monthYearString(from: selectedDate))
                    .font(AppFonts.title())
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Today button
                Button("Today") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDate = Date()
                    }
                }
                .font(AppFonts.caption())
                .foregroundColor(AppColors.accent)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 8)
        .background(AppColors.background)
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    TimelineView()
        .environmentObject(ThemeManager())
        .modelContainer(for: [Task.self])
}
