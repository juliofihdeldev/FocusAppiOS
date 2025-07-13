import SwiftUI

struct MainTabView: View {

    @State private var selectedTab = 0
    @StateObject private var themeManager = ThemeManager()
    
    struct FocusZoneApp: App {
        @StateObject private var themeManager = ThemeManager()

        var body: some Scene {
            WindowGroup {
                MainTabView()
                TimelineView()
                    .environmentObject(themeManager)
            }
        }
        
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .environmentObject(themeManager)
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
                .tag(0)

            AIAssistantView()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .environmentObject(themeManager)
    }
}

#Preview {
    MainTabView()
}
