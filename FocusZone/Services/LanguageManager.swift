import Foundation
import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selected_language")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            
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
        // Get saved language or use system language
        if let savedLanguage = UserDefaults.standard.string(forKey: "selected_language") {
            self.currentLanguage = savedLanguage
        } else {
            // Use system language if supported, otherwise default to English
            let systemLanguage = Locale.current.languageCode ?? "en"
            let supportedCodes = supportedLanguages.map { $0.0 }
            self.currentLanguage = supportedCodes.contains(systemLanguage) ? systemLanguage : "en"
        }
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
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
