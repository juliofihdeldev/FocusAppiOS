import SwiftUI
import UserNotifications

struct PermissionCheckerView: View {
    @StateObject private var alarmService = AlarmService.shared
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingSettings = false
    @State private var debugInfo: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Permission Checker")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Diagnose and fix permission issues")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Permission Status Cards
                    VStack(spacing: 12) {
                        PermissionCard(
                            title: "Notification Permissions",
                            status: notificationStatusText,
                            color: notificationStatusColor,
                            action: "Check Status"
                        ) {
                            checkNotificationPermissions()
                        }
                        
                        PermissionCard(
                            title: "AlarmKit Support",
                            status: alarmService.isAlarmKitSupported ? "✅ Supported" : "❌ Not Supported",
                            color: alarmService.isAlarmKitSupported ? .green : .red,
                            action: "Check Support"
                        ) {
                            checkAlarmKitSupport()
                        }
                        
                        PermissionCard(
                            title: "AlarmKit Authorization",
                            status: alarmService.isAuthorized ? "✅ Authorized" : "❌ Not Authorized",
                            color: alarmService.isAuthorized ? .green : .red,
                            action: "Request Permission"
                        ) {
                            requestAlarmKitPermission()
                        }
                    }
                    
                    // Debug Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Debug Information")
                            .font(.headline)
                        
                        ScrollView {
                            Text(debugInfo.isEmpty ? "Tap 'Check All Permissions' to see debug info" : debugInfo)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            checkAllPermissions()
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Check All Permissions")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            requestAllPermissions()
                        }) {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("Request All Permissions")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            openSettings()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open iOS Settings")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            testNotification()
                        }) {
                            HStack {
                                Image(systemName: "bell.fill")
                                Text("Test Notification")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            debugAlarmKitSupport()
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass.circle")
                                Text("Debug AlarmKit")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Permission Checker")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkNotificationPermissions()
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Debug Info"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var notificationStatusText: String {
        switch notificationStatus {
        case .authorized:
            return "✅ Authorized"
        case .denied:
            return "❌ Denied"
        case .notDetermined:
            return "⚠️ Not Determined"
        case .provisional:
            return "⚠️ Provisional"
        case .ephemeral:
            return "⚠️ Ephemeral"
        @unknown default:
            return "❓ Unknown"
        }
    }
    
    private var notificationStatusColor: Color {
        switch notificationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined, .provisional, .ephemeral:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
                self.debugInfo += "📱 Notification Status: \(settings.authorizationStatus.rawValue)\n"
                self.debugInfo += "📱 Alert Setting: \(settings.alertSetting.rawValue)\n"
                self.debugInfo += "📱 Sound Setting: \(settings.soundSetting.rawValue)\n"
                self.debugInfo += "📱 Badge Setting: \(settings.badgeSetting.rawValue)\n"
                self.debugInfo += "---\n"
            }
        }
    }
    
    private func checkAlarmKitSupport() {
        debugInfo += "🔔 AlarmKit Support: \(alarmService.isAlarmKitSupported)\n"
        debugInfo += "🔔 iOS Version: \(UIDevice.current.systemVersion)\n"
        debugInfo += "---\n"
    }
    
    private func requestAlarmKitPermission() {
        _Concurrency.Task {
            let granted = await alarmService.requestAuthorization()
            await MainActor.run {
                debugInfo += "🔔 AlarmKit Permission Request: \(granted ? "Granted" : "Denied")\n"
                debugInfo += "---\n"
            }
        }
    }
    
    private func checkAllPermissions() {
        debugInfo = "🔍 Checking all permissions...\n\n"
        
        _Concurrency.Task {
            let result = await alarmService.checkAllPermissions()
            
            await MainActor.run {
                self.debugInfo = result.debugInfo
                self.notificationStatus = result.notifications ? .authorized : .denied
            }
        }
    }
    
    private func requestAllPermissions() {
        debugInfo += "🔑 Requesting all permissions...\n"
        
        _Concurrency.Task {
            let result = await alarmService.requestAllPermissions()
            
            await MainActor.run {
                self.debugInfo += "📱 Notification Permission: \(result.notifications ? "Granted" : "Denied")\n"
                self.debugInfo += "🔔 AlarmKit Permission: \(result.alarmKit ? "Granted" : "Denied")\n"
                self.debugInfo += "---\n"
                self.notificationStatus = result.notifications ? .authorized : .denied
            }
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func debugAlarmKitSupport() {
        let debugInfo = alarmService.debugAlarmKitSupport()
        self.debugInfo = debugInfo
        showingAlert = true
        alertMessage = "Check console for detailed AlarmKit debug information"
        
        // Also print to console
        print(debugInfo)
    }
    
    private func testNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "This is a test notification from FocusZone"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.debugInfo += "🧪 Test Notification Error: \(error.localizedDescription)\n"
                } else {
                    self.debugInfo += "🧪 Test Notification Scheduled Successfully\n"
                }
                self.debugInfo += "---\n"
            }
        }
    }
}

struct PermissionCard: View {
    let title: String
    let status: String
    let color: Color
    let action: String
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Button(action: onTap) {
                Text(action)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PermissionCheckerView()
}
