import SwiftUI

struct MainAppView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    
    var body: some View {
        Group {
            if onboardingManager.hasSeenOnboarding {
                SplashScreen()
            } else {
                OnboardingView()
            }
        }
    }
}

#Preview {
    MainAppView()
}
