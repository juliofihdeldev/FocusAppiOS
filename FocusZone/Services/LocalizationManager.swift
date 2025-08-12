import Foundation
import SwiftUI

/// Manages app localization and language switching
@MainActor
class LocalizationManager: ObservableObject {
    
    /// Shared instance for app-wide access
    static let shared = LocalizationManager()
    
    /// Currently selected language
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
            updateLocale()
        }
    }
    
    /// Current locale for the app
    @Published var currentLocale: Locale
    
    /// Available languages
    let availableLanguages: [AppLanguage] = [
        .english,
        .french,
        .spanish
    ]
    
    private init() {
        // Load saved language or default to system language
        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage")
        let initialLanguage: AppLanguage
        if let savedLanguage = savedLanguage, let language = AppLanguage(rawValue: savedLanguage) {
            initialLanguage = language
        } else {
            // Default to system language or English
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            initialLanguage = AppLanguage(rawValue: systemLanguage) ?? .english
        }
        
        self.currentLanguage = initialLanguage
        self.currentLocale = Locale(identifier: initialLanguage.localeIdentifier)
        updateLocale()
    }
    
    /// Updates the app locale and triggers UI refresh
    private func updateLocale() {
        currentLocale = Locale(identifier: currentLanguage.localeIdentifier)
        
        // Post notification to refresh UI
        NotificationCenter.default.post(name: .localeDidChange, object: nil)
        
        // Update bundle for localization
        Bundle.setLanguage(currentLanguage.rawValue)
    }
    
    /// Switches to a different language
    func switchLanguage(to language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language
    }
    
    /// Gets the localized string for a key
    func localizedString(for key: String) -> String {
        return NSLocalizedString(key, bundle: Bundle.main, comment: "")
    }
    
    /// Gets the localized string with format arguments
    func localizedString(for key: String, with arguments: CVarArg...) -> String {
        let format = localizedString(for: key)
        return String(format: format, arguments: arguments)
    }
    
    /// Gets the localized string with a single argument
    func localizedString(for key: String, with argument: CVarArg) -> String {
        let format = localizedString(for: key)
        return String(format: format, argument)
    }
    
    /// Gets the display name for a language
    func displayName(for language: AppLanguage) -> String {
        return language.displayName
    }
    
    /// Gets the flag emoji for a language
    func flagEmoji(for language: AppLanguage) -> String {
        return language.flagEmoji
    }
    
    /// Checks if the current language is RTL (Right-to-Left)
    var isRTL: Bool {
        return currentLanguage.isRTL
    }
    
    /// Gets the text alignment for the current language
    var textAlignment: TextAlignment {
        return isRTL ? .trailing : .leading
    }
}

// MARK: - App Language Enum
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case french = "fr"
    case spanish = "es"
    
    var id: String { rawValue }
    
    /// Locale identifier for the language
    var localeIdentifier: String {
        switch self {
        case .english:
            return "en_US"
        case .french:
            return "fr_FR"
        case .spanish:
            return "es_ES"
        }
    }
    
    /// Display name in the language itself
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .french:
            return "Français"
        case .spanish:
            return "Español"
        }
    }
    
    /// Flag emoji for the language
    var flagEmoji: String {
        switch self {
        case .english:
            return "🇺🇸"
        case .french:
            return "🇫🇷"
        case .spanish:
            return "🇪🇸"
        }
    }
    
    /// Whether the language is RTL (Right-to-Left)
    var isRTL: Bool {
        return false // None of our supported languages are RTL
    }
}

// MARK: - Bundle Extension for Language Switching
extension Bundle {
    private static var bundle: Bundle?
    
    static func localizedBundle() -> Bundle! {
        if bundle == nil {
            bundle = Bundle.main
        }
        return bundle
    }
    
    static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, Bundle.self)
        }
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else {
            bundle = Bundle.main
            return
        }
        
        bundle = Bundle(path: path)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let localeDidChange = Notification.Name("localeDidChange")
}

// MARK: - View Extension for Localization
extension View {
    /// Applies the current locale to the view
    func localized() -> some View {
        let locale = LocalizationManager.shared.currentLocale
        return self.environment(\.locale, locale)
    }
    
    /// Applies RTL support for the current language
    func rtlSupport() -> some View {
        let isRTL = LocalizationManager.shared.isRTL
        return self.environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
    }
}
