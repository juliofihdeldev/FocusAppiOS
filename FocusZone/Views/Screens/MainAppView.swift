import SwiftUI

struct MainAppView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @EnvironmentObject var languageManager: LanguageManager
    
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
        .environmentObject(LanguageManager.shared)
}
