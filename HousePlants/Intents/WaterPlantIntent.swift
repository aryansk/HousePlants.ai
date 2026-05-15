import AppIntents

@available(iOS 17.0, *)
struct WaterPlantIntent: AppIntent {
    static var title: LocalizedStringResource = "Water Plant"
    static var description = IntentDescription("Logs that you've watered a plant in your jungle.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Plant")
    var plant: PlantEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        DataLoader.shared.waterPlant(plantId: plant.id)
        return .result(dialog: "Logged watering for \(plant.nickname).")
    }
}
