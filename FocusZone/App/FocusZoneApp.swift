
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
//    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
//            TimelineView()
//                .environmentObject(themeManager)
        }
    }
    
}
