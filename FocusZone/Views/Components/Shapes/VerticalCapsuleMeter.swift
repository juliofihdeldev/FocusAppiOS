import SwiftUI

/// A vertical capsule that represent a total duration with a fill that grows from the top
/// according to progress (0.0...1.0).
struct VerticalCapsuleMeter<OverlayContent: View>: View {
    let totalHeight: CGFloat
    let width: CGFloat
    let backgroundColor: Color
    let baseColor: Color
    let progress: Double
    let isCompleted: Bool
    @ViewBuilder var overlayContent: () -> OverlayContent

    init(
        totalHeight: CGFloat,
        width: CGFloat = 56,
        backgroundColor: Color,
        baseColor: Color,
        progress: Double,
        isCompleted: Bool,
        @ViewBuilder overlayContent: @escaping () -> OverlayContent
    ) {
        self.totalHeight = totalHeight
        self.width = width
        self.backgroundColor = backgroundColor
        self.baseColor = baseColor
        self.progress = min(max(progress, 0.0), 1.0)
        self.isCompleted = isCompleted
        self.overlayContent = overlayContent
    }

    var body: some View {
        ZStack {
            Capsule()
                .fill(backgroundColor)
                .frame(width: width, height: totalHeight)

            if isCompleted {
                Capsule()
                    .fill(baseColor)
                    .frame(width: width, height: totalHeight)
            } else if progress > 0 {
                VStack(spacing: 0) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    baseColor.opacity(0.9),
                                    baseColor.opacity(0.25)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: width, height: fillHeight)
                        .modifier(TopRoundedOrFullCapsuleModifier(
                            showFull: progress >= 0.98
                        ))
                        .animation(.easeInOut(duration: 0.35), value: progress)

                    Spacer(minLength: 0)
                }
                .frame(width: width, height: totalHeight)
            }

            overlayContent()
                .frame(height: totalHeight)
        }
        .frame(width: width, height: totalHeight)
    }

    private var fillHeight: CGFloat {
        // keep a small minimum so it feels visible at very small progress
        let minHeight: CGFloat = 12
        let calculated = totalHeight * CGFloat(progress)
        return max(minHeight, calculated)
    }
}

private struct TopRoundedOrFullCapsuleModifier: ViewModifier {
    let showFull: Bool

    func body(content: Content) -> some View {
        if showFull {
            content.clipShape(Capsule())
        } else {
            content.clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 28,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 28
                )
            )
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        VerticalCapsuleMeter(
            totalHeight: 180,
            width: 56,
            backgroundColor: .blue.opacity(0.25),
            baseColor: .blue,
            progress: 0.6,
            isCompleted: false
        ) {
            Text("💼")
                .font(.title2)
                .foregroundColor(.white)
        }

        VerticalCapsuleMeter(
            totalHeight: 140,
            width: 56,
            backgroundColor: .purple.opacity(0.25),
            baseColor: .purple,
            progress: 0.2,
            isCompleted: false
        ) {
            Text("🏃‍♂️")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
    .padding()
    .background(Color.black)
}


