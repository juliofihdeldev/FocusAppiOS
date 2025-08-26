import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    @State private var animateContent = false
        
    var body: some View {
        ZStack {
            // Beautiful gradient background inspired by the serene landscape
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0), // Light sky blue
                    Color(red: 0.9, green: 0.95, blue: 1.0),  // Soft blue
                    Color(red: 0.85, green: 0.9, blue: 0.98)  // Deeper blue
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Image("landscape")
                .resizable()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.6 as CGFloat)
                .opacity(0.5)
            Spacer()
            
            VStack(spacing: 0) {
                // Top section with logo and category
                VStack(spacing: 16) {
                    Spacer()
                    // Logo section
                    HStack {
                        ZStack {
                        
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange,
                                            Color.orange.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                
                                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            
                        }.padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FocusZEN+")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                            
                            Text("PRODUCTIVITY")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.orange.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : -20)
                    
                    // Content section
                    VStack(spacing: 24) {
                      
                        // Description
                        Text("Discover the ultimate focus companion that helps you achieve more in less time.")
                            .font(AppFonts.headline())
                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.6))
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 40)
                            .lineLimit(5)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        // Feature highlights
                        VStack(spacing:26) {
                            FeatureRow(icon: "brain.head.profile", title: "AI-Powered Focus Assistant", color: .blue)
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Progress Analytics & Insights", color: .green)
                            FeatureRow(icon: "timer", title: "Smart Pomodoro Timers", color: .orange)
                            FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Intelligent Break Suggestions", color: .pink)
                            FeatureRow(icon: "folder.badge.plus", title: "Customizable Focus Modes", color: .brown)
                            FeatureRow(icon: "icloud.fill", title: "Cloud Sync & Backup", color: .purple)
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        
                        Spacer()
                    }
                    
                    // Bottom section
                    VStack(spacing: 20) {
                        // Beautiful Slider Get Started Button
                        SliderGetStartedButton(
                            backgroundColor: Color.green,
                            onComplete: completeOnboarding
                        )
                        .padding(.horizontal, 40)
                        
                        // Log In button
                        Button(action: completeOnboarding) {
                            Text("Skip")
                                .font(AppFonts.headline())
                            .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white)
                                    .shadow(radius: 1)
                            )
                        }
                        .padding(.horizontal, 40)
                        
                        // Terms and Conditions
                        Button(action: {}) {
                            Text("Terms & Conditions")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                        }
                        .padding(.bottom, 20)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animateContent = true
                }
            }
            .animation(.easeInOut(duration: 0.5), value: currentPage)
        }
    }
        
    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            hasSeenOnboarding = true
        }
    }
}


// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(AppFonts.headline())
                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
            
            Spacer()
        }
        .padding(.horizontal, 20)
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
                .fill(Color.white.opacity(0.3))
                .frame(height: buttonHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: buttonHeight / 2)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
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
                Spacer()
                Text(showCompletion ? "Welcome!" : "Slide to Get Started")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.7))
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

#Preview {
    OnboardingView()
}
