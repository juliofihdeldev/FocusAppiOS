import SwiftUI

struct TaskColorPicker: View {
    @Binding var selectedColor: Color
    
    let colors: [Color] = [.pink, .orange, .yellow, .green, .blue, .teal, .purple]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("What color?")
                    .font(AppFonts.headline())
                    .foregroundColor(.gray)
                Spacer()
                Button("More...") {}
                    .font(.system(size: 16))
                    .foregroundColor(.pink)
            }
            
            HStack(spacing: 16) {
                ForEach(colors, id: \.self) { color in
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedColor = color
                        }
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .opacity(selectedColor == color ? 1 : 0)
                            )
                            .overlay(
                                Circle()
                                    .stroke(color, lineWidth: 3)
                                    .scaleEffect(1.3)
                                    .opacity(selectedColor == color ? 1 : 0)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

#Preview {
    @State var selectedColor = Color.pink
    
    return TaskColorPicker(selectedColor: $selectedColor)
}