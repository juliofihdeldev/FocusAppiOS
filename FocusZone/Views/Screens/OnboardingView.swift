import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    @State private var animateContent = false
    
    private let totalPages = 3
        
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
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .opacity(0.5)
            
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
                    
                    // Page content
                    TabView(selection: $currentPage) {
                        // Screen 1: Welcome & Introduction
                        OnboardingScreen1()
                            .tag(0)
                        
                        // Screen 2: Key Features
                        OnboardingScreen2()
                            .tag(1)
                        
                        // Screen 3: Get Started
                        OnboardingScreen3(onComplete: completeOnboarding)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 400)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.orange : Color.orange.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        // Previous button (hidden on first page)
                        if currentPage > 0 {
                            Button(action: previousPage) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                                .frame(height: 50)
                                .padding(.horizontal, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white)
                                        .shadow(radius: 1)
                                )
                            }
                        }
                        
                        // Next button (hidden on last page)
                        if currentPage < totalPages - 1 {
                            Button(action: nextPage) {
                                HStack {
                                    Text("Next")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .padding(.horizontal, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.orange)
                                        .shadow(radius: 1)
                                )
                            }
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    
                    // Skip button (always visible)
                    Button(action: completeOnboarding) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                    }
                    .padding(.top, 20)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    
                    Spacer()
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
    
    private func nextPage() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage = min(currentPage + 1, totalPages - 1)
        }
    }
    
    private func previousPage() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentPage = max(currentPage - 1, 0)
        }
    }
        
    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            hasSeenOnboarding = true
        }
    }
}

// MARK: - Onboarding Screen 1: Welcome & Introduction
struct OnboardingScreen1: View {
    var body: some View {
        VStack(spacing: 30) {
            // Main title
            Text("Transform Your Productivity")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Description
            Text("Discover the ultimate focus companion that helps you achieve more in less time. Our AI-powered app combines smart time management with personalized insights to boost your productivity and maintain work-life balance.")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .lineLimit(6)
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.orange)
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Onboarding Screen 2: Key Features
struct OnboardingScreen2: View {
    var body: some View {
        VStack(spacing: 25) {
            // Title
            Text("Powerful Features")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                .padding(.top, 20)
            
            // Features grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                FeatureCard(icon: "brain.head.profile", title: "AI Assistant", color: .blue)
                FeatureCard(icon: "chart.line.uptrend.xyaxis", title: "Analytics", color: .green)
                FeatureCard(icon: "timer", title: "Smart Timers", color: .orange)
                FeatureCard(icon: "arrow.triangle.2.circlepath", title: "Break Suggestions", color: .pink)
                FeatureCard(icon: "folder.badge.plus", title: "Focus Modes", color: .brown)
                FeatureCard(icon: "icloud.fill", title: "Cloud Sync", color: .purple)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Onboarding Screen 3: Get Started
struct OnboardingScreen3: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Ready to Focus?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                .padding(.top, 20)
            
            // Description
            Text("Start your productivity journey today. Create tasks, set focus sessions, and watch your progress grow with our intelligent insights and recommendations.")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .lineLimit(5)
            
            // Beautiful Slider Get Started Button
            SliderGetStartedButton(
                backgroundColor: Color.green,
                onComplete: onComplete
            )
            .padding(.horizontal, 40)
            
            // Additional info
            Text("Swipe to begin your focus journey")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.7))
                .padding(.top, 10)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
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
