import Foundation

nonisolated enum Hemisphere: Sendable {
    case northern, southern
}

nonisolated struct BloomWindow: Equatable, Sendable {
    /// 1-indexed months (1 = January) when blooming typically occurs in the northern hemisphere.
    let months: [Int]
    let notes: String

    func adjusted(for hemisphere: Hemisphere) -> BloomWindow {
        guard hemisphere == .southern else { return self }
        let flipped = months.map { (($0 + 5) % 12) + 1 }
        return BloomWindow(months: flipped, notes: notes)
    }

    var monthsLabel: String {
        let f = DateFormatter()
        let names = months.sorted().map { f.shortMonthSymbols[$0 - 1] }
        return names.joined(separator: ", ")
    }

    func daysUntilNextBloom(from date: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard !months.isEmpty else { return nil }
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = comps.year, let month = comps.month else { return nil }
        let sorted = months.sorted()
        // Find next month >= current
        let nextMonth = sorted.first(where: { $0 >= month }) ?? (sorted.first! + 12)
        var target = DateComponents()
        target.year = nextMonth > 12 ? year + 1 : year
        target.month = nextMonth > 12 ? nextMonth - 12 : nextMonth
        target.day = 1
        guard let targetDate = calendar.date(from: target) else { return nil }
        return calendar.dateComponents([.day], from: date, to: targetDate).day
    }
}

nonisolated enum BloomPredictor {
    /// Genus-keyed bloom table. Months are northern-hemisphere defaults; predict() flips for south.
    private static let table: [String: BloomWindow] = [
        "Phalaenopsis": .init(months: [2, 3, 4], notes: "Spike emerges in cool nights."),
        "Cattleya": .init(months: [9, 10, 11], notes: "Fall bloomer, fragrant."),
        "Dendrobium": .init(months: [3, 4, 5], notes: "Following a dry winter rest."),
        "Saintpaulia": .init(months: [1, 4, 7, 10], notes: "African violets can bloom year-round under good light."),
        "Hoya": .init(months: [5, 6, 7, 8], notes: "Keep spurs intact between blooms."),
        "Anthurium": .init(months: [3, 4, 5, 6, 7, 8], notes: "Spathes through warm months."),
        "Spathiphyllum": .init(months: [4, 5, 6], notes: "Peace lilies bloom in spring with bright indirect light."),
        "Begonia": .init(months: [5, 6, 7, 8, 9], notes: "Long summer flush."),
        "Hibiscus": .init(months: [5, 6, 7, 8, 9, 10], notes: "Daily blooms in heat."),
        "Jasminum": .init(months: [3, 4, 5, 6], notes: "Night-fragrant."),
        "Plumeria": .init(months: [5, 6, 7, 8, 9], notes: "Loves heat and full sun."),
        "Gardenia": .init(months: [5, 6, 7], notes: "Acidic soil, warm nights."),
        "Bougainvillea": .init(months: [4, 5, 6, 7, 8, 9, 10], notes: "Drought stress triggers blooms."),
        "Adenium": .init(months: [4, 5, 6, 7, 8], notes: "Desert rose, full sun."),
        "Schlumbergera": .init(months: [11, 12], notes: "Holiday cactus — long nights cue bloom."),
        "Kalanchoe": .init(months: [1, 2, 3], notes: "Short-day plant — needs 14h dark to set buds."),
        "Echinopsis": .init(months: [5, 6, 7, 8], notes: "Night blooming cactus."),
        "Epiphyllum": .init(months: [5, 6, 7], notes: "Orchid cactus, night fragrant."),
        "Cymbidium": .init(months: [1, 2, 3, 4], notes: "Needs cool autumn nights to spike."),
        "Vanda": .init(months: [3, 4, 5, 9, 10], notes: "Twice yearly under good light."),
        "Streptocarpus": .init(months: [4, 5, 6, 7, 8, 9], notes: "Cape primrose, long bloom flush."),
        "Clivia": .init(months: [2, 3, 4], notes: "Needs cool dry winter rest."),
        "Hippeastrum": .init(months: [12, 1, 2], notes: "Amaryllis, forced winter bloom."),
        "Crassula": .init(months: [11, 12, 1], notes: "Jade plants bloom in cool short days when mature."),
        "Aeschynanthus": .init(months: [6, 7, 8, 9], notes: "Lipstick plant trails through summer."),
        "Sinningia": .init(months: [4, 5, 6, 7, 8], notes: "Gloxinia, soft humidity helps."),
        "Tillandsia": .init(months: [3, 4, 5, 6], notes: "Air plants bloom once at maturity."),
        "Bromeliad": .init(months: [3, 4, 5, 6, 7], notes: "Single inflorescence per rosette."),
        "Citrus": .init(months: [3, 4, 5], notes: "Spring flush, fragrant."),
        "Lavandula": .init(months: [6, 7, 8], notes: "Full sun, dry soil.")
    ]

    static func predict(for plant: Plant, hemisphere: Hemisphere = .northern) -> BloomWindow? {
        // Plant.botanicalName is like "Phalaenopsis amabilis" — first word is genus.
        let genus = plant.botanicalName.split(separator: " ").first.map(String.init) ?? ""
        guard let window = table[genus] else { return nil }
        return window.adjusted(for: hemisphere)
    }

    /// Pick a hemisphere from a country name. Defaults to northern for unknowns.
    static func hemisphere(forCountry country: String?) -> Hemisphere {
        let south: Set<String> = [
            "Argentina", "Australia", "Bolivia", "Brazil", "Chile", "Ecuador", "Indonesia",
            "Madagascar", "New Zealand", "Paraguay", "Peru", "South Africa", "Uruguay", "Zimbabwe",
            "Mozambique", "Angola", "Namibia", "Botswana", "Lesotho", "Eswatini", "Malawi", "Zambia"
        ]
        guard let country else { return .northern }
        return south.contains(country) ? .southern : .northern
    }
}
