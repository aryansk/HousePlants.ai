import SwiftUI

// MARK: - Moon Phase Calculator
struct MoonCalculator {
    static func moonAge(for date: Date) -> Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        var r = year % 100
        r = r % 19
        if r > 9 { r -= 19 }
        r = ((r * 11) % 30) + month + day
        if month < 3 { r += 2 }
        r -= ((year < 2000) ? 4 : 8)
        r = ((r + 30) % 30)
        return Double(r < 0 ? r + 30 : r)
    }
    
    static func phaseFraction(for date: Date) -> Double {
        return moonAge(for: date) / 29.53
    }
    
    static func illumination(for date: Date) -> Double {
        let fraction = phaseFraction(for: date)
        return (1.0 - cos(fraction * 2 * .pi)) / 2.0 * 100.0
    }
    
    static func phaseName(for date: Date) -> String {
        let age = moonAge(for: date)
        switch age {
        case 0..<1.85:     return "New Moon"
        case 1.85..<7.38:  return "Waxing Crescent"
        case 7.38..<9.23:  return "First Quarter"
        case 9.23..<14.77: return "Waxing Gibbous"
        case 14.77..<16.61: return "Full Moon"
        case 16.61..<22.15: return "Waning Gibbous"
        case 22.15..<24.0: return "Last Quarter"
        case 24.0..<29.53: return "Waning Crescent"
        default: return "New Moon"
        }
    }
    
    static func phaseIcon(for date: Date) -> String {
        let age = moonAge(for: date)
        switch age {
        case 0..<1.85:     return "moonphase.new.moon"
        case 1.85..<7.38:  return "moonphase.waxing.crescent"
        case 7.38..<9.23:  return "moonphase.first.quarter"
        case 9.23..<14.77: return "moonphase.waxing.gibbous"
        case 14.77..<16.61: return "moonphase.full.moon"
        case 16.61..<22.15: return "moonphase.waning.gibbous"
        case 22.15..<24.0: return "moonphase.last.quarter"
        case 24.0..<29.53: return "moonphase.waning.crescent"
        default: return "moonphase.new.moon"
        }
    }
    
    static func nextPhaseDate(from date: Date, targetAge: Double) -> Date {
        let currentAge = moonAge(for: date)
        var daysUntil = targetAge - currentAge
        if daysUntil <= 0 { daysUntil += 29.53 }
        return Calendar.current.date(byAdding: .day, value: Int(ceil(daysUntil)), to: date) ?? date
    }
    
    static func gardeningAdvice(for date: Date) -> (title: String, advice: String, activities: [GardeningActivity]) {
        let age = moonAge(for: date)
        switch age {
        case 0..<1.85:
            return ("Rest & Plan", "The new moon is a time for rest. Plan your garden layout and prepare seeds for the cycle ahead.",
                    [.init(name: "Plan Layout", icon: "map", recommended: true),
                     .init(name: "Prepare Soil", icon: "square.stack.3d.up.fill", recommended: true),
                     .init(name: "Transplant", icon: "arrow.left.arrow.right", recommended: false),
                     .init(name: "Harvest", icon: "basket", recommended: false)])
        case 1.85..<7.38:
            return ("Sow & Sprout", "Rising lunar light encourages leaf growth. Ideal for planting leafy greens and above-ground crops.",
                    [.init(name: "Sow Seeds", icon: "leaf", recommended: true),
                     .init(name: "Graft Plants", icon: "scissors", recommended: true),
                     .init(name: "Fertilize", icon: "drop.fill", recommended: true),
                     .init(name: "Prune", icon: "scissors", recommended: false)])
        case 7.38..<9.23:
            return ("Growth Surge", "First quarter moon pulls moisture upward. Strong sap flow benefits transplanting.",
                    [.init(name: "Transplant", icon: "arrow.left.arrow.right", recommended: true),
                     .init(name: "Fertilize", icon: "drop.fill", recommended: true),
                     .init(name: "Plant Vines", icon: "leaf.arrow.triangle.pullpath", recommended: true),
                     .init(name: "Root Crops", icon: "carrot", recommended: false)])
        case 9.23..<14.77:
            return ("Peak Energy", "Optimal alignment for foliar feeding. Focus on nutrient absorption while the lunar pull is strong.",
                    [.init(name: "Foliar Feed", icon: "spray", recommended: true),
                     .init(name: "Water Deeply", icon: "drop.fill", recommended: true),
                     .init(name: "Mist Leaves", icon: "humidity.fill", recommended: true),
                     .init(name: "Heavy Prune", icon: "scissors", recommended: false)])
        case 14.77..<16.61:
            return ("Harvest Moon", "Full moon maximum light and gravity. Harvest herbs at peak potency. Avoid pruning.",
                    [.init(name: "Harvest Herbs", icon: "leaf.fill", recommended: true),
                     .init(name: "Harvest Fruit", icon: "basket", recommended: true),
                     .init(name: "Make Cuttings", icon: "scissors", recommended: true),
                     .init(name: "Transplant", icon: "arrow.left.arrow.right", recommended: false)])
        case 16.61..<22.15:
            return ("Wind Down", "Declining light draws energy to roots. Perfect for root crops and bulbs.",
                    [.init(name: "Plant Bulbs", icon: "circle.fill", recommended: true),
                     .init(name: "Root Crops", icon: "carrot", recommended: true),
                     .init(name: "Compost", icon: "leaf.arrow.triangle.pullpath", recommended: true),
                     .init(name: "Sow Seeds", icon: "leaf", recommended: false)])
        case 22.15..<24.0:
            return ("Deep Roots", "Last quarter. Energy concentrated below ground. Excellent time for pruning and weeding.",
                    [.init(name: "Prune", icon: "scissors", recommended: true),
                     .init(name: "Weed", icon: "xmark.circle", recommended: true),
                     .init(name: "Pest Control", icon: "ant", recommended: true),
                     .init(name: "Transplant", icon: "arrow.left.arrow.right", recommended: false)])
        default:
            return ("Rest Phase", "Waning crescent. The cycle nears its end. Clear debris and prepare for the next new moon.",
                    [.init(name: "Clear Debris", icon: "trash", recommended: true),
                     .init(name: "Turn Soil", icon: "square.stack.3d.up.fill", recommended: true),
                     .init(name: "Rest", icon: "moon.zzz", recommended: true),
                     .init(name: "Sow Seeds", icon: "leaf", recommended: false)])
        }
    }
}

struct GardeningActivity: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let recommended: Bool
}
