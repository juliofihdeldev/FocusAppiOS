import SwiftUI
import SwiftData

struct PreviewTask {
    let title: String
    let color: Color
    let duration: Int
    let icon: String
}

struct TaskFormView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedFocusMode: FocusMode? = nil
    @State private var enableFocusMode: Bool = false
    // Task to edit (nil for new task)
    let taskToEdit: Task?
    
    @State private var taskTitle: String = ""
    @State private var selectedDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var duration: Int = 15
    @State private var selectedColor: Color = .pink
    @State private var selectedTaskType: TaskType? = nil
    @State private var selectedIcon: String = "📝"
    @State private var repeatRule: RepeatRule = .none
    @State private var alerts: [String] = ["At start of task"]
    @State private var showSubtasks: Bool = true
    @State private var notes: String = ""
    @State private var showingTimeSlots: Bool = false
    @State private var showingPreviewTasks: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    private let notificationService = NotificationService.shared
    
    init(taskToEdit: Task? = nil) {
        self.taskToEdit = taskToEdit
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TaskFormHeader(onDismiss: { dismiss() })
                    
                    VStack(alignment: .leading, spacing: 40) {
                        
                        TaskTitleInput(
                            taskTitle: $taskTitle,
                            selectedColor: $selectedColor,
                            duration: $duration
                        )
                        
                        if taskTitle != "" {
                            TaskTimeSelector(
                                selectedDate: $selectedDate,
                                startTime: $startTime
                            )
                            
                            TaskDurationSelector(duration: $duration)
                            
                            TaskIconPicker(selectedIcon: $selectedIcon)
                            
                            FocusModeFormSection(
                                               isEnabled: $enableFocusMode,
                                               selectedMode: $selectedFocusMode,
                                               taskType: selectedTaskType
                                           )
                            
                            TaskColorPicker(selectedColor: $selectedColor)
                            
                            TaskRepeatSelector(repeatRule: $repeatRule)
                            
                            // Create/Update Task Button
                            Button(action: {
                                saveTask()
                            }) {
                                Text(taskToEdit == nil ? "Create Task" : "Update Task")
                                    .font(AppFonts.headline())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(selectedColor)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(taskTitle.isEmpty)
                            
                            // Notification Info Section
                            NotificationInfoSection()
                            
//                            TaskAlertsSection(alerts: $alerts)
                            
                            TaskDetailsSection(
                                showSubtasks: $showSubtasks,
                                notes: $notes
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
        }
        .navigationBarHidden(true)
        .onAppear {
            loadTaskData()
        }
    }
    
    private func loadTaskData() {
        guard let task = taskToEdit else { return }
        
        taskTitle = task.title
        selectedDate = task.startTime
        startTime = task.startTime
        duration = task.durationMinutes
        selectedColor = task.color
        selectedTaskType = task.taskType
        selectedIcon = task.icon
        repeatRule = task.repeatRule
    }
    
    private func saveTask() {
        
        print(">>>>>> save task call >>>>>>>")
        print("TaskFormView: ModelContext available: \(modelContext != nil)")
        print("TaskFormView: ModelContext description: \(String(describing: modelContext))")
        print("TaskFormView: Task title: \(taskTitle)")
        print("TaskFormView: Task start time: \(startTime)")
        print("TaskFormView: Task duration: \(duration)")
        print("TaskFormView: Task icon: \(selectedIcon)")
        print("TaskFormView: Task color: \(selectedColor)")
        
        // Validate required fields
        guard !taskTitle.isEmpty else {
            print("TaskFormView: Error - Task title is empty")
            return
        }
        
        // Combine selectedDate and startTime
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        
        guard let finalStartTime = calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        )) else {
            print("TaskFormView: Error creating final start time")
            return
        }
        
        print("TaskFormView: Final start time: \(finalStartTime)")
        
        if let taskToEdit = taskToEdit {
            // Update existing task
            print("TaskFormView: Updating existing task")
            
            // Cancel old notifications first
            notificationService.cancelNotifications(for: taskToEdit.id.uuidString)
            
            taskToEdit.title = taskTitle
            taskToEdit.icon = selectedIcon
            taskToEdit.startTime = finalStartTime
            taskToEdit.durationMinutes = duration
            taskToEdit.color = selectedColor
            taskToEdit.taskType = selectedTaskType
            taskToEdit.repeatRule = repeatRule
            taskToEdit.updatedAt = Date()
            taskToEdit.isCompleted = false
            
            print("TaskFormView: Task updated in memory")
            
            do {
                try modelContext.save()
                print("TaskFormView: Task updated successfully in database")
                
                // Schedule new notifications for updated task
                notificationService.scheduleTaskReminders(for: taskToEdit)
                print("TaskFormView: Rescheduled notifications for updated task")
                
            } catch {
                print("TaskFormView: Error updating task: \(error)")
                print("TaskFormView: Error details: \(error.localizedDescription)")
            }
        } else {
            // Create new task
            print("TaskFormView: Creating new task")
            
            let newTask = Task(
                title: taskTitle,
                icon: selectedIcon,
                startTime: finalStartTime,
                durationMinutes: duration,
                color: selectedColor,
                taskType: selectedTaskType,
                repeatRule: repeatRule
            )
            
            print("TaskFormView: New task created with ID: \(newTask.id)")
            print("TaskFormView: New task title: \(newTask.title)")
            print("TaskFormView: New task start time: \(newTask.startTime)")
            
            modelContext.insert(newTask)
            print("TaskFormView: Task inserted into ModelContext")
            
            do {
                try modelContext.save()
                print(">>>>>>> TaskFormView: Task created successfully and saved to database")
                print("TaskFormView: Saved task ID: \(newTask.id)")
                
                // Verify the task was actually saved by trying to fetch it
                let descriptor = FetchDescriptor<Task>()
                let allTasks = try modelContext.fetch(descriptor)
                let savedTasks = allTasks.filter { $0.id == newTask.id }
                print("TaskFormView: Verification - Found \(savedTasks.count) tasks with ID \(newTask.id)")
                
                // Schedule notifications for new task
                notificationService.scheduleTaskReminders(for: newTask)
                print("TaskFormView: Scheduled notifications for new task")
                
                // Show confirmation if notifications are enabled
                if notificationService.isAuthorized {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a 'on' MMM d"
                    let timeString = formatter.string(from: finalStartTime)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        notificationService.sendImmediateNotification(
                            title: "✅ Task Created",
                            body: "'\(taskTitle)' scheduled for \(timeString)"
                        )
                    }
                }
                
            } catch {
                print(">>>>>TaskFormView: Error creating task: \(error)")
                print("TaskFormView: Error details: \(error.localizedDescription)")
            }
        }
        
        print("TaskFormView: Dismissing form")
        dismiss()
    }
}

#Preview {
    TaskFormView()
        .environmentObject(NotificationService.shared)
}
