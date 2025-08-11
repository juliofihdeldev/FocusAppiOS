# FocusZone App Localization System

## Overview

This document describes the localization system implemented for the FocusZone iOS app, supporting English, French, and Spanish languages.

## Supported Languages

- 🇺🇸 **English** (en) - Default language
- 🇫🇷 **French** (fr) - Français
- 🇪🇸 **Spanish** (es) - Español

## Project Structure

```
FocusZone/
├── Resources/
│   ├── en.lproj/
│   │   └── Localizable.strings    # English strings
│   ├── fr.lproj/
│   │   └── Localizable.strings    # French strings
│   ├── es.lproj/
│   │   └── Localizable.strings    # Spanish strings
│   └── Localizable.strings        # Base strings file
├── Helpers/Extensions/
│   └── String+Localization.swift  # String extension for localization
├── Services/
│   └── LocalizationManager.swift  # Language management service
└── Views/Components/
    └── LanguageSelectorView.swift # Language selection UI
```

## Key Components

### 1. LocalizationManager

The central service that manages language switching and provides localized content.

```swift
// Access the shared instance
let localizationManager = LocalizationManager.shared

// Switch languages
localizationManager.switchLanguage(to: .french)

// Get localized strings
let text = localizationManager.localizedString(for: "create_task")
let formattedText = localizationManager.localizedString(for: "percentage_complete", with: 75)
```

### 2. String Extension

Provides convenient methods for string localization throughout the app.

```swift
// Basic localization
let text = "create_task".localized

// With format arguments
let text = "percentage_complete".localized(with: 75)
let text = "suggested_focus_mode".localized(with: "Deep Work", "coding")
```

### 3. LocalizationKeys

Centralized constants for all localization keys to prevent typos.

```swift
// Use predefined keys
let text = LocalizationKeys.createTask.localized
let text = LocalizationKeys.percentageComplete.localized(with: 75)
```

## Usage Examples

### In SwiftUI Views

```swift
struct TaskFormView: View {
    var body: some View {
        VStack {
            Text(LocalizationKeys.createTask.localized)
                .font(.title)
            
            Text(LocalizationKeys.suggestedFocusMode.localized(
                with: focusMode.displayName,
                taskType?.displayName ?? "this task"
            ))
        }
        .localized()      // Apply current locale
        .rtlSupport()     // Apply RTL if needed
    }
}
```

### In ViewModels

```swift
class TaskViewModel: ObservableObject {
    func getTaskStatusText() -> String {
        if task.isCompleted {
            return LocalizationKeys.allDone.localized
        } else {
            return LocalizationKeys.timeRemaining.localized
        }
    }
}
```

### In Services

```swift
class NotificationService {
    func showTaskReminder() {
        let title = LocalizationKeys.focus.localized
        let message = LocalizationKeys.timeUp.localized
        
        // Show notification with localized text
    }
}
```

## Adding New Localized Strings

### 1. Add to English Strings File

```strings
// FocusZone/Resources/en.lproj/Localizable.strings
"new_feature_title" = "New Feature";
"welcome_message" = "Welcome to %@!";
```

### 2. Add to French Strings File

```strings
// FocusZone/Resources/fr.lproj/Localizable.strings
"new_feature_title" = "Nouvelle fonctionnalité";
"welcome_message" = "Bienvenue dans %@ !";
```

### 3. Add to Spanish Strings File

```strings
// FocusZone/Resources/es.lproj/Localizable.strings
"new_feature_title" = "Nueva función";
"welcome_message" = "¡Bienvenido a %@!";
```

### 4. Add to LocalizationKeys

```swift
// FocusZone/Helpers/Extensions/String+Localization.swift
struct LocalizationKeys {
    // ... existing keys ...
    static let newFeatureTitle = "new_feature_title"
    static let welcomeMessage = "welcome_message"
}
```

### 5. Use in Code

```swift
let title = LocalizationKeys.newFeatureTitle.localized
let message = LocalizationKeys.welcomeMessage.localized(with: "FocusZone")
```

## Language Switching

### Programmatic Language Change

```swift
// Switch to French
LocalizationManager.shared.switchLanguage(to: .french)

// Switch to Spanish
LocalizationManager.shared.switchLanguage(to: .spanish)

// Switch back to English
LocalizationManager.shared.switchLanguage(to: .english)
```

### User Interface

The `LanguageSelectorView` provides a user-friendly interface for language selection:

```swift
struct SettingsView: View {
    @State private var showLanguageSelector = false
    
    var body: some View {
        Button("Change Language") {
            showLanguageSelector = true
        }
        .sheet(isPresented: $showLanguageSelector) {
            LanguageSelectorView()
        }
    }
}
```

## Best Practices

### 1. Always Use LocalizationKeys

❌ **Don't do this:**
```swift
let text = "create_task".localized
```

✅ **Do this instead:**
```swift
let text = LocalizationKeys.createTask.localized
```

### 2. Handle Format Arguments Properly

❌ **Don't do this:**
```swift
let text = "Welcome \(userName)".localized
```

✅ **Do this instead:**
```swift
let text = LocalizationKeys.welcomeMessage.localized(with: userName)
```

### 3. Apply Localization to Views

```swift
struct MyView: View {
    var body: some View {
        VStack {
            // Your view content
        }
        .localized()      // Apply current locale
        .rtlSupport()     // Apply RTL if needed
    }
}
```

### 4. Test All Languages

Always test your app in all supported languages to ensure:
- Text fits properly in UI elements
- No text is cut off
- Format arguments work correctly
- Cultural considerations are respected

## Testing Localization

### 1. Simulator Testing

1. Run the app in simulator
2. Go to Settings > General > Language & Region
3. Add your target language
4. Set it as primary language
5. Restart the app

### 2. Code Testing

```swift
// Test different languages programmatically
LocalizationManager.shared.switchLanguage(to: .french)
// Verify UI updates

LocalizationManager.shared.switchLanguage(to: .spanish)
// Verify UI updates
```

### 3. String Validation

Use Xcode's built-in localization validation:
1. Select your project in Xcode
2. Go to Product > Analyze
3. Check for missing localizations

## Troubleshooting

### Common Issues

1. **Strings not localizing**: Ensure the key exists in all `.lproj` folders
2. **Format arguments not working**: Check that `%@` placeholders match the number of arguments
3. **Language not switching**: Verify the language switching code is called on the main thread
4. **Missing translations**: Use Xcode's localization validation tools

### Debug Information

```swift
// Get current language info
let currentLang = LocalizationManager.shared.currentLanguage
print("Current language: \(currentLang.displayName)")

// Get available languages
let available = LocalizationManager.shared.availableLanguages
print("Available languages: \(available.map { $0.displayName })")
```

## Future Enhancements

- [ ] Add more languages (German, Italian, Portuguese, etc.)
- [ ] Implement dynamic language switching without app restart
- [ ] Add language-specific date/time formatting
- [ ] Support for RTL languages (Arabic, Hebrew)
- [ ] Localized app store metadata
- [ ] A/B testing for different language versions

## Contributing

When adding new features or modifying existing ones:

1. **Always localize new user-facing strings**
2. **Test in all supported languages**
3. **Follow the established naming conventions**
4. **Update this documentation**
5. **Consider cultural differences and local preferences**

## Resources

- [Apple Localization Guide](https://developer.apple.com/documentation/xcode/localization)
- [SwiftUI Localization](https://developer.apple.com/documentation/swiftui/environmentvalues/locale)
- [NSLocalizedString Documentation](https://developer.apple.com/documentation/foundation/nslocalizedstring)
