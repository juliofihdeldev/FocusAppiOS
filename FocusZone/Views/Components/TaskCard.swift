import SwiftUI

 struct TaskCard: View {
    var title: String
    var time: String
    var icon: String
    var color: Color
    var isCompleted: Bool
    var durationMinutes: Int = 60

    var body: some View {
        let minHeight: CGFloat = 50
        let height = isCompleted ? minHeight :  max(minHeight, CGFloat(durationMinutes))
        let timeSpentOnTask = Double(durationMinutes) / 1.5
    
        HStack(alignment: .center, spacing: 12) {
            
            ZStack {
                if !isCompleted {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                        gradient: Gradient(colors: [color.opacity(1), Color.green.opacity(0.0)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                        )
                        .frame(width: 50, height: height)
                        .offset(y:-20)
                }
                
                Text(icon)
                    .frame(width: 50, height: height)
                 
            }
            .background(isCompleted ? color : AppColors.lightGray)
            .cornerRadius(40)
            .overlay(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(isCompleted ? color  : Color.gray, lineWidth: 1)
            )
                     
            VStack(alignment: .leading, spacing: 4) {
                
                Text(time)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
                
                Text(title)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.accent)
            } else {
                EmptyView()
            }
        }
        .padding(
            .horizontal, 16
        )
        .background(AppColors.card)
        .shadow(radius: 2)
    }
}


#Preview {
    TaskCard(title: "Task 1", time: "1h 30m", icon: "⏰", color: .red, isCompleted: false , durationMinutes:120)
    TaskCard(title: "Task 1", time: "1h 30m", icon: "⏰", color: .blue, isCompleted: true , durationMinutes:220
    )
}
