import SwiftUI

// MARK: - Onboarding Goal
enum PlantGoal: String, CaseIterable, Identifiable {
    case keepAlive = "Stop killing my plants"
    case growCollection = "Grow my collection"
    case learnMore = "Learn plant science"
    case decorate = "Make my space beautiful"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .keepAlive: return "heart.circle.fill"
        case .growCollection: return "leaf.circle.fill"
        case .learnMore: return "book.circle.fill"
        case .decorate: return "sparkles"
        }
    }
    var color: Color {
        switch self {
        case .keepAlive: return Color(hex: "E74C3C")
        case .growCollection: return Color(hex: "27AE60")
        case .learnMore: return Color(hex: "8E44AD")
        case .decorate: return Color(hex: "F39C12")
        }
    }
}

enum PlantCount: String, CaseIterable, Identifiable {
    case none = "None yet"
    case few = "1–5 plants"
    case many = "6–15 plants"
    case jungle = "16+ (a jungle!)"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .none: return "questionmark.circle"
        case .few: return "leaf"
        case .many: return "leaf.fill"
        case .jungle: return "tree.fill"
        }
    }
}

// MARK: - Recommendation Engine

/// Scores the plant catalog against onboarding answers (climate, experience,
/// pet safety, goal) to pick starter recommendations.
struct OnboardingRecommender {
    let difficulty: String
    let petSafeOnly: Bool
    let goal: PlantGoal?
    let country: String

    var climateZone: String { Self.climateZone(for: country) }

    func recommend(from allPlants: [Plant], limit: Int = 5) -> [Plant] {
        guard !allPlants.isEmpty else { return [] }

        let avgTemp = Self.averageTemp(for: climateZone)

        let scored = allPlants.map { plant -> (Plant, Double) in
            var score: Double = 0

            // 1. Temperature compatibility (0–40 pts)
            if let (low, high) = Self.parseTempRange(plant.careGuide.temperatureRange) {
                if avgTemp >= Double(low) && avgTemp <= Double(high) {
                    score += 40 // Perfect match
                } else {
                    let distance = avgTemp < Double(low) ? Double(low) - avgTemp : avgTemp - Double(high)
                    score += max(0, 40 - distance * 4)
                }
            } else {
                score += 20 // Unknown range, neutral
            }

            // 2. Difficulty match (0–30 pts)
            let plantDiff = plant.careGuide.difficulty.lowercased()
            switch difficulty {
            case "Beginner":
                if plantDiff.contains("very easy") || plantDiff.contains("beginner") { score += 30 }
                else if plantDiff.contains("easy") { score += 25 }
                else if plantDiff.contains("medium") || plantDiff.contains("intermediate") { score += 10 }
            case "Enthusiast":
                if plantDiff.contains("medium") || plantDiff.contains("intermediate") { score += 30 }
                else if plantDiff.contains("easy") { score += 20 }
                else if plantDiff.contains("hard") { score += 15 }
            case "Botany Pro":
                if plantDiff.contains("hard") { score += 30 }
                else if plantDiff.contains("medium") || plantDiff.contains("intermediate") { score += 25 }
                else if plantDiff.contains("easy") { score += 15 }
            default: score += 15
            }

            // 3. Pet safety (0–20 pts)
            if petSafeOnly {
                score += plant.toxicity.isPetSafe ? 20 : -50 // Heavily penalize toxic plants
            }

            // 4. Goal alignment (0–10 pts)
            switch goal {
            case .keepAlive:
                if plantDiff.contains("easy") || plantDiff.contains("very easy") || plantDiff.contains("beginner") { score += 10 }
            case .growCollection:
                if plant.propagation != nil { score += 10 }
            case .learnMore:
                if plant.botanistQuote != nil { score += 5 }
                score += 5 // All plants good for learning
            case .decorate:
                if plant.images.main.count > 0 { score += 10 }
            case .none:
                score += 5
            }

            return (plant, score)
        }

        let sorted = scored
            .filter { petSafeOnly ? $0.0.toxicity.isPetSafe : true }
            .sorted { $0.1 > $1.1 }

        return sorted.prefix(limit).map { $0.0 }
    }

    func climateNote(for plant: Plant, city: String) -> String {
        let avgTemp = Self.averageTemp(for: climateZone)

        if let (low, high) = Self.parseTempRange(plant.careGuide.temperatureRange) {
            if avgTemp >= Double(low) && avgTemp <= Double(high) {
                return "Great match for \(city.isEmpty ? "your" : city + "'s") climate"
            } else if avgTemp < Double(low) {
                return "Keep indoors during cold months"
            } else {
                return "Keep in shade during hot months"
            }
        }
        return "Adapts well to indoor conditions"
    }

    static func parseTempRange(_ range: String) -> (Int, Int)? {
        // Parse "18°C - 30°C" format
        let numbers = range.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        guard numbers.count >= 2 else { return nil }
        return (numbers[0], numbers[1])
    }

    static func climateZone(for country: String) -> String {
        let c = country.lowercased().trimmingCharacters(in: .whitespaces)

        // Tropical
        let tropical = ["india", "thailand", "indonesia", "malaysia", "philippines", "vietnam",
                        "singapore", "brazil", "colombia", "nigeria", "kenya", "tanzania",
                        "sri lanka", "myanmar", "cambodia", "costa rica", "panama", "ecuador",
                        "peru", "venezuela", "mexico", "cuba", "jamaica", "bangladesh", "ghana"]
        if tropical.contains(c) { return "tropical" }

        // Arid / Desert
        let arid = ["saudi arabia", "uae", "egypt", "iraq", "iran", "pakistan", "algeria",
                     "libya", "morocco", "tunisia", "jordan", "oman", "qatar", "bahrain", "kuwait",
                     "australia", "namibia", "botswana"]
        if arid.contains(c) { return "arid" }

        // Mediterranean
        let med = ["italy", "spain", "greece", "portugal", "turkey", "israel", "croatia",
                    "cyprus", "malta", "lebanon", "tunisia", "south africa"]
        if med.contains(c) { return "mediterranean" }

        // Cold / Continental
        let cold = ["russia", "canada", "norway", "sweden", "finland", "iceland", "denmark",
                     "estonia", "latvia", "lithuania", "poland", "czech republic", "slovakia",
                     "austria", "switzerland", "mongolia", "kazakhstan"]
        if cold.contains(c) { return "cold" }

        // Default: Temperate (most of Europe, US, Japan, etc.)
        return "temperate"
    }

    static func averageTemp(for climate: String) -> Double {
        switch climate {
        case "tropical": return 28
        case "arid": return 32
        case "mediterranean": return 22
        case "cold": return 10
        case "temperate": return 18
        default: return 20
        }
    }
}
