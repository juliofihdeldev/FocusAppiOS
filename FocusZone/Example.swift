import SwiftUI

// MARK: - Example Usage
struct Example: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var notificationsEnabled = true
    @State private var showAlert = false
    @State private var userName = ""
    @State private var showModal = false
    @State private var selectedIcon = "📘"
    @State private var selectedDate = Date()

    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, TaskFlow")
                .font(AppFonts.headline())
                .foregroundColor(theme.currentTextColor)

            AppTextField(placeholder: "Enter task title", text: $userName)

            AppPicker(title: "Icon", options: ["📘", "🏃‍♂️", "📝", "💡"], selection: $selectedIcon)

            DateSelector(selectedDate: $selectedDate)

            TaskCard(title: userName, time: "9:00 AM - 10:00 AM", icon: selectedIcon, color: AppColors.accent, isCompleted: false, durationMinutes: 160)

            AppButton(title: "Show Modal") {
                showModal.toggle()
            }

            AppToggle(title: "Enable Alerts", isOn: $notificationsEnabled)

            if showAlert {
                AlertBox(title: "Heads up!", message: "This is an important reminder.")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.currentBackground)
        .sheet(isPresented: $showModal) {
            AppModal(isPresented: $showModal, title: "My Modal") {
                Text("Here’s a modal body.")
                    .foregroundColor(theme.currentTextColor)
            }
        }
    }
}

#Preview {
    Example()
        .environmentObject(ThemeManager())
}
