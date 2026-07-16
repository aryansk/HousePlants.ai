import SwiftUI

/// The "Overdue! / Water today / In 2d / 5 days" label shown on cards and rows. This logic was
/// copy-pasted across four jungle components; centralising it means a wording or threshold change
/// happens in exactly one place.
struct WateringStatusDisplay {
    let text: String
    let color: Color
    let icon: String
}

extension DataLoader {
    func wateringStatusDisplay(for myPlant: MyPlant?) -> WateringStatusDisplay {
        guard let myPlant else {
            return WateringStatusDisplay(text: "Unknown", color: .gray, icon: "drop.fill")
        }
        guard let daysUntil = daysUntilWatering(myPlant: myPlant) else {
            return WateringStatusDisplay(text: "Not set", color: .gray, icon: "drop.fill")
        }
        if daysUntil < 0 {
            return WateringStatusDisplay(text: "Overdue!", color: .red, icon: "exclamationmark.triangle.fill")
        } else if daysUntil == 0 {
            return WateringStatusDisplay(text: "Water today", color: .orange, icon: "drop.fill")
        } else if daysUntil <= 2 {
            return WateringStatusDisplay(text: "In \(daysUntil)d", color: .blue, icon: "drop.fill")
        } else {
            return WateringStatusDisplay(text: "\(daysUntil) days", color: .green, icon: "checkmark.circle.fill")
        }
    }
}
