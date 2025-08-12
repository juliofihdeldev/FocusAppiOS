import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var notificationsEnabled = true
    @State private var showingAbout = false
    @State private var enableFocusMode = true
    @State private var showPaywall = false
    @State private var showLanguageSelector = false
    @StateObject private var focusManager = FocusModeManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Header
                    appHeader
                    
                    // Settings Sections
                    VStack(spacing: 20) {
                        subscriptionSection
                        appearanceSection
                        languageSection
                        notificationSection
                        dataSection
                        focusSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top, 20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .onChange(of: theme.currentBackground) { newValue in
            // TODO Store preference
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showLanguageSelector) {
            LanguageSelectorView()
        }
        .localized()
        .rtlSupport()
    }
    
    // MARK: - App Header
    private var appHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                
                Text(LocalizationKeys.settings.localized)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // App Icon and Info
            VStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(AppColors.accent.opacity(0.1))
                    )
                
                VStack(spacing: 4) {
                    Text(LocalizationKeys.focus.localized)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text(LocalizationKeys.stayFocusedAchieveMore.localized)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondary)
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.card)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            // Subscription status card
            SubscriptionStatusView()
            
            if !subscriptionManager.isProUser {
                // Upgrade prompt for free users
                Button(action: {
                    showPaywall = true
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizationKeys.upgradeToPro.localized)
                                .font(AppFonts.headline())
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(LocalizationKeys.unlockAllFeatures.localized)
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.accent)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.orange.opacity(0.1),
                                    Color.red.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange.opacity(0.3),
                                            Color.red.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ), lineWidth: 1)
                            )
                    )
                }
            } else {
                // Pro user management options
                SettingsSection(title: LocalizationKeys.subscription.localized, icon: "crown.fill") {
                    VStack(spacing: 0) {
                        Button(action: {
                            _Concurrency.Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(AppColors.accent)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LocalizationKeys.restorePurchases.localized)
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(LocalizationKeys.restoreSubscriptionDevice.localized)
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        
                        Divider()
                            .padding(.leading, 52)
                        
                        Button(action: {
                            // TODO: Open subscription management in App Store
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "gear.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(AppColors.accent)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LocalizationKeys.manageSubscription.localized)
                                        .font(AppFonts.body())
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(LocalizationKeys.changeCancelSubscription.localized)
                                        .font(AppFonts.caption())
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        SettingsSection(title: LocalizationKeys.appearance.localized, icon: "paintbrush") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: LocalizationKeys.darkMode.localized,
                    subtitle: LocalizationKeys.switchLightDarkThemes.localized,
                    icon: "moon.circle.fill",
                    isOn: $theme.isDarkMode
                )
            }
        }
    }
    
    // MARK: - Language Section
    private var languageSection: some View {
        SettingsSection(title: LocalizationKeys.language.localized, icon: "globe") {
            VStack(spacing: 0) {
                LanguageSettingsRow(
                    localizationManager: localizationManager,
                    action: { showLanguageSelector = true }
                )
            }
        }
    }
    
    // Focus  Section
    private var focusSection: some View {
        SettingsSection(title: LocalizationKeys.focus.localized, icon: "target") {
            VStack(spacing: 0) {
                
                SettingsToggleRow(
                    title: LocalizationKeys.focusConcentration.localized,
                    subtitle: LocalizationKeys.getNotifiedTasksStarting.localized,
                    icon: "bell.circle.fill",
                    isOn: $enableFocusMode
                )
                
            }
            
        }
    }
    
    // MARK: - Notifications Section
    private var notificationSection: some View {
        SettingsSection(title: LocalizationKeys.notifications.localized, icon: "bell") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: LocalizationKeys.taskReminders.localized,
                    subtitle: LocalizationKeys.getNotifiedTasksStarting.localized,
                    icon: "bell.circle.fill",
                    isOn: $notificationsEnabled
                )
            }
        }
        
        
    }
    
    // MARK: - Data Section
    private var dataSection: some View {
        SettingsSection(title: LocalizationKeys.data.localized, icon: "internaldrive") {
            VStack(spacing: 0) {
     
                
                SettingsNavigationRow(
                    title: LocalizationKeys.clearAllData.localized,
                    subtitle: LocalizationKeys.resetAllTasksSettings.localized,
                    icon: "trash.circle.fill",
                    isDestructive: true,
                    action: { clearAllData() }
                )
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSection(title: LocalizationKeys.about.localized, icon: "info.circle") {
            VStack(spacing: 0) {
                SettingsNavigationRow(
                    title: LocalizationKeys.version.localized,
                    subtitle: "1.0.0",
                    icon: "app.badge.checkmark",
                    action: { showingAbout = true }
                )
                
                
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsNavigationRow(
                    title: LocalizationKeys.contactSupport.localized,
                    subtitle: LocalizationKeys.getHelpSendFeedback.localized,
                    icon: "envelope.circle.fill",
                    action: { contactSupport() }
                )
            }
        }
    }
    
    // MARK: - Actions
    private func clearAllData() {
        // TODO: Implement clear data functionality
        print("Clear all data requested")
    }
    
    private func contactSupport() {
        // TODO: Implement contact support functionality
        print("Contact support requested")
    }
}

// MARK: - Supporting Views
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                //                Image(systemName: icon)
                //                    .font(.system(size: 18))
                //                    .foregroundColor(AppColors.accent)
                
                //                Text(title)
                //                    .font(AppFonts.headline())
                //                    .foregroundColor(AppColors.textPrimary)
                //                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.card)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let subtitle: String
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? .red : AppColors.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.body())
                        .foregroundColor(isDestructive ? .red : AppColors.textPrimary)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .onChange(of: isDestructive) { newValue in
          
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.accent)
                        
                        Text(LocalizationKeys.focus.localized)
                            .font(AppFonts.title())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.bold)
                        
                       Text("Version 1.0.0")
                           .font(AppFonts.body())
                           .foregroundColor(AppColors.secondary)
                        

                       Text(LocalizationKeys.focus.localized)
                           .font(AppFonts.title())
                           .foregroundColor(AppColors.textPrimary)
                           .fontWeight(.bold)
                        
                    }
                    
                    
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizationKeys.builtWithSwiftUI.localized)
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(LocalizationKeys.focusHelpsStayFocused.localized)
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.secondary)
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
            .navigationTitle(LocalizationKeys.about.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKeys.done.localized) {
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
