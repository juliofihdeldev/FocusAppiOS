import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @State private var notificationsEnabled = true
    @State private var showingAbout = false
    @State private var showingContact = false
    @State private var enableFocusMode = true
    @State private var showPaywall = false
    @State private var showLanguageSelector = false
    @State private var showingClearDataConfirmation = false
    @State private var showingClearDataAlert = false
    @State private var clearDataMessage = ""
    @StateObject private var focusManager = FocusModeManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var cloudSyncManager = CloudSyncManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Header
                    appHeader
                    
                    // Settings Sections
                    VStack(spacing: 20) {
                        subscriptionSection
//                     TODO:   appearanceSection
//                     TODO:   languageSection
                        notificationSection
                        dataSection
                        focusSection
                        aboutSection
                        cloudKitSyncSection
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
        .sheet(isPresented: $showingContact) {
            ContactSheet()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showLanguageSelector) {
            LanguageSelectorView()
        }
        .confirmationDialog(
            "Clear All Data",
            isPresented: $showingClearDataConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Data", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all tasks, settings, and app data. This action cannot be undone.")
        }
        .alert("Data Cleared", isPresented: $showingClearDataAlert) {
            Button("OK") { }
        } message: {
            Text(clearDataMessage)
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
                    action: { showingClearDataConfirmation = true }
                )
            }
        }
    }
    
    // MARK: - CloudKit Sync Section
    private var cloudKitSyncSection: some View {
        SettingsSection(title: "iCloud Sync", icon: "icloud") {
            CloudKitSyncStatusView(cloudSyncManager: cloudSyncManager)
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        SettingsSection(title: LocalizationKeys.about.localized, icon: "info.circle") {
            VStack(spacing: 0) {
                SettingsNavigationRow(
                    title: "Abous Us",
                    subtitle: "Version 1.0",
                    icon: "app.badge.checkmark",
                    action: { showingAbout = true }
                )
                
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsNavigationRow(
                    title: LocalizationKeys.contactSupport.localized,
                    subtitle: LocalizationKeys.getHelpSendFeedback.localized,
                    icon: "envelope.circle.fill",
                    action: { showingContact = true }
                )
            }
        }
    }
    
    private func clearAllData() {
        _Concurrency.Task {
            do {
                // Clear SwiftData - Delete all tasks
                let taskDescriptor = FetchDescriptor<Task>()
                let allTasks = try modelContext.fetch(taskDescriptor)
                
                for task in allTasks {
                    modelContext.delete(task)
                }
                
                // Save the context to persist deletions
                try modelContext.save()
                
                // Clear UserDefaults data
                let defaults = UserDefaults.standard
                let domain = Bundle.main.bundleIdentifier!
                defaults.removePersistentDomain(forName: domain)
                
                // Clear specific UserDefaults keys that might not be in the domain
                let keysToRemove = [
                    "active_focus_session",
                    "focus_session_history",
                    "focus_mode_preferences",
                    "notification_preferences",
                    "theme_preferences",
                    "last_analytics_date",
                    "user_preferences"
                ]
                
                for key in keysToRemove {
                    defaults.removeObject(forKey: key)
                }
                
                // Clear all pending notifications
                await UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                await UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                
                // Clear analytics data
                focusManager.clearFocusSessionHistory()
                
                // Reset local state variables
                await MainActor.run {
                    notificationsEnabled = true
                    enableFocusMode = true
                    theme.resetToDefaults()
                    
                    clearDataMessage = "All data has been successfully cleared. The app will now restart to apply changes."
                    showingClearDataAlert = true
                }
                
                // Restart the app after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    exit(0)
                }
                
            } catch {
                await MainActor.run {
                    clearDataMessage = "Error clearing data: \(error.localizedDescription)"
                    showingClearDataAlert = true
                }
            }
        }
    }
    
    private func contactSupport() {
        // TODO: Implement contact support functionality
        print("Contact support requested")
    }
}

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
                    // App Header
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
                    }
                    
                    // About Us Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About FocusZen+")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        Text("FocusZen+ is your personal productivity companion designed to help you stay focused, manage tasks efficiently, and achieve your goals through intelligent time management and distraction-free work sessions.")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Mission Statement
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Our Mission")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        Text("To empower individuals to take control of their time, eliminate distractions, and create meaningful progress in their personal and professional lives through focused work sessions and intelligent task management.")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Key Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            _FeatureRow(icon: "target", title: "Focus Sessions", description: "Dedicated time blocks for deep work")
                            _FeatureRow(icon: "brain.head.profile", title: "AI-Powered Insights", description: "Smart suggestions for better productivity")
                            _FeatureRow(icon: "bell.badge", title: "Smart Notifications", description: "Intelligent reminders that don't interrupt")
                            _FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Progress Tracking", description: "Visual insights into your productivity")
                            _FeatureRow(icon: "gear", title: "Customizable Focus Modes", description: "Tailored settings for different work types")
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Technology Stack
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Built With")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• SwiftUI & iOS 15+")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                            Text("• Core Data for persistence")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                            Text("• WidgetKit for home screen widgets")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                            Text("• Localization for global users")
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Contact & Support
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Get in Touch")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Button(action: {
                                if let url = URL(string: "mailto:support@focuszenplus.app") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(AppColors.accent)
                                    Text("support@focuszenplus.app")
                                        .foregroundColor(AppColors.accent)
                                    Spacer()
                                }
                            }
                            
                            Button(action: {
                                if let url = URL(string: "https://focuszenplus.app") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "globe")
                                        .foregroundColor(AppColors.accent)
                                    Text("focuszenplus.app")
                                        .foregroundColor(AppColors.accent)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Copyright
                    VStack(spacing: 8) {
                        Text("© 2024 FocusZen+")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Made with ❤️ for productivity")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 16)
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

struct _FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.accent)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct ContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Contact Header
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.accent)
                        
                        Text("Contact & Support")
                            .font(AppFonts.title())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.bold)
                        
                        Text("We're here to help! Get in touch with our support team or send us feedback.")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.top, 20)
                    
                    // Support Options
                    VStack(spacing: 16) {
                        Text("Support Options")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ContactOptionRow(
                                icon: "envelope.fill",
                                title: "Email Support",
                                subtitle: "Get help via email",
                                action: {
                                    if let url = URL(string: "mailto:support@focuszenplus.app") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            ContactOptionRow(
                                icon: "globe",
                                title: "Website",
                                subtitle: "Visit our website for help",
                                action: {
                                    if let url = URL(string: "https://focuszenplus.app") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            ContactOptionRow(
                                icon: "questionmark.circle.fill",
                                title: "FAQ & Help Center",
                                subtitle: "Find answers to common questions",
                                action: {
                                    if let url = URL(string: "https://focuszenplus.app/help") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Feedback Section
                    VStack(spacing: 16) {
                        Text("Send Feedback")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ContactOptionRow(
                                icon: "star.fill",
                                title: "Rate the App",
                                subtitle: "Share your experience on the App Store",
                                action: {
                                    rateApp()
                                }
                            )
                            
                            ContactOptionRow(
                                icon: "paperplane.fill",
                                title: "Feature Request",
                                subtitle: "Suggest new features or improvements",
                                action: {
                                    if let url = URL(string: "mailto:feedback@focuszenplus.app?subject=Feature%20Request") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            ContactOptionRow(
                                icon: "exclamationmark.triangle.fill",
                                title: "Report Bug",
                                subtitle: "Help us fix issues you encounter",
                                action: {
                                    if let url = URL(string: "mailto:bugs@focuszenplus.app?subject=Bug%20Report") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.card)
                    )
                    
                    // Response Time
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.accent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Response Time")
                                    .font(AppFonts.body())
                                    .foregroundColor(AppColors.textPrimary)
                                    .fontWeight(.medium)
                                
                                Text("We typically respond within 24 hours during business days")
                                    .font(AppFonts.caption())
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.card)
                        )
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Contact & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func rateApp() {
        // Get the app's bundle identifier
        let bundleId = Bundle.main.bundleIdentifier ?? "ios.focus.jf.com.Focus"
        
        // Create the App Store URL for rating
        let appStoreURL = "https://apps.apple.com/app/id[APP_ID]?action=write-review"
        
        // Alternative: Use the app's name to search (more reliable)
        let searchURL = "https://apps.apple.com/search?term=FocusZen%2B&media=software"
        
        // Try to open the App Store rating page
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback to search page if rating page fails
                    if let searchURL = URL(string: searchURL) {
                        UIApplication.shared.open(searchURL)
                    }
                }
            }
        } else {
            // Fallback to search page
            if let searchURL = URL(string: searchURL) {
                UIApplication.shared.open(searchURL)
            }
        }
    }
}

struct ContactOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.background)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
