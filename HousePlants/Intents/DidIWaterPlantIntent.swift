import AppIntents
import Foundation

@available(iOS 17.0, *)
struct DidIWaterPlantIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Watering Status"
    static var description = IntentDescription("Asks whether you've recently watered a plant.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Plant")
    var plant: PlantEntity

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let loader = DataLoader.shared
        guard let myPlant = loader.userProfile?.myJungle.first(where: { $0.plantId == plant.id }) else {
            return .result(dialog: "I couldn't find \(plant.nickname) in your jungle.")
        }

        let lastDate: Date? = {
            if let last = myPlant.wateringHistory?.last,
               let parsed = DataLoader.isoFormatter.date(from: last) {
                return parsed
            }
            return nil
        }()

        if let last = lastDate {
            let hours = Calendar.current.dateComponents([.hour], from: last, to: Date()).hour ?? 0
            let phrasing: String
            if hours < 24 {
                phrasing = "Yes — about \(hours) hour\(hours == 1 ? "" : "s") ago."
            } else {
                let days = hours / 24
                phrasing = "Yes — \(days) day\(days == 1 ? "" : "s") ago."
            }
            if let due = loader.daysUntilWatering(myPlant: myPlant), due <= 0 {
                return .result(dialog: "\(phrasing) But it's due again now.")
            }
            return .result(dialog: IntentDialog(stringLiteral: phrasing))
        }

        if let due = loader.daysUntilWatering(myPlant: myPlant) {
            if due <= 0 {
                return .result(dialog: "No, and \(plant.nickname) is overdue by \(-due) day\(due == -1 ? "" : "s").")
            }
            return .result(dialog: "No recent watering on record. Next due in \(due) day\(due == 1 ? "" : "s").")
        }

        return .result(dialog: "No watering history yet for \(plant.nickname).")
    }
}
