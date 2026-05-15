import AppIntents

@available(iOS 17.0, *)
struct HousePlantsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WaterPlantIntent(),
            phrases: [
                "Water my \(\.$plant) with \(.applicationName)",
                "Log watering for \(\.$plant) in \(.applicationName)"
            ],
            shortTitle: "Water Plant",
            systemImageName: "drop.fill"
        )
        AppShortcut(
            intent: DidIWaterPlantIntent(),
            phrases: [
                "Did I water my \(\.$plant) with \(.applicationName)",
                "When did I last water \(\.$plant) in \(.applicationName)"
            ],
            shortTitle: "Check Watering",
            systemImageName: "questionmark.circle"
        )
    }
}
