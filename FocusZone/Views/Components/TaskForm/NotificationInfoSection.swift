import SwiftUI

struct NotificationInfoSection: View {
    @Environment(\.modelContext) private var modelContext
    private let notificationService = NotificationService.shared
    var body : some View {
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                Text(NSLocalizedString("notifications", comment: "Notifications section title"))
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if notificationService.isAuthorized {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(NSLocalizedString("notifications_enabled", comment: "Notifications enabled status"))
                            .font(AppFonts.body())
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("you_will_receive", comment: "You will receive notifications list header"))
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                        
                        Text(NSLocalizedString("five_minutes_before", comment: "5 minutes before task starts notification"))
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                        
                        Text(NSLocalizedString("when_task_starts", comment: "When task starts notification"))
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                        
                        Text(NSLocalizedString("completion_confirmation", comment: "Completion confirmation notification"))
                            .font(AppFonts.caption())
                            .foregroundColor(.gray)
                    }
                } else {
                    HStack {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(.orange)
                        Text(NSLocalizedString("notifications_disabled", comment: "Notifications disabled status"))
                            .font(AppFonts.body())
                            .foregroundColor(.orange)
                    }
                    
                    Text(NSLocalizedString("enable_notifications_settings", comment: "Enable notifications in settings message"))
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

