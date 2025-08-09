import SwiftUI

struct DateDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let isSelected: Bool
    let isToday: Bool
    let hasTask: Bool
    let taskCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text(shortWeekdayString(from: date))
                .font(AppFonts.caption())
                .fontWeight(.medium)
                .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
            
            ZStack {
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
                
                Text(dayString(from: date))
                    .font(AppFonts.body())
                    .fontWeight(isSelected ? .bold : .semibold)
                    .foregroundColor(textColor)
                
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
        .onTapGesture { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selectedDate = date } }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
    
    // MARK: - Computed
    private var backgroundGradient: LinearGradient {
        if isSelected {
            return LinearGradient(gradient: Gradient(colors: [AppColors.accent.opacity(0.9), AppColors.accent]), startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if isToday {
            return LinearGradient(gradient: Gradient(colors: [AppColors.accent.opacity(0.15), AppColors.accent.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(gradient: Gradient(colors: [AppColors.card, AppColors.card]), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    private var textColor: Color { isSelected ? .white : (isToday ? AppColors.accent : AppColors.textPrimary) }
    private var borderColor: Color { isToday ? AppColors.accent.opacity(0.5) : .clear }
    
    // MARK: - Helpers
    private func shortWeekdayString(from date: Date) -> String { let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: date) }
    private func dayString(from date: Date) -> String { let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date) }
}


