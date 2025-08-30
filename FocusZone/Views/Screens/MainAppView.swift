import SwiftUI

struct MainAppView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some View {
        Group {
            if hasSeenOnboarding {
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
