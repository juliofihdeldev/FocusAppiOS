import SwiftUI

struct WeekDateNavigator: View {
    @Binding var selectedDate: Date
    var tasksForDate: [Date: Int] = [:]
    @State private var showingDatePicker = false
    @State private var currentWeekOffset: Int = 0
    private var calendar: Calendar { Calendar.current }
    private var currentWeek: [Date] {
        let startOfSelectedWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let offsetWeekStart = calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: startOfSelectedWeek) ?? startOfSelectedWeek
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: offsetWeekStart) }
    }
    private var isCurrentWeek: Bool { currentWeek.contains { calendar.isDate($0, inSameDayAs: Date()) } }
    
    var body: some View {
        VStack(alignment: .center,  spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: { showingDatePicker = true }) {
                    HStack(spacing: 8) {
                        Text(monthYearString(from: selectedDate))
                            .font(AppFonts.title())
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundColor(AppColors.accent)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { withAnimation(.easeInOut(duration: 0.3)) { currentWeekOffset -= 1; if let first = currentWeek.first { selectedDate = first } } }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(AppColors.accent)
                            .frame(width: 32, height: 32)
                            .background(AppColors.card)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    if !isCurrentWeek {
                        Button(action: { withAnimation(.easeInOut(duration: 0.3)) { selectedDate = Date(); currentWeekOffset = 0 } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location").font(.caption)
                                Text("Today").font(AppFonts.caption()).fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(LinearGradient(gradient: Gradient(colors: [AppColors.accent.opacity(0.9), AppColors.accent]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Capsule())
                            .shadow(color: AppColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    Button(action: { withAnimation(.easeInOut(duration: 0.3)) { currentWeekOffset += 1; if let first = currentWeek.first { selectedDate = first } } }) {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundColor(AppColors.accent)
                            .frame(width: 32, height: 32)
                            .background(AppColors.card)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(currentWeek, id: \.self) { date in
                        DateDayView(
                            date: date,
                            selectedDate: $selectedDate,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasTask: hasTasksForDate(date),
                            taskCount: tasksForDate[normalizeDate(date)] ?? 0
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            HStack {
                ForEach(-2...2, id: \.self) { offset in
                    Circle()
                        .fill(offset == currentWeekOffset ? AppColors.accent : AppColors.accent.opacity(0.2))
                        .frame(width: offset == currentWeekOffset ? 8 : 6, height: offset == currentWeekOffset ? 8 : 6)
                        .animation(.easeInOut(duration: 0.2), value: currentWeekOffset)
                }
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20).fill(AppColors.background).shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2))
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate, currentWeekOffset: $currentWeekOffset)
        }
    }
    
    private func monthYearString(from date: Date) -> String { let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: date) }
    private func normalizeDate(_ date: Date) -> Date { calendar.startOfDay(for: date) }
    private func hasTasksForDate(_ date: Date) -> Bool { (tasksForDate[normalizeDate(date)] ?? 0) > 0 }
}

#Preview {
    WeekDateNavigator(
        selectedDate: .constant(Date()),
        tasksForDate: [
            Calendar.current.startOfDay(for: Date()): 3,
            Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()): 1,
            Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()): 2
        ]
    )
    .environmentObject(ThemeManager())
    .padding()
    .background(Color.gray.opacity(0.1))
}


