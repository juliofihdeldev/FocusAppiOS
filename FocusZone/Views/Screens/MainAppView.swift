import SwiftUI

struct MainAppView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some View {
        // Temporarily show TestTranslationView for debugging
        TestTranslationView()
        
        // Original code (commented out for now):
        // Group {
        //     if hasSeenOnboarding {
        //         SplashScreen()
        //     } else {
        //         OnboardingView()
        //     }
        // }
    }
}

#Preview {
    MainAppView()
}
