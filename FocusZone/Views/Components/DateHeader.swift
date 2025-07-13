import SwiftUI

struct DateHeader: View {
    @Binding var selectedDate: Date

    private var currentWeek: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        let startOfWeek = calendar.date(byAdding: .day, value: -((weekday - calendar.firstWeekday + 7) % 7), to: today) ?? today
        return (0..<365).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthYearString(from: selectedDate))
                .font(AppFonts.title())
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(currentWeek, id: \ .self) { date in
                        VStack(spacing: 4) {
                            Text(shortWeekdayString(from: date))
                                .font(AppFonts.caption())
                                .foregroundColor(.gray)

                            Text(dayString(from: date))
                                .font(AppFonts.body())
                                .fontWeight(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .bold : .regular)
                                .foregroundColor(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .white : .gray)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? AppColors.accent : Color.clear)
                                )
                        }
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    func shortWeekdayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    DateHeader(selectedDate: .constant(Date()))
        .environmentObject(ThemeManager())
}
