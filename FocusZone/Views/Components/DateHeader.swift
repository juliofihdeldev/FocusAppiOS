import SwiftUI

struct DateHeader: View {
    @Binding var selectedDate: Date
    var tasksForDate: [Date: Int] = [:] // Optional: tasks count per date
    
    private var currentWeek: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        
        let startOfWeek = calendar.date(byAdding: .day, value: -((weekday - calendar.firstWeekday + 7) % 7), to: selectedDate) ?? selectedDate
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

                            ZStack {
                                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
                                
                                Text(dayString(from: date))
                                    .font(AppFonts.body())
                                    .fontWeight(isSelected ? .bold : .regular)
                                    .foregroundColor(isSelected ? .white : (isToday ? AppColors.accent : .gray))
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? AppColors.accent : Color.clear)
                                            .overlay(
                                                Circle()
                                                    .stroke(isToday && !isSelected ? AppColors.accent : Color.clear, lineWidth: 1)
                                            )
                                    )
                                
                                // Task indicator dot
                                if hasTasksForDate(date) {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Circle()
                                                .fill(isSelected ? .white : AppColors.accent)
                                                .frame(width: 6, height: 6)
                                                .offset(x: -2, y: -2)
                                        }
                                    }
                                }
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = date
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        Spacer(minLength: 0)
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
    
    private func hasTasksForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return tasksForDate.keys.contains { calendar.isDate($0, inSameDayAs: date) }
    }
}

#Preview {
    DateHeader(selectedDate: .constant(Date()))
        .environmentObject(ThemeManager())
}
