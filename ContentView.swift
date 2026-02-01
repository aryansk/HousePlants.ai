import SwiftUI

struct ContentView: View {
    @StateObject private var dataLoader = DataLoader()
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView {
                    PlantListView()
                        .tabItem {
                            Label("Discover", systemImage: "leaf.fill")
                        }
                    
                    ToolsView()
                        .tabItem {
                            Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                        }

                    MyJungleView()
                        .tabItem {
                            Label("My Jungle", systemImage: "heart.fill")
                        }
                }
                .tint(.green)
            } else {
                WelcomeView(isCompleted: $hasCompletedOnboarding)
            }
        }
        .environmentObject(dataLoader)
    }
}

#Preview {
    ContentView()
}
