import SwiftUI

struct TaskFormHeader: View {
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text("New Task")
                .font(AppFonts.title())
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
}

#Preview {
    TaskFormHeader(onDismiss: {})
}