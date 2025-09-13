import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            setLanguagePreference()
            
            // Post notification to restart app for language change
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    let supportedLanguages = [
        ("en", "English", "🇺🇸"),
        ("fr", "Français", "🇫🇷"),
        ("pt-PT", "Português", "🇵🇹"),
        ("it", "Italiano", "🇮🇹"),
        ("ja", "日本語", "🇯🇵")
    ]
    
    private init() {
        // Get saved language or default to English
        if let savedLanguage = UserDefaults.standard.string(forKey: "selected_language") {
            self.currentLanguage = savedLanguage
        } else {
            // Always default to English for new installations
            self.currentLanguage = "en"
        }
        
        // Immediately set the language preference to ensure proper localization
        setLanguagePreference()
    }
    
    private func setLanguagePreference() {
        UserDefaults.standard.set(currentLanguage, forKey: "selected_language")
        UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    func getLanguageDisplayName(for code: String) -> String {
        return supportedLanguages.first { $0.0 == code }?.1 ?? code
    }
    
    func getLanguageFlag(for code: String) -> String {
        return supportedLanguages.first { $0.0 == code }?.2 ?? "🌐"
    }
    
    func getCurrentLanguageDisplayName() -> String {
        return getLanguageDisplayName(for: currentLanguage)
    }
    
    func getCurrentLanguageFlag() -> String {
        return getLanguageFlag(for: currentLanguage)
    }
    
    func resetToEnglish() {
        currentLanguage = "en"
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
