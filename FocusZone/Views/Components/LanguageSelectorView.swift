import SwiftUI

/// View for selecting the app language
struct LanguageSelectorView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(localizationManager.availableLanguages) { language in
                        LanguageRowView(
                            language: language,
                            isSelected: language == localizationManager.currentLanguage
                        ) {
                            localizationManager.switchLanguage(to: language)
                            dismiss()
                        }
                    }
                } header: {
                    Text("Select Language")
                        .font(.headline)
                        .foregroundColor(.primary)
                } footer: {
                    Text("The app will restart to apply the language change")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .localized()
        .rtlSupport()
    }
}

/// Individual language row in the selector
struct LanguageRowView: View {
    let language: AppLanguage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Flag emoji
                Text(language.flagEmoji)
                    .font(.title2)
                
                // Language name
                Text(language.displayName)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LanguageSelectorView()
}
