import SwiftUI

struct AlertBox: View {
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.danger)

            Text(message)
                .font(AppFonts.body())
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.card)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
