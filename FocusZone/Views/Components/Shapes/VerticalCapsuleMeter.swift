import SwiftUI

enum CapsuleMeterKind {
    case auto
    case capsule
    case circle
}

/// A vertical meter rendered as a capsule or a circle that fills from the top
/// according to progress (0.0...1.0).
struct VerticalCapsuleMeter<OverlayContent: View>: View {
    let totalHeight: CGFloat
    let width: CGFloat
    let backgroundColor: Color
    let baseColor: Color
    let progress: Double
    let isCompleted: Bool
    let kind: CapsuleMeterKind
    let outlineColor: Color?
    let outlineWidth: CGFloat
    @ViewBuilder var overlayContent: () -> OverlayContent

    init(
        totalHeight: CGFloat,
        width: CGFloat = 56,
        backgroundColor: Color,
        baseColor: Color,
        progress: Double,
        isCompleted: Bool,
        kind: CapsuleMeterKind = .auto,
        outlineColor: Color? = nil,
        outlineWidth: CGFloat = 1,
        @ViewBuilder overlayContent: @escaping () -> OverlayContent
    ) {
        self.totalHeight = totalHeight
        self.width = width
        self.backgroundColor = backgroundColor
        self.baseColor = baseColor
        self.progress = min(max(progress, 0.0), 1.0)
        self.isCompleted = isCompleted
        self.kind = kind
        self.outlineColor = outlineColor
        self.outlineWidth = outlineWidth
        self.overlayContent = overlayContent
    }

    var body: some View {
        ZStack {
            shape.fill(backgroundColor)

            if isCompleted {
                shape.fill(baseColor)
            } else if progress > 0 {
                GeometryReader { proxy in
                    let h = proxy.size.height
                    let fill = max(minFillHeight, h * CGFloat(progress))
                    VStack(spacing: 0) {
                        Rectangle()
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
                            .frame(height: fill)
                            .animation(.easeInOut(duration: 0.35), value: progress)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask(shape)
                }
            }

            if let outlineColor {
                shape.stroke(outlineColor, lineWidth: outlineWidth)
            }

            overlayContent()
                .frame(height: totalHeight)
        }
        .frame(width: width, height: totalHeight)
    }

    private var minFillHeight: CGFloat { 12 }

    private var shape: AnyShape {
        switch resolvedKind {
        case .capsule:
            return AnyShape(Capsule())
        case .circle:
            return AnyShape(Circle())
        case .auto:
            return AnyShape(Capsule())
        }
    }

    private var resolvedKind: CapsuleMeterKind {
        switch kind {
        case .auto:
            // choose circle if height roughly equals width
            let ratio = totalHeight / width
            return ratio <= 1.2 ? .circle : .capsule
        default:
            return kind
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
            isCompleted: false,
            outlineColor: .black.opacity(0.7)
        )
        {
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
            isCompleted: false,
            outlineColor: .black.opacity(0.7)
        ) {
            Text("🏃‍♂️")
                .font(.title2)
                .foregroundColor(.white)
        }
        
        VerticalCapsuleMeter(
            totalHeight: 60,
            width: 56,
            backgroundColor: .purple.opacity(0.25),
            baseColor: .purple,
            progress: 0.2,
            isCompleted: false,
            outlineColor: .black.opacity(0.7)
        ) {
            Text("🏃‍♂️")
                .font(.title2)
                .foregroundColor(.white)
        }

        // Circle 30%
        VerticalCapsuleMeter(
            totalHeight: 56,
            width: 56,
            backgroundColor: .teal.opacity(0.25),
            baseColor: .teal,
            progress: 0.3,
            isCompleted: false,
            kind: .circle,
            outlineColor: .black.opacity(0.7)
        ) { EmptyView() }

        // Small circle 100%
        VerticalCapsuleMeter(
            totalHeight: 44,
            width: 44,
            backgroundColor: .orange.opacity(0.25),
            baseColor: .orange,
            progress: 1.0,
            isCompleted: true,
            kind: .circle,
            outlineColor: .black.opacity(0.7)
        ) { EmptyView() }
    }
    .padding()
    .background(Color.black)
}


