import SwiftUI
import SwiftData

// Create an alias to avoid conflict with Swift's Task
typealias FocusTask = Task

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    @StateObject private var timerService = TaskTimerService()
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date = Date()
    @State private var showAddTaskForm = false
    @State private var editingTask: FocusTask?
    @State private var selectedTaskForActions: FocusTask?
    @State private var showNotificationAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Notification permission banner
                    if !notificationService.isAuthorized {
                        notificationPermissionBanner
                    }
                    
                    // Date Header - Fixed at top
                    WeekDateNavigator(
                        selectedDate: $selectedDate
                    )
                    .padding(.bottom, 16)
                    
                    // // Debug button (remove in production)
                    // #if DEBUG
                    // Button("Test Task Creation") {
                    //     viewModel.createTestTask()
                    // }
                    // .foregroundColor(.blue)
                    // .padding(.bottom, 8)
                    // #endif
                    
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
                                    .padding(.top, 10)
                                } else {
                                    ForEach(Array(viewModel.tasks.enumerated()), id: \.element.id) { index, task in
                                        TaskCard(
                                            title: task.title,
                                            time: viewModel.timeRange(for: task),
                                            icon: task.icon,
                                            color: viewModel.taskColor(task),
                                            isCompleted: task.isCompleted,
                                            durationMinutes: task.durationMinutes,
                                            task: task,
                                            timelineViewModel: viewModel
                                        )
//                                        .padding(.horizontal, 16)
//                                        .padding(.vertical, 8)
                                        .onTapGesture {
                                            selectedTaskForActions = task
                                        }
                                        
                                        // Show break suggestions after this task
                                        ForEach(viewModel.breakSuggestions.filter { $0.insertAfterTaskId == task.id }) { suggestion in
                                            BreakSuggestionCard(
                                                suggestion: suggestion,
                                                onAccept: {
                                                    viewModel.acceptBreakSuggestion(suggestion)
                                                },
                                                onDismiss: {
                                                    viewModel.dismissBreakSuggestion(suggestion)
                                                }
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    
                                    // Add standalone suggestions after all tasks
                                    ForEach(viewModel.breakSuggestions.filter { $0.insertAfterTaskId == nil }) { suggestion in
                                        BreakSuggestionCard(
                                            suggestion: suggestion,
                                            onAccept: {
                                                viewModel.acceptBreakSuggestion(suggestion)
                                            },
                                            onDismiss: {
                                                viewModel.dismissBreakSuggestion(suggestion)
                                            }
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                    }
                                    
                                    // And add this to the onChange modifier for selectedDate:
                                    .onChange(of: selectedDate) { _, newDate in
                                        viewModel.loadTodayTasks(for: newDate)
                                        viewModel.updateBreakSuggestions() // Add this line
                                    }
                                    
                                }
                                
                                // Bottom padding to prevent content from hiding behind FAB
                                Spacer()
                                    .frame(height: 100)
                            }
                        }
                        .refreshable {
                            viewModel.forceRefreshTasks(for: selectedDate)
                          
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Refresh timeline when app becomes active
            viewModel.forceRefreshTasks(for: selectedDate)
            print("TimelineView: Refreshed on app becoming active")
        }
        .onChange(of: selectedDate) { _, newDate in
            viewModel.loadTodayTasks(for: newDate)
            viewModel.refreshTasksWithBreakSuggestions(for: newDate)
            
        }
        .sheet(isPresented: $showAddTaskForm, onDismiss: {
            // Refresh timeline after creating a task with a small delay to ensure data is saved
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.forceRefreshTasks(for: selectedDate)
                viewModel.updateBreakSuggestions()
                print("TimelineView: Force refreshed after task creation")
            }
        }) {
            TaskFormView()
                .environment(\.modelContext, modelContext)
        }
        .sheet(isPresented: Binding<Bool>(
            get: { editingTask != nil },
            set: { if !$0 {
                editingTask = nil
                // Refresh timeline after editing a task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.forceRefreshTasks(for: selectedDate)
                    viewModel.updateBreakSuggestions()
                    print("TimelineView: Force refreshed after task edit")
                }
            } }
        )) {
            if let task = editingTask {
                TaskFormView(taskToEdit: task)
                    .environment(\.modelContext, modelContext)
            }
        }
        .sheet(isPresented: Binding<Bool>(
            get: { selectedTaskForActions != nil },
            set: { if !$0 { selectedTaskForActions = nil } }
        )) {
            if let task = selectedTaskForActions {
                TaskActionsModal(
                    task: task,
                    onStart: { startTask(task) },
                    onComplete: { completeTask(task) },
                    onEdit: { editTask(task) },
                    onDuplicate: { duplicateTask(task) },
                    onDelete: { deletionType in
                        handleTaskDeletion(task, type: deletionType)
                    }
                )
            }
        }
        .alert("Enable Notifications", isPresented: $showNotificationAlert) {
            Button("Enable") {
                _Concurrency.Task {
                    await viewModel.requestNotificationPermission()
                }
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text("Enable notifications to get reminders for your tasks and stay focused!")
        }
    }
    
    private var notificationPermissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications Disabled")
                    .font(AppFonts.subheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Enable to get task reminders")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Button("Enable") {
                showNotificationAlert = true
            }
            .font(AppFonts.caption())
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.accent)
            .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.orange.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    
    private func handleTaskDeletion(_ task: FocusTask, type: TaskActionsModal.DeletionType) {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch type {
            case .instance:
                viewModel.deleteTaskInstance(task)
            case .allInstances:
                viewModel.deleteAllTaskInstances(task)
            case .futureInstances:
                viewModel.deleteFutureTaskInstances(task)
            }
        }
        selectedTaskForActions = nil
    }
        
    private func setupViewModels() {
        viewModel.setModelContext(modelContext)
        timerService.setModelContext(modelContext)
        viewModel.loadTodayTasks(for: selectedDate)
        viewModel.refreshTasksWithBreakSuggestions(for: selectedDate) // Changed this line
        
        // Show notification permission alert if not authorized
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if !notificationService.isAuthorized {
                showNotificationAlert = true
            }
        }
    }
    
    // MARK: - Task Actions
    private func deleteTask(_ task: FocusTask) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.deleteTask(task)
        }
        selectedTaskForActions = nil
    }
    
    private func duplicateTask(_ task: FocusTask) {
        viewModel.duplicateTask(task)
        selectedTaskForActions = nil
    }
    
    private func completeTask(_ task: FocusTask) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.completeTask(task)
        }
        selectedTaskForActions = nil
    }
    
    private func editTask(_ task: FocusTask) {
        selectedTaskForActions = nil
        editingTask = task
    }
    
    private func startTask(_ task: FocusTask) {
        timerService.startTask(task)
        selectedTaskForActions = nil
    }
}

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

#Preview {
    TimelineView()
        .environmentObject(ThemeManager())
        .environmentObject(NotificationService.shared)
}
