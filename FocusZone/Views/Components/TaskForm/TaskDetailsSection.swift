import SwiftUI

struct TaskDetailsSection: View {
    @Binding var showSubtasks: Bool
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Any details?")
                .font(AppFonts.headline())
                .foregroundColor(.gray)
            
            Button(action: {
                withAnimation(.spring()) {
                    showSubtasks.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                    Text("Add Subtask")
                        .font(AppFonts.subheadline())
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.pink)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            TextField("Add notes, meeting links or phone numbers...", text: $notes, axis: .vertical)
                .font(AppFonts.body())
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                .lineLimit(4...8)
        }
    }
}

#Preview {
    @State var showSubtasks = false
    @State var notes = ""
    
    return TaskDetailsSection(
        showSubtasks: $showSubtasks,
        notes: $notes
    )
}