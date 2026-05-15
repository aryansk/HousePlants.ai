import Foundation

struct HealthFactor: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let delta: Int
    let detail: String
}

struct HealthAssessment: Equatable {
    let score: Int
    let factors: [HealthFactor]
}

enum HealthScoreEngine {
    static func compute(
        myPlant: MyPlant,
        plant: Plant,
        journalPhotoCount: Int,
        mostRecentJournalDate: Date?,
        now: Date = Date()
    ) -> HealthAssessment {
        var score = 100
        var factors: [HealthFactor] = []

        // Watering adherence
        if let nextStr = myPlant.nextWateringDate,
           let next = DataLoader.isoFormatter.date(from: nextStr) {
            let daysOverdue = Calendar.current.dateComponents([.day], from: next, to: now).day ?? 0
            if daysOverdue > 0 {
                let penalty = min(30, daysOverdue * 5)
                score -= penalty
                factors.append(HealthFactor(label: "Watering overdue", delta: -penalty,
                                            detail: "\(daysOverdue) day\(daysOverdue == 1 ? "" : "s") past due"))
            } else {
                factors.append(HealthFactor(label: "Watering on schedule", delta: 0,
                                            detail: "Next in \(-daysOverdue) day\(-daysOverdue == 1 ? "" : "s")"))
            }
        }

        // Fertilizing
        if let fertStr = myPlant.lastFertilized,
           let fert = DataLoader.isoFormatter.date(from: fertStr) {
            let days = Calendar.current.dateComponents([.day], from: fert, to: now).day ?? 0
            if days > 60 {
                score -= 10
                factors.append(HealthFactor(label: "Fertilizer overdue", delta: -10,
                                            detail: "Last fed \(days) days ago"))
            }
        } else {
            score -= 5
            factors.append(HealthFactor(label: "Never fertilized", delta: -5,
                                        detail: "Add to care log"))
        }

        // Misting (only for humidity-loving species)
        let humidity = plant.careGuide.humidity.lowercased()
        let humidityLoving = humidity.contains("high") || humidity.contains("humid") || humidity.contains("mist")
        if humidityLoving {
            if let mistStr = myPlant.lastMisted,
               let mist = DataLoader.isoFormatter.date(from: mistStr) {
                let days = Calendar.current.dateComponents([.day], from: mist, to: now).day ?? 0
                if days > 14 {
                    score -= 5
                    factors.append(HealthFactor(label: "Misting overdue", delta: -5,
                                                detail: "Last misted \(days) days ago"))
                }
            } else {
                score -= 5
                factors.append(HealthFactor(label: "Needs misting", delta: -5,
                                            detail: "Humidity-loving species"))
            }
        }

        // Repotting
        if let repotStr = myPlant.nextRepotDate,
           let repot = DataLoader.isoFormatter.date(from: repotStr),
           repot < now {
            score -= 10
            factors.append(HealthFactor(label: "Repotting overdue", delta: -10,
                                        detail: "Roots may be cramped"))
        }

        // Journal engagement bonus
        if let recent = mostRecentJournalDate,
           Calendar.current.dateComponents([.day], from: recent, to: now).day ?? 99 <= 30 {
            score += 5
            factors.append(HealthFactor(label: "Active journaling", delta: 5,
                                        detail: "\(journalPhotoCount) photo\(journalPhotoCount == 1 ? "" : "s") in journal"))
        }

        score = min(100, max(0, score))
        return HealthAssessment(score: score, factors: factors)
    }
}
