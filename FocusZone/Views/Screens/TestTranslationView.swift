import SwiftUI

struct TestTranslationView: View {
    @State private var selectedLanguage: AppLanguage = .english
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Language Selector
                Picker("Language", selection: $selectedLanguage) {
                    Text("English").tag(AppLanguage.english)
                    Text("Français").tag(AppLanguage.french)
                    Text("Español").tag(AppLanguage.spanish)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .onChange(of: selectedLanguage) { newLanguage in
                    LocalizationManager.shared.switchLanguage(to: newLanguage)
                }
                
                Spacer()
                
                // Welcome Message
                VStack(spacing: 20) {
                    Image(systemName: "globe")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text(LocalizationKeys.welcomeMessage.localized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Text(LocalizationKeys.welcomeDescription.localized)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .lineLimit(4)
                }
                
                Spacer()
                
                // Test Buttons
                VStack(spacing: 15) {
                    Button(LocalizationKeys.testButtonHello.localized) {
                        // Test button action
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    Button(LocalizationKeys.testButtonGoodbye.localized) {
                        // Test button action
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.green)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Current Language Display
                Text("Current Language: \(selectedLanguage.displayName)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .navigationTitle("Test Translation")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            // Set initial language
            LocalizationManager.shared.switchLanguage(to: selectedLanguage)
        }
    }
}

#Preview {
    TestTranslationView()
}
