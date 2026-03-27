import SwiftUI

struct ContentView: View {
    @StateObject private var dataLoader = DataLoader()
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("darkModeEnabled") var darkModeEnabled: Bool = false
    
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
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
                .tint(.green)
            } else {
                WelcomeView(isCompleted: $hasCompletedOnboarding)
            }
        }
        .environmentObject(dataLoader)
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }
}


#Preview {
    ContentView()
}
