import SwiftUI

struct TaskColorPicker: View {
    @Binding var selectedColor: Color
    
    // Keep a concise set of quick presets; use ColorPicker for everything else
    private let quickColors: [Color] = [
        .pink, .orange, .yellow, .green, .teal, .blue, .purple
    ]
    
    @State private var showPickerSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("What color?")
                    .font(AppFonts.headline())
                    .foregroundColor(.gray)
                Spacer()
                Button("More…") { showPickerSheet = true }
                    .font(.system(size: 16))
                    .foregroundColor(.pink)
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityIdentifier("taskColorPickerMoreButton")
            }
            
            // Quick colors row
            colorRow(colors: quickColors)
        }
        .sheet(isPresented: $showPickerSheet) {
            NavigationView {
                VStack(spacing: 24) {
                    ColorPicker("Pick a color", selection: $selectedColor, supportsOpacity: false)
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("Color")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showPickerSheet = false }
                    }
                }
            }
        }
    }

    private func colorRow(colors: [Color]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(colors.indices, id: \.self) { idx in
                    let color = colors[idx]
                    Button(action: { withAnimation(.spring()) { selectedColor = color } }) {
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
                                    .scaleEffect(1.25)
                                    .opacity(selectedColor == color ? 1 : 0)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    @Previewable @State var selectedColor = Color.pink
    
    return TaskColorPicker(selectedColor: $selectedColor)
}
