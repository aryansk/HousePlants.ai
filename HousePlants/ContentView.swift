import SwiftUI

struct ContentView: View {
    @StateObject private var dataLoader = DataLoader.shared
    @State private var tabSelection = TabSelection()
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("darkModeEnabled") var darkModeEnabled: Bool = false

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
        .environmentObject(dataLoader)
        .environment(tabSelection)
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}

#Preview {
    ContentView()
}
