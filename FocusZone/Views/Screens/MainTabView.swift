import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .tabItem {
                    Label(NSLocalizedString("timeline", comment: "Timeline tab label"), systemImage: "calendar")
                }
                .tag(0)

            FocusInsightsView()
                .tabItem {
                    Label(NSLocalizedString("insights", comment: "Insights tab label"), systemImage: selectedTab == 1 ? "brain.head.profile.fill" : "brain.head.profile")
                }
                .tag(1)
                .overlay(
                    // Pro badge overlay
                    VStack {
                        HStack {
                            Spacer()
                            if !subscriptionManager.isProUser {
                                ProFeatureGate()
                                    .padding(.top, 8)
                                    .padding(.trailing, 16)
                            }
                        }
                        Spacer()
                    }
                )

            SettingsView()
                .tabItem {
                    Label(NSLocalizedString("settings", comment: "Settings tab label"), systemImage: "gearshape")
                }
                .tag(2)
        }
        .accentColor(AppColors.accent)
        .environmentObject(subscriptionManager)
    }
    
    
    // MARK: - Removed complex layout methods for now
    private var sidebarView: some View {
        EmptyView()
    }
    
    private var mainContentView: some View {
        EmptyView()
    }
    
    private var navigationTitle: String {
        return "FocusZone"
    }
    
    private var proBadge: some View {
        EmptyView()
    }
    
    private var proTabBadge: some View {
        EmptyView()
    }
    
    private func setupTabBarAppearance() {
        // Empty for now
    }
    
    // MARK: - Original Sidebar View (Removed)
    private var originalSidebarView: some View {
        List(selection: $selectedTab) {
            NavigationLink(value: 0) {
                Label(NSLocalizedString("timeline", comment: "Timeline tab label"), systemImage: "calendar")
                    .font(.headline)
            }
            .tag(0)
            
            NavigationLink(value: 1) {
                HStack {
                    Label(NSLocalizedString("insights", comment: "Insights tab label"), systemImage: selectedTab == 1 ? "brain.head.profile.fill" : "brain.head.profile")
                        .font(.headline)
                    
                    Spacer()
                    
                    if !subscriptionManager.isProUser {
                        proBadge
                    }
                }
            }
            .tag(1)
            
            NavigationLink(value: 2) {
                Label(NSLocalizedString("settings", comment: "Settings tab label"), systemImage: "gear")
                    .font(.headline)
            }
            .tag(2)
        }
        .navigationTitle("FocusZone")
        .listStyle(SidebarListStyle())
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        Group {
            switch selectedTab {
            case 0:
                TimelineView()
            case 1:
                FocusInsightsView()
            case 2:
                SettingsView()
            default:
                TimelineView()
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Navigation Title
    private var navigationTitle: String {
        switch selectedTab {
        case 0:
            return NSLocalizedString("timeline", comment: "Timeline tab label")
        case 1:
            return NSLocalizedString("insights", comment: "Insights tab label")
        case 2:
            return NSLocalizedString("settings", comment: "Settings tab label")
        default:
            return "FocusZone"
        }
    }
    
    // MARK: - Pro Badge
    private var proBadge: some View {
        Text(NSLocalizedString("pro", comment: "Pro subscription badge"))
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(8)
    }
    
    @ViewBuilder
    private var proTabBadge: some View {
        if !subscriptionManager.isProUser && selectedTab != 1 {
            Text(NSLocalizedString("pro", comment: "Pro subscription badge"))
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .offset(x: -10, y: 10)
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Selected item
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemPurple
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemPurple
        ]
        
        // Normal item
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}


#Preview {
    MainTabView()
}
