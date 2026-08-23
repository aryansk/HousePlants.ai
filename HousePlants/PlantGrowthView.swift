import SwiftUI
import Charts

/// Per-plant growth analytics — watering history, health score, and journal coverage.
struct PlantGrowthView: View {
    let plant: Plant
    @Environment(DataLoader.self) var dataLoader

    private var myPlant: MyPlant? { dataLoader.myJungleLookup[plant.id] }

    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()

            analyticsContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Growth Analytics")
                    .font(.claudeSans(size: 16, weight: .bold))
            }
        }
    }

    // MARK: - Analytics content

    private var analyticsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                summaryCards
                wateringAdherenceSection
                weeklyWateringChart
                journalSection
                upcomingCareSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Summary cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            AnalyticsStat(
                icon: "heart.fill", color: .green,
                value: "\(myPlant?.healthScore ?? 0)",
                label: "Health Score"
            )
            AnalyticsStat(
                icon: "drop.fill", color: .blue,
                value: "\(wateringsLast30Days)",
                label: "Waterings (30d)"
            )
            AnalyticsStat(
                icon: "camera.fill", color: .purple,
                value: "\(journalPhotoCount)",
                label: "Journal Photos"
            )
        }
    }

    // MARK: - Watering adherence

    private var wateringAdherenceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("WATERING ADHERENCE", subtitle: "Last 30 days")

            let adherence = wateringAdherencePct
            let color: Color = adherence >= 0.75 ? .green : adherence >= 0.5 ? .orange : .red

            VStack(spacing: 10) {
                HStack {
                    Text("\(Int(adherence * 100))%")
                        .font(.claudeSerif(size: 36, weight: .bold))
                        .foregroundStyle(color)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(wateringsLast30Days) of \(expectedWateringsIn30Days) expected")
                            .font(.claudeSans(size: 13))
                            .foregroundColor(.claudeSecondaryText)
                        Text(adherenceLabel(adherence))
                            .font(.claudeSans(size: 12, weight: .semibold))
                            .foregroundStyle(color)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.claudeSecondaryBackground)
                            .frame(height: 10)
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * CGFloat(min(adherence, 1.0)), height: 10)
                            .animation(.spring(response: 0.6), value: adherence)
                    }
                }
                .frame(height: 10)
            }
            .padding(18)
            .background(Color.claudeSecondaryBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Weekly watering chart

    private var weeklyWateringChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("WATERINGS PER WEEK", subtitle: "Last 8 weeks")

            let data = weeklyWateringData
            if data.allSatisfy({ $0.count == 0 }) {
                Text("No watering history yet. Start tracking to see your chart.")
                    .font(.claudeSans(size: 13))
                    .foregroundColor(.claudeSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
                    .background(Color.claudeSecondaryBackground)
                    .cornerRadius(16)
            } else {
                Chart(data) { entry in
                    BarMark(
                        x: .value("Week", entry.weekLabel),
                        y: .value("Waterings", entry.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 160)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { v in
                        AxisGridLine()
                        AxisValueLabel {
                            if let n = v.as(Int.self) { Text("\(n)") }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { v in
                        AxisValueLabel {
                            if let s = v.as(String.self) { Text(s).font(.system(size: 9)) }
                        }
                    }
                }
                .padding(18)
                .background(Color.claudeSecondaryBackground)
                .cornerRadius(16)
            }
        }
    }

    // MARK: - Journal section

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("JOURNAL ACTIVITY", subtitle: "Photo documentation")

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(journalPhotoCount)")
                        .font(.claudeSerif(size: 32, weight: .bold))
                        .foregroundStyle(.purple)
                    Text("total photos")
                        .font(.claudeSans(size: 12))
                        .foregroundColor(.claudeSecondaryText)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    let rate = photosPerMonth
                    Text(rate < 0.5 ? "Low" : rate < 2 ? "Good" : "Excellent")
                        .font(.claudeSerif(size: 22, weight: .bold))
                        .foregroundStyle(rate < 0.5 ? .orange : .green)
                    Text("documentation rate")
                        .font(.claudeSans(size: 12))
                        .foregroundColor(.claudeSecondaryText)
                }

                Spacer()
            }
            .padding(18)
            .background(Color.claudeSecondaryBackground)
            .cornerRadius(16)
        }
    }

    // MARK: - Upcoming care

    private var upcomingCareSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("UPCOMING CARE", subtitle: "Next scheduled events")

            VStack(spacing: 10) {
                if let nextWater = myPlant?.nextWateringDate,
                   let d = DataLoader.isoFormatter.date(from: nextWater) {
                    UpcomingCareRow(icon: "drop.fill", color: .blue,
                                   label: "Next watering",
                                   date: d)
                }
                if let repot = myPlant?.nextRepotDate,
                   let d = DataLoader.isoFormatter.date(from: repot) {
                    UpcomingCareRow(icon: "arrow.up.left.and.arrow.down.right.circle.fill", color: .brown,
                                   label: "Repotting",
                                   date: d)
                }
                if let window = BloomPredictor.predict(for: plant),
                   let daysAway = window.daysUntilNextBloom(), daysAway > 0,
                   let bloomDate = Calendar.current.date(byAdding: .day, value: daysAway, to: Date()) {
                    UpcomingCareRow(icon: "leaf.fill", color: .pink,
                                   label: "Bloom season",
                                   date: bloomDate)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.claudeSans(size: 11, weight: .bold))
                .foregroundColor(.claudeSecondaryText)
                .tracking(1.4)
            Text(subtitle)
                .font(.claudeSans(size: 12))
                .foregroundColor(.claudeSecondaryText.opacity(0.7))
        }
    }

    private var wateringHistory: [Date] {
        guard let history = myPlant?.wateringHistory else { return [] }
        return history.compactMap { DataLoader.isoFormatter.date(from: $0) }
    }

    private var wateringsLast30Days: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return wateringHistory.filter { $0 >= cutoff }.count
    }

    private var expectedWateringsIn30Days: Int {
        guard let catalogPlant = dataLoader.plant(for: plant.id) else { return 4 }
        let freq = dataLoader.getWateringFrequency(for: catalogPlant)
        return max(1, 30 / freq)
    }

    private var wateringAdherencePct: Double {
        let expected = Double(expectedWateringsIn30Days)
        guard expected > 0 else { return 0 }
        return Double(wateringsLast30Days) / expected
    }

    private func adherenceLabel(_ pct: Double) -> String {
        switch pct {
        case 0.9...:  return "On track"
        case 0.6..<0.9: return "Slightly behind"
        default: return "Needs attention"
        }
    }

    struct WeekEntry: Identifiable {
        let id = UUID()
        let weekLabel: String
        let count: Int
    }

    private var weeklyWateringData: [WeekEntry] {
        let cal = Calendar.current
        let now = Date()
        return (0..<8).reversed().map { weeksAgo in
            let weekStart = cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: now)!
            let weekEnd   = cal.date(byAdding: .weekOfYear, value: -weeksAgo + 1, to: now)!
            let count = wateringHistory.filter { $0 >= weekStart && $0 < weekEnd }.count
            let label = weeksAgo == 0 ? "Now" : "-\(weeksAgo)w"
            return WeekEntry(weekLabel: label, count: count)
        }
    }

    private var journalPhotoCount: Int {
        PlantJournalStore.shared.photos(for: plant.id).count
    }

    private var photosPerMonth: Double {
        let photos = PlantJournalStore.shared.photos(for: plant.id)
        guard !photos.isEmpty,
              let oldest = photos.last?.date else { return 0 }
        let monthsElapsed = max(1.0, Date().timeIntervalSince(oldest) / (30 * 86400))
        return Double(photos.count) / monthsElapsed
    }
}

// MARK: - Supporting views

private struct AnalyticsStat: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(value)
                .font(.claudeSerif(size: 22, weight: .bold))
                .foregroundColor(.claudePrimaryText)
            Text(label)
                .font(.claudeSans(size: 11))
                .foregroundColor(.claudeSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(14)
    }
}

private struct UpcomingCareRow: View {
    let icon: String
    let color: Color
    let label: String
    let date: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 32)
            Text(label)
                .font(.claudeSans(size: 14))
                .foregroundColor(.claudePrimaryText)
            Spacer()
            Text(date, style: .relative)
                .font(.claudeSans(size: 13))
                .foregroundColor(.claudeSecondaryText)
        }
        .padding(14)
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.claudeBorder, lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        PlantGrowthView(plant: Plant(
            id: "preview", commonName: "Monstera", botanicalName: "Monstera deliciosa",
            categoryId: "cat_aroid",
            origin: Origin(region: "Mexico", countries: nil, coordinates: Coordinates(lat: 0, lng: 0)),
            images: PlantImages(main: ""), description: "",
            careGuide: CareGuide(difficulty: "easy", light: "bright indirect", water: "weekly",
                                 humidity: "high, 60-80%", soil: "well-draining",
                                 temperatureRange: "65-85°F"),
            toxicity: Toxicity(isPetSafe: false, warning: "Toxic"),
            mlRecognitionConfidence: 0.9,
            skincarePotential: nil, propagation: nil, botanistQuote: nil
        ))
        .environment(DataLoader.shared)
    }
}
