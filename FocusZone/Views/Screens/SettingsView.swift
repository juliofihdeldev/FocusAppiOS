import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var notificationsEnabled = true
    @State private var smartSuggestionsEnabled = true
    @State private var voiceInputEnabled = true
    @State private var analyticsEnabled = false
    @State private var selectedLanguage = "English"
    @State private var selectedVoice = "System Default"
    @State private var autoSaveEnabled = true
    @State private var showingAbout = false
    @State private var showingPrivacy = false
    @State private var showingSupport = false
    
    private let languages = ["English", "Spanish", "French", "German", "Japanese", "Chinese"]
    private let voices = ["System Default", "Male Voice", "Female Voice", "Neutral Voice"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Settings Sections
                    VStack(spacing: 20) {
                        appearanceSection
                        aiSettingsSection
                        notificationSection
                        dataPrivacySection
                        supportSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top, 20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacySheet()
        }
        .sheet(isPresented: $showingSupport) {
            SupportSheet()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(theme.currentTextColor)
                }
                
                Spacer()
                
                Text("Settings")
                    .font(AppFonts.headline())
                    .foregroundColor(theme.currentTextColor)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundColor(theme.currentTextColor)
                }
            }
            .padding(.horizontal, 20)
            
            // Profile Card
            VStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.accent)
                        .overlay(
                            Circle()
                                .stroke(AppColors.accent.opacity(0.2), lineWidth: 2)
                                .frame(width: 70, height: 70)
                        )
                }
                
                VStack(spacing: 4) {
                    Text("John Doe")
                        .font(AppFonts.headline())
                        .foregroundColor(theme.currentTextColor)
                        .fontWeight(.semibold)
                    
                    Text("Premium Member")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppColors.accent.opacity(0.1))
                        )
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance", icon: "paintbrush") {
            VStack(spacing: 12) {
                SettingsToggleRow(
                    title: "Dark Mode",
                    subtitle: "Switch between light and dark themes",
                    icon: "moon.circle.fill",
                    isOn: $theme.isDarkMode
                )
                
                SettingsNavigationRow(
                    title: "Theme Colors",
                    subtitle: "Customize your accent color",
                    icon: "palette.fill",
                    action: {}
                )
                
                SettingsNavigationRow(
                    title: "Font Size",
                    subtitle: "Adjust text size for better readability",
                    icon: "textformat.size",
                    action: {}
                )
            }
        }
    }
    
    // MARK: - AI Settings Section
    private var aiSettingsSection: some View {
        SettingsSection(title: "AI Assistant", icon: "brain.head.profile") {
            VStack(spacing: 12) {
                SettingsToggleRow(
                    title: "Smart Suggestions",
                    subtitle: "Get contextual suggestions while typing",
                    icon: "lightbulb.circle.fill",
                    isOn: $smartSuggestionsEnabled
                )
                
                SettingsToggleRow(
                    title: "Voice Input",
                    subtitle: "Enable voice commands and dictation",
                    icon: "mic.circle.fill",
                    isOn: $voiceInputEnabled
                )
                
                SettingsPickerRow(
                    title: "Language",
                    subtitle: selectedLanguage,
                    icon: "globe",
                    options: languages,
                    selection: $selectedLanguage
                )
                
                SettingsPickerRow(
                    title: "Voice",
                    subtitle: selectedVoice,
                    icon: "speaker.wave.2.circle.fill",
                    options: voices,
                    selection: $selectedVoice
                )
            }
        }
    }
    
    // MARK: - Notifications Section
    private var notificationSection: some View {
        SettingsSection(title: "Notifications", icon: "bell") {
            VStack(spacing: 12) {
                SettingsToggleRow(
                    title: "Push Notifications",
                    subtitle: "Get notified about important updates",
                    icon: "bell.circle.fill",
                    isOn: $notificationsEnabled
                )
                
                SettingsNavigationRow(
                    title: "Notification Schedule",
                    subtitle: "Set quiet hours and preferences",
                    icon: "clock.circle.fill",
                    action: {}
                )
            }
        }
    }
    
    // MARK: - Data & Privacy Section
    private var dataPrivacySection: some View {
        SettingsSection(title: "Data & Privacy", icon: "lock.shield") {
            VStack(spacing: 12) {
                SettingsToggleRow(
                    title: "Auto-Save Conversations",
                    subtitle: "Automatically save your chat history",
                    icon: "square.and.arrow.down.circle.fill",
                    isOn: $autoSaveEnabled
                )
                
                SettingsToggleRow(
                    title: "Analytics",
                    subtitle: "Help improve the app with usage data",
                    icon: "chart.bar.circle.fill",
                    isOn: $analyticsEnabled
                )
                
                SettingsNavigationRow(
                    title: "Privacy Policy",
                    subtitle: "Learn how we protect your data",
                    icon: "hand.raised.circle.fill",
                    action: { showingPrivacy = true }
                )
                
                SettingsNavigationRow(
                    title: "Export Data",
                    subtitle: "Download your conversations and settings",
                    icon: "square.and.arrow.up.circle.fill",
                    action: {}
                )
            }
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        SettingsSection(title: "Support", icon: "questionmark.circle") {
            VStack(spacing: 12) {
                SettingsNavigationRow(
                    title: "Help Center",
                    subtitle: "Get answers to common questions",
                    icon: "book.circle.fill",
                    action: { showingSupport = true }
                )
                
                SettingsNavigationRow(
                    title: "Contact Us",
                    subtitle: "Send feedback or report issues",
                    icon: "envelope.circle.fill",
                    action: {}
                )
                
                SettingsNavigationRow(
                    title: "Rate the App",
                    subtitle: "Share your experience on the App Store",
                    icon: "star.circle.fill",
                    action: {}
                )
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle") {
            VStack(spacing: 12) {
                SettingsNavigationRow(
                    title: "Version",
                    subtitle: "1.0.0 (Build 123)",
                    icon: "app.badge.checkmark",
                    action: { showingAbout = true }
                )
                
                SettingsNavigationRow(
                    title: "What's New",
                    subtitle: "See the latest features and improvements",
                    icon: "sparkles",
                    action: {}
                )
                
                SettingsNavigationRow(
                    title: "Terms of Service",
                    subtitle: "Read our terms and conditions",
                    icon: "doc.text.circle.fill",
                    action: {}
                )
            }
        }
    }
}

// MARK: - Supporting Views
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    @EnvironmentObject var theme: ThemeManager
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
                
                Text(title)
                    .font(AppFonts.subheadline())
                    .foregroundColor(theme.currentTextColor)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 1) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppColors.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(theme.currentTextColor)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(AppFonts.caption())
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.body())
                        .foregroundColor(theme.currentTextColor)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(AppFonts.caption())
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsPickerRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let options: [String]
    @Binding var selection: String
    @EnvironmentObject var theme: ThemeManager
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: { showingPicker = true }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppColors.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.body())
                        .foregroundColor(theme.currentTextColor)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.accent)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingPicker) {
            PickerSheet(title: title, options: options, selection: $selection)
        }
    }
}

struct PickerSheet: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        NavigationView {
            List(options, id: \.self) { option in
                HStack {
                    Text(option)
                        .font(AppFonts.body())
                        .foregroundColor(theme.currentTextColor)
                    
                    Spacer()
                    
                    if option == selection {
                        Image(systemName: "checkmark")
                            .foregroundColor(AppColors.accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = option
                    dismiss()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.accent)
                        
                        Text("AI Assistant")
                            .font(AppFonts.headline())
                            .foregroundColor(theme.currentTextColor)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(AppFonts.subheadline())
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Made with ❤️ in SwiftUI")
                            .font(AppFonts.body())
                            .foregroundColor(theme.currentTextColor)
                        
                        Text("Your intelligent assistant for productivity and focus. Built to help you manage your time, schedule tasks, and stay organized.")
                            .font(AppFonts.body())
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Privacy Policy content would go here")
                .navigationTitle("Privacy Policy")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct SupportSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Support and help content would go here")
                .navigationTitle("Help Center")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
