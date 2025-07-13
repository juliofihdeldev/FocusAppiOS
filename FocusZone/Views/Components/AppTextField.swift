import SwiftUI

struct AppTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(AppFonts.body())
            .padding()
            .background(AppColors.card)
            .foregroundColor(AppColors.textPrimary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.accent, lineWidth: 1)
            )
    }
}
