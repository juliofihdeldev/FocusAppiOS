import SwiftUI

struct DateHeader: View {
    @Binding var selectedDate: Date
    var tasksForDate: [Date: Int] = [:] // Optional: tasks count per date
    @State private var showingDatePicker = false
    @State private var currentWeekOffset: Int = 0
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    // Get the current week based on selected date and offset
    private var currentWeek: [Date] {
        let startOfSelectedWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let offsetWeekStart = calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: startOfSelectedWeek) ?? startOfSelectedWeek
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: offsetWeekStart)
        }
    }
    
    // Check if we're viewing the current week
    private var isCurrentWeek: Bool {
        let today = Date()
        return currentWeek.contains { calendar.isDate($0, inSameDayAs: today) }
    }
    
    var body: some View {
        
        VStack(alignment: .center,  spacing: 16) {
            // Header with month/year and controls
            HStack(alignment: .center, spacing: 12) {
                // Month and Year (tappable for date picker)
                Button(action: {
                    showingDatePicker = true
                }) {
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
                
                // Navigation Controls
                HStack(spacing: 16) {
                    // Previous week button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentWeekOffset -= 1
                            if let firstDayOfWeek = currentWeek.first {
                                selectedDate = firstDayOfWeek
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(AppColors.accent)
                            .frame(width: 32, height: 32)
                            .background(AppColors.card)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    
                    // Today button (only show if not viewing current week)
                    if !isCurrentWeek {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedDate = Date()
                                currentWeekOffset = 0
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "location")
                                    .font(.caption)
                                Text("Today")
                                    .font(AppFonts.caption())
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [AppColors.accent.opacity(0.9), AppColors.accent]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: AppColors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    
                    // Next week button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentWeekOffset += 1
                            if let firstDayOfWeek = currentWeek.first {
                                selectedDate = firstDayOfWeek
                            }
                        }
                    }) {
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
            
            // Week Days Scroll
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
            // Week navigation indicator
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
    
        .frame(width: .infinity, alignment: .top)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.background)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate, currentWeekOffset: $currentWeekOffset)
        }
    }
    
    // MARK: - Helper Functions
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func hasTasksForDate(_ date: Date) -> Bool {
        return tasksForDate[normalizeDate(date)] != nil && tasksForDate[normalizeDate(date)]! > 0
    }
    
    private func normalizeDate(_ date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }
}

// MARK: - Individual Day View Component

struct DateDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let isSelected: Bool
    let isToday: Bool
    let hasTask: Bool
    let taskCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Weekday label
            Text(shortWeekdayString(from: date))
                .font(AppFonts.caption())
                .fontWeight(.medium)
                .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
            
            // Day number with background
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundGradient)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: isToday && !isSelected ? 2 : 0)
                    )
                    .shadow(
                        color: isSelected ? AppColors.accent.opacity(0.3) : .clear,
                        radius: isSelected ? 8 : 0,
                        x: 0,
                        y: isSelected ? 4 : 0
                    )
                
                // Day number
                Text(dayString(from: date))
                    .font(AppFonts.body())
                    .fontWeight(isSelected ? .bold : .semibold)
                    .foregroundColor(textColor)
                
                // Task indicator
                if hasTask && !isSelected {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(AppColors.accent)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Text("\(taskCount)")
                                        .font(.system(size: 6, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 2, y: 2)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedDate = date
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundGradient: LinearGradient {
        if isSelected {
            return LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.accent.opacity(0.9),
                    AppColors.accent
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isToday {
            return LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.accent.opacity(0.15),
                    AppColors.accent.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.card,
                    AppColors.card
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return AppColors.accent
        } else {
            return AppColors.textPrimary
        }
    }
    
    private var borderColor: Color {
        return isToday ? AppColors.accent.opacity(0.5) : .clear
    }
    
    // MARK: - Helper Functions
    
    private func shortWeekdayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Date Picker Sheet

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
                
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .accentColor(AppColors.accent)
                .padding()
                .background(AppColors.card)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Quick date options
                VStack(spacing: 12) {
                    Text("Quick Select")
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 12) {
                        QuickDateButton(title: "Today", date: Date())
                        QuickDateButton(title: "Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
                        QuickDateButton(title: "Next Week", date: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date())
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
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Reset week offset when jumping to a specific date
                        currentWeekOffset = 0
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    @ViewBuilder
    private func QuickDateButton(title: String, date: Date) -> some View {
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

#Preview {
    DateHeader(
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
