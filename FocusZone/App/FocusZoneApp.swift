
//
//  FocusZoneApp.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/12/25.
//

import SwiftUI
import SwiftData
import CloudKit 
@main
struct FocusZoneApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var cloudSyncManager = CloudSyncManager()
    @StateObject private var languageManager = LanguageManager.shared
    // CloudKit-backed SwiftData container
    let modelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration(cloudKitDatabase: .automatic)
            return try ModelContainer(for: Task.self, configurations: configuration)
        } catch {
            fatalError("Failed to create CloudKit-backed ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(themeManager)
                .environmentObject(notificationService)
                .environmentObject(cloudSyncManager)
                .environmentObject(languageManager)
                .task {
                    // Initialize language early to ensure proper localization
                    _ = languageManager.currentLanguage
                    // Request notification permission when app launches
                    await requestNotificationPermission()
                    // Initialize alarm notification handler
                    _ = AlarmNotificationHandler.shared
                }
                .onReceive(NotificationCenter.default.publisher(for: .CKAccountChanged)) { _ in
                    cloudSyncManager.refreshAccountStatus()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Trigger sync when app becomes active
                    _Concurrency.Task {
                        await cloudSyncManager.syncData(modelContext: modelContainer.mainContext)
                    }
                }
                .task {
                    cloudSyncManager.refreshAccountStatus()
                    // Initial sync when app launches
                    await cloudSyncManager.syncData(modelContext: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
    
    private func requestNotificationPermission() async {
            let granted = await notificationService.requestAuthorization()
            if granted {
                print("FocusZoneApp: Notification permission granted")
            } else {
                print("FocusZoneApp: Notification permission denied")
            }
            
            // Also request AlarmKit authorization
            let alarmService = AlarmService.shared
            let alarmGranted = await alarmService.requestAuthorization()
            if alarmGranted {
                print("FocusZoneApp: AlarmKit permission granted")
            } else {
                print("FocusZoneApp: AlarmKit permission denied")
            }
        }
}
