import SwiftUI
import UIKit
import CoreGraphics
import QuartzCore

struct ConfettiCelebrationView: View {
    @Binding var isPresented: Bool
    var title: String = "Great job!"
    var subtitle: String? = "Task completed"
    var accent: Color = AppColors.accent
    var duration: TimeInterval = 4
    var onClose: (() -> Void)?

    @State private var startTime: Date = Date()

    var body: some View {
        ZStack {
            // Dimmed, vibrant background
            LinearGradient(colors: [accent.opacity(0.3), Color.black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 10) {
                    Text(title)
                        .font(AppFonts.largetitle())
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppFonts.subheadline())
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                Spacer()

                Button(action: close) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .white.opacity(0.8))
                            .font(.headline)
                        Text("Close")
                            .font(AppFonts.headline())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                }
                .buttonStyle(CelebrationCapsuleButtonStyle(accent: accent))
                .accessibilityLabel("Close celebration")
                .padding(.bottom, 30)
            }

            // Confetti Layer (UIKit emitter for reliability and performance)
            ConfettiEmitter(colors: [.systemPink, .systemYellow, .systemTeal, .systemPurple, .systemOrange, UIColor(accent)])
                .allowsHitTesting(false)
        }
        .onAppear {
            startTime = Date()
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
        }
    }

    private func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            isPresented = false
        }
        onClose?()
    }
}

// MARK: - Button Style

private struct CelebrationCapsuleButtonStyle: ButtonStyle {
    let accent: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [accent.opacity(0.95), accent.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .overlay(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.28), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .blendMode(.screen)
            )
            .shadow(color: accent.opacity(0.45), radius: 12, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

// MARK: - UIKit Emitter-backed Confetti

private struct ConfettiEmitter: UIViewRepresentable {
    let colors: [UIColor]
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        addEmitter(to: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if uiView.layer.sublayers?.contains(where: { $0 is CAEmitterLayer }) != true {
            addEmitter(to: uiView)
        }
    }
    
    private func addEmitter(to view: UIView) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitter.emitterSize = CGSize(width: view.bounds.width + 40, height: 2)
        emitter.emitterShape = .line
        emitter.birthRate = 1
        emitter.beginTime = CACurrentMediaTime()
        emitter.emitterMode = .surface
        emitter.renderMode = .additive
        emitter.masksToBounds = false

        let cells = colors.map { color -> CAEmitterCell in
            let cell = CAEmitterCell()
            cell.birthRate = 14
            cell.lifetime = 6
            cell.lifetimeRange = 1.5
            cell.velocity = 160
            cell.velocityRange = 80
            cell.yAcceleration = 120
            cell.xAcceleration = 4
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3
            cell.spinRange = 6
            cell.scale = 0.3
            cell.scaleRange = 0.2
            cell.color = color.cgColor
            cell.contents = particleImage().cgImage
            return cell
        }
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        // Layout update
        DispatchQueue.main.async {
            emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
            emitter.emitterSize = CGSize(width: view.bounds.width + 40, height: 2)
        }
    }
    
    private func particleImage() -> UIImage {
        let size = CGSize(width: 4, height: 6)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 1).addClip()
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}


