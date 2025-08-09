
//
//  FocusZoneApp.swift
//  FocusZone
//
//  Created by Julio J Fils on 7/12/25.
//

import SwiftUI
import SwiftData
import CloudKit
import RevenueCat
import Foundation

@main
struct FocusZoneApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var cloudSyncManager = CloudSyncManager()
    // CloudKit-backed SwiftData container
    let modelContainer: ModelContainer = {
        do {
            let configuration = ModelConfiguration(cloudKitDatabase: .automatic)
            return try ModelContainer(for: Task.self, configurations: configuration)
        } catch {
            fatalError("Failed to create CloudKit-backed ModelContainer: \(error)")
        }
    }()

    init() {
        // Configure RevenueCat before any views/objects access Purchases.shared
        configureRevenueCat()
        // Eagerly touch SubscriptionManager to ensure observer is attached
        _ = SubscriptionManager.shared
    }

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
        .modelContainer(modelContainer)
    }
    
    private func requestNotificationPermission() async {
            let granted = await notificationService.requestAuthorization()
            if granted {
                print("FocusZoneApp: Notification permission granted")
            } else {
                print("FocusZoneApp: Notification permission denied")
            }
        }

    private func configureRevenueCat() {
        // Configure with provided public SDK key
        let apiKey = "appl_OvrdrmbbOqtogqrIfROZKanDGIP"
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        
        print("[RevenueCat] Configured Purchases SDK with provided key")
        NotificationCenter.default.post(name: .revenueCatConfigured, object: nil)
    }
}

extension Notification.Name {
    static let revenueCatConfigured = Notification.Name("RevenueCatConfigured")
}
