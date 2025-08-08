
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

    // TODO: Switch to CloudKit-backed ModelContainer when available in your toolchain.
    // For now, we keep the default local container to keep builds green.

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(themeManager)
                .environmentObject(notificationService)
                .environmentObject(cloudSyncManager)
                .task {
                    // Request notification permission when app launches
                    await requestNotificationPermission()
                }
                .onReceive(NotificationCenter.default.publisher(for: .CKAccountChanged)) { _ in
                    cloudSyncManager.refreshAccountStatus()
                }
                .task {
                    cloudSyncManager.refreshAccountStatus()
                }
        }
        .modelContainer(for: Task.self)
    }
    
    private func requestNotificationPermission() async {
            let granted = await notificationService.requestAuthorization()
            if granted {
                print("FocusZoneApp: Notification permission granted")
            } else {
                print("FocusZoneApp: Notification permission denied")
            }
        }
}
