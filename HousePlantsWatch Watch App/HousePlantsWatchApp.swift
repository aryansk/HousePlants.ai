import SwiftUI

@main
struct HousePlantsWatchApp: App {
    @StateObject private var store = WatchPlantStore()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(store)
        }
    }
}
