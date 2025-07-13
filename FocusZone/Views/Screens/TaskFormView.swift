import SwiftUI

struct PreviewTask {
    let title: String
    let color: Color
    let duration: Int
    let icon: String
}

struct TaskFormView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var taskTitle: String = ""
    @State private var selectedDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var duration: Int = 15
    @State private var selectedColor: Color = .pink
    @State private var repeatRule: String = "Once"
    @State private var alerts: [String] = ["At start of task"]
    @State private var showSubtasks: Bool = false
    @State private var notes: String = ""
    @State private var showingTimeSlots: Bool = false
    @State private var showingPreviewTasks: Bool = false


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
                        
                        TaskTimeSelector(
                            selectedDate: $selectedDate,
                            startTime: $startTime
                        )
                        
                        TaskDurationSelector(duration: $duration)
                        
                        TaskColorPicker(selectedColor: $selectedColor)
                        
                        TaskRepeatSelector(repeatRule: $repeatRule)
                        
                        // Create Task Button
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Create Task")
                                .font(AppFonts.headline())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.pink)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        TaskAlertsSection(alerts: $alerts)
                        
                        TaskDetailsSection(
                            showSubtasks: $showSubtasks,
                            notes: $notes
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(AppColors.background.ignoresSafeArea())
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    TaskFormView()
}
