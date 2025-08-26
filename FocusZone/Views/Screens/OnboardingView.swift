import SwiftUI

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var currentPage = 0
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Focus.",
            quote: "It's not how much time we spend, but how much focus we put into every moment.",
            illustration: "🧠",
            backgroundColor: Color(red: 0.2, green: 0.6, blue: 1.0),
            accentColor: Color(red: 0.9, green: 0.3, blue: 0.5)
        ),
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.8),
                    Color.blue.opacity(0.6),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            
            VStack(spacing: 0) {
         
                Spacer()
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    )

                
                // Main content
                VStack(spacing: 30) {
                    // Title
                    Text(onboardingPages[currentPage].title)
                        .font(AppFonts.title()  )
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .onLongPressGesture(minimumDuration: 2) {
                            // Reset onboarding for testing (long press for 2 seconds)
                            onboardingManager.resetOnboarding()
                        }
                    
                    // Quote
                    Text(onboardingPages[currentPage].quote)
                        .font(AppFonts.headline())
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                
                    // Features showcase
                    VStack(spacing: 12) {
                        ForEach(Array(ProFeatures.proFeaturesList.enumerated()), id: \.offset) { index, feature in
                            FeatureRow(
                                icon: getFeatureIcon(for: index),
                                title: feature,
                                delay: Double(index) * 0.1,
                                description: "Pro feature"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                }
                
                Spacer()
                
                // Bottom buttons
                VStack(spacing: 20) {
                
                    // Get Started button
                    Button(action: completeOnboarding) {
                        Text("Get Started")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(onboardingPages[currentPage].backgroundColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(28)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .accessibilityLabel("Get Started")
                    .accessibilityHint("Tap to begin using the app")
                    
                   
                }
                .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentPage)
    }
        
    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            onboardingManager.completeOnboarding()
        }
    }
}

private func getFeatureIcon(for index: Int) -> String {
    let icons = [
        "infinity.circle.fill",
        "chart.line.uptrend.xyaxis",
        "brain.head.profile",
        "lightbulb.fill",
        "magnifyingglass.circle.fill",
        "doc.text.fill",
        "paintbrush.fill",
        "icloud.fill",
        "headphones.circle.fill"
    ]
    return icons[safe: index] ?? "star.fill"
}


struct OnboardingPage {
    let title: String
    let quote: String
    let illustration: String
    let backgroundColor: Color
    let accentColor: Color
}

#Preview {
    OnboardingView()
}
