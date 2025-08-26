import Foundation
import UIKit

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        }
    }
    
    private init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
    func completeOnboarding() {
        hasSeenOnboarding = true
        provideHapticFeedback(.success)
    }
    
    func resetOnboarding() {
        hasSeenOnboarding = false
        provideHapticFeedback(.warning)
    }
    
    private func provideHapticFeedback(_ style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(style)
    }
}
