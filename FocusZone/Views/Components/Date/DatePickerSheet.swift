import SwiftUI

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var currentWeekOffset: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Date")
                    .font(AppFonts.title())
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, 20)
                
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .accentColor(AppColors.accent)
                    .padding()
                    .background(AppColors.card)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 12) {
                    Text("Quick Select")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                    HStack(spacing: 12) {
                        quickDateButton(title: "Today", date: Date())
                        quickDateButton(title: "Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                        quickDateButton(title: "Next Week", date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date())
                    }
                }
                .padding()
                .background(AppColors.card)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(AppColors.background)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        currentWeekOffset = 0
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func quickDateButton(title: String, date: Date) -> some View {
        Button(action: {
            selectedDate = date
            currentWeekOffset = 0
            dismiss()
        }) {
            Text(title)
                .font(AppFonts.caption())
                .fontWeight(.medium)
                .foregroundColor(AppColors.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppColors.accent.opacity(0.1))
                .cornerRadius(20)
        }
    }
}


