import Foundation

// MARK: - Repotting
extension DataLoader {

    /// Heuristic: pot size sets a base interval (small <6" → 12mo, medium 6–10" → 18mo, large → 24mo),
    /// then growth rate (journal photos / month since last repot) shortens or extends it.
    func recomputeRepotDate(for plantId: String) {
        guard var profile = userProfile,
              let idx = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }

        let pot = profile.myJungle[idx].potSizeInches ?? 6
        let baseMonths: Double = pot < 6 ? 12 : (pot <= 10 ? 18 : 24)

        let anchor: Date = {
            if let last = profile.myJungle[idx].lastRepotted,
               let date = DataLoader.isoFormatter.date(from: last) {
                return date
            }
            // Fall back to acquired date (numeric format, not ISO)
            let f = DateFormatter()
            f.dateStyle = .short
            return f.date(from: profile.myJungle[idx].dateAcquired) ?? Date()
        }()

        let multiplier = growthRateMultiplier(plantId: plantId, since: anchor)
        let adjustedMonths = max(6, min(36, Int((baseMonths * multiplier).rounded())))

        guard let next = Calendar.current.date(byAdding: .month, value: adjustedMonths, to: anchor) else { return }
        profile.myJungle[idx].nextRepotDate = DataLoader.isoFormatter.string(from: next)

        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }

    func setPotSize(plantId: String, inches: Int) {
        guard var profile = userProfile,
              let idx = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        profile.myJungle[idx].potSizeInches = inches
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
        recomputeRepotDate(for: plantId)
    }

    func markRepotted(plantId: String) {
        guard var profile = userProfile,
              let idx = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        profile.myJungle[idx].lastRepotted = DataLoader.isoFormatter.string(from: Date())
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
        recomputeRepotDate(for: plantId)
    }

    func daysUntilRepot(myPlant: MyPlant) -> Int? {
        guard let dateString = myPlant.nextRepotDate,
              let date = DataLoader.isoFormatter.date(from: dateString) else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }

    /// Photos-per-month since `anchor` → multiplier on the base repot interval.
    /// Fast-growing plants (≥2 photos/mo) get 0.7×, slow (<0.5/mo) get 1.3×, otherwise 1.0×.
    private func growthRateMultiplier(plantId: String, since anchor: Date) -> Double {
        let photos = PlantJournalStore.shared.photos(for: plantId).filter { $0.date >= anchor }
        let monthsElapsed = max(1.0, Date().timeIntervalSince(anchor) / (60 * 60 * 24 * 30))
        let perMonth = Double(photos.count) / monthsElapsed
        if perMonth >= 2 { return 0.7 }
        if perMonth < 0.5 { return 1.3 }
        return 1.0
    }

    /// Generate in-app notifications for plants due to be repotted within 14 days.
    /// Skips plants already notified about within the last 7 days to avoid spam.
    func scanRepotReminders() {
        guard let profile = userProfile else { return }
        let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        for myPlant in profile.myJungle {
            guard let days = daysUntilRepot(myPlant: myPlant), days <= 14, days >= -180 else { continue }
            guard let plant = plants.first(where: { $0.id == myPlant.plantId }) else { continue }
            let alreadyNotified = notifications.contains { n in
                n.type == .repotting && n.date >= cutoff && n.message.contains(plant.commonName)
            }
            if alreadyNotified { continue }
            let message: String
            if days <= 0 {
                message = "\(plant.commonName) is overdue for repotting (\(-days) day\(days == -1 ? "" : "s") past due)."
            } else {
                message = "\(plant.commonName) is due for repotting in \(days) day\(days == 1 ? "" : "s")."
            }
            addNotification(title: "Repotting Reminder", message: message, type: .repotting)
        }
    }
}
