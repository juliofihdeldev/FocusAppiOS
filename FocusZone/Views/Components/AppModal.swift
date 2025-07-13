import SwiftUI

struct AppModal<Content: View>: View {
    var isPresented: Binding<Bool>
    var title: String
    let content: Content

    init(isPresented: Binding<Bool>, title: String, @ViewBuilder content: () -> Content) {
        self.isPresented = isPresented
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)

            content

            AppButton(title: "Close") {
                isPresented.wrappedValue = false
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
        .cornerRadius(20)
        .padding()
    }
}
