import SwiftUI

struct DateSelector: View {
    @Binding var selectedDate: Date

    var body: some View {
        DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
            .datePickerStyle(.graphical)
            .accentColor(AppColors.accent)
            .padding()
            .background(AppColors.card)
            .cornerRadius(12)
    }
}
