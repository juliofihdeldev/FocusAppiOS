
//
//  FocusZoneApp.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/12/25.
//

import SwiftUI
import SwiftData

@main
struct FocusZoneApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var notificationService = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(themeManager)
                .environmentObject(notificationService)
                .task {
                    // Request notification permission when app launches
                    await requestNotificationPermission()
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
