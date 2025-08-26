import SwiftUI

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var currentPage = 0
        
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
                    Text("FocusZen+")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Focus on what really matters. Let Us help you stay on track.")
                                            .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                        
                
                    // Features showcase
                    VStack(spacing: 16) {
                    
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            FeatureCard(
                                icon: "brain.head.profile",
                                title: "AI Focus Assistant",
                                description: "Smart task optimization",
                                color: .blue
                            )
                            
                            FeatureCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Analytics & Insights",
                                description: "Track your progress",
                                color: .green
                            )
                            
                            FeatureCard(
                                icon: "timer",
                                title: "Smart Timers",
                                description: "Pomodoro & custom",
                                color: .orange
                            )
                            
                            FeatureCard(
                                icon: "icloud.fill",
                                title: "Cloud Sync",
                                description: "Access anywhere",
                                color: .purple
                            )
                            
                            FeatureCard(
                                icon: "bell.badge",
                                title: "Smart Notifications",
                                description: "Never miss a task",
                                color: .red
                            )
                            
                            FeatureCard(
                                icon: "paintbrush.fill",
                                title: "Custom Themes",
                                description: "Personalize your app",
                                color: .pink
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                // Bottom buttons
                VStack(spacing: 22) {
                    // Beautiful Slider Get Started Button
                    SliderGetStartedButton(
                        backgroundColor: Color.blue.opacity(0.8),
                        onComplete: completeOnboarding
                    )
                    .padding(.horizontal, 40)
                    
                    // Skip button
                    Button(action: completeOnboarding) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
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

// MARK: - Slider Get Started Button
struct SliderGetStartedButton: View {
    let backgroundColor: Color
    let onComplete: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showCompletion = false
    
    private let buttonHeight: CGFloat = 60
    private let maxDragDistance: CGFloat = 250
    
    var body: some View {
        ZStack {
            // Background track
            RoundedRectangle(cornerRadius: buttonHeight / 2)
                .fill(Color.white.opacity(0.2))
                .frame(height: buttonHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: buttonHeight / 2)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            // Progress track
            HStack {
                RoundedRectangle(cornerRadius: buttonHeight / 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [backgroundColor, backgroundColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(70, dragOffset + buttonHeight / 2), height: buttonHeight)
                
                Spacer()
            }
            
            // Slider handle
            HStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: buttonHeight - 8, height: buttonHeight - 8)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    if showCompletion {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .foregroundColor(backgroundColor)
                            .fontWeight(.bold)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundColor(backgroundColor)
                            .fontWeight(.bold)
                    }
                }
                .offset(x: dragOffset - 120)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            let translation = value.translation
                            dragOffset = min(maxDragDistance, max(0, translation.width))
                        }
                        .onEnded { value in
                            isDragging = false
                            
                            if dragOffset >= maxDragDistance * 0.7 {
                                // Complete the slide
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    dragOffset = maxDragDistance
                                    showCompletion = true
                                }
                                
                                // Trigger completion after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    onComplete()
                                }
                            } else {
                                // Reset to start
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                
                Spacer()
            }
            
            // Text overlay
            HStack {
                Text(showCompletion ? "Welcome!" : "Slide to Get Started")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white)
                    .opacity(showCompletion ? 1 : (dragOffset > 50 ? 0 : 1))
                    .animation(.easeInOut(duration: 0.3), value: showCompletion)
                
                Spacer()
            }
            .padding(.leading, 20)
            .allowsHitTesting(false)
        }
        .frame(height: buttonHeight)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .fontWeight(.semibold)
            }
            
            // Title
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Description
            Text(description)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    OnboardingView()
}
