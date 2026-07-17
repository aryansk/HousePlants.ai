import SwiftUI

struct ContentView: View {
    @State private var dataLoader = DataLoader.shared
    @State private var tabSelection = TabSelection()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppAppearance.system.rawValue

    init() {
        let tabBackground = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 27 / 255, green: 37 / 255, blue: 64 / 255, alpha: 1)
                : UIColor(red: 255 / 255, green: 250 / 255, blue: 240 / 255, alpha: 1)
        }
        let normalColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 197 / 255, green: 203 / 255, blue: 218 / 255, alpha: 1)
                : UIColor(red: 65 / 255, green: 73 / 255, blue: 92 / 255, alpha: 1)
        }
        let selectedIconColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 120 / 255, green: 146 / 255, blue: 255 / 255, alpha: 1)
                : UIColor(red: 30 / 255, green: 58 / 255, blue: 214 / 255, alpha: 1)
        }
        let selectedTitleColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 255 / 255, green: 248 / 255, blue: 233 / 255, alpha: 1)
                : UIColor(red: 23 / 255, green: 33 / 255, blue: 59 / 255, alpha: 1)
        }

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = tabBackground
        appearance.shadowColor = normalColor

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = normalColor
        normal.titleTextAttributes = [.foregroundColor: normalColor]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = selectedIconColor
        selected.titleTextAttributes = [
            .foregroundColor: selectedTitleColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView(selection: $tabSelection.selectedTab) {
                    PlantListView()
                        .tabItem { Label("Discover", systemImage: "leaf.fill") }
                        .tag(0)

                    ToolsView()
                        .tabItem { Label("Tools", systemImage: "wrench.and.screwdriver.fill") }
                        .tag(1)

                    MyJungleView()
                        .tabItem { Label("My Jungle", systemImage: "heart.fill") }
                        .tag(2)

                    ProfileView()
                        .tabItem { Label("Profile", systemImage: "person.fill") }
                        .tag(3)
                }
                .tint(Color.claudeAccent)
            } else {
                WelcomeView(isCompleted: $hasCompletedOnboarding)
            }
        }
        .environment(dataLoader)
        .environment(tabSelection)
        .preferredColorScheme(AppAppearance(rawValue: appearanceModeRaw)?.colorScheme)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { dataLoader.flushPendingJungleSave() }
        }
    }
}

#Preview {
    ContentView()
}
