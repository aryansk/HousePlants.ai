import SwiftUI

struct ContentView: View {
    @State private var dataLoader = DataLoader.shared
    @State private var tabSelection = TabSelection()
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppAppearance.system.rawValue

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
    }
}

#Preview {
    ContentView()
}
