import SwiftUI

struct NotificationInfoSection: View {
    @Environment(\.modelContext) private var modelContext
    private let notificationService = NotificationService.shared
    var body : some View {
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                Text("Notifications")
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if notificationService.isAuthorized {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Notifications enabled")
                            .font(AppFonts.body())
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You'll receive:")
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                        
                        Text("• 5 minutes before task starts")
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                        
                        Text("• When task is scheduled to begin")
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                        
                        Text("• Completion confirmation")
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                    }
                } else {
                    HStack {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(.orange)
                        Text("Notifications disabled")
                            .font(AppFonts.body())
                            .foregroundColor(.orange)
                    }
                    
                    Text("Enable notifications in Settings to get task reminders")
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(notificationService.isAuthorized ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        )
    }
}

