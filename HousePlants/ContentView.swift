import SwiftUI

struct ContentView: View {
    @State private var dataLoader = DataLoader.shared
    @State private var tabSelection = TabSelection()
    @State private var careExperience = CareExperienceStore.shared
    @State private var hasAppliedAdaptiveHome = false
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppAppearance.system.rawValue

    // The old initialiser installed a `UITabBarAppearance` with
    // `configureWithOpaqueBackground()` and a hand-matched paper fill, because before
    // Liquid Glass the only way to keep the tab bar on-brand was to paint it. That now
    // does active harm: an opaque background is exactly what stops the system applying
    // the glass material, so the app would opt itself out of the new design.
    //
    // The bar is now left alone. `.tint` still carries the Indie House accent through
    // to the selected item, and the material picks up the paper background behind it.

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView(selection: $tabSelection.selectedTab) {
                    Tab("Discover", systemImage: "leaf.fill", value: 0) {
                        PlantListView()
                    }

                    Tab("Tools", systemImage: "wrench.and.screwdriver.fill", value: 1) {
                        ToolsView()
                    }

                    // My Jungle is the app's home for anyone with a collection and the
                    // destination for every care action, so it takes the prominent role
                    // and separates to the trailing edge where that role exists.
                    Tab("My Jungle", systemImage: "heart.fill", value: 2, role: .prominentIfAvailable) {
                        MyJungleView()
                    }

                    Tab("Profile", systemImage: "person.fill", value: 3) {
                        ProfileView()
                    }
                }
                .tint(Color.claudeAccent)
                .onAppear {
                    guard !hasAppliedAdaptiveHome else { return }
                    hasAppliedAdaptiveHome = true
                    // Discover is the welcoming home for a new gardener. Once a collection
                    // exists, return users to the action-oriented My Jungle experience.
                    tabSelection.selectedTab = dataLoader.userProfile?.myJungle.isEmpty == false ? 2 : 0
                }
            } else {
                WelcomeView(isCompleted: $hasCompletedOnboarding)
            }
        }
        .environment(dataLoader)
        .environment(tabSelection)
        .environment(careExperience)
        .preferredColorScheme(AppAppearance(rawValue: appearanceModeRaw)?.colorScheme)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { dataLoader.flushPendingJungleSave() }
        }
    }
}

#Preview {
    ContentView()
}
