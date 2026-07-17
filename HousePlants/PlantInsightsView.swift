import SwiftUI
import CoreLocation

struct PlantInsightsView: View {
    let myPlant: MyPlant
    @Environment(DataLoader.self) var dataLoader
    @StateObject private var locationManager = LocationManager()
    @StateObject private var homeKit = HomeKitSensorManager.shared

    @State private var assessment: HealthAssessment?
    @State private var isOutdoor: Bool
    @State private var potSize: Int

    init(myPlant: MyPlant) {
        self.myPlant = myPlant
        _isOutdoor = State(initialValue: myPlant.isOutdoor ?? false)
        _potSize = State(initialValue: myPlant.potSizeInches ?? 6)
    }

    private var plant: Plant? {
        dataLoader.plant(for: myPlant.plantId)
    }

    var body: some View {
        List {
            healthSection
            weatherSection
            sensorSection
            repotSection
            bloomSection
            journalSection
        }
        .navigationTitle(myPlant.nickname)
        .onAppear {
            refresh()
            locationManager.requestLocation()
            homeKit.start()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var healthSection: some View {
        Section("Health assessment") {
            if let assessment {
                HStack {
                    Text("\(assessment.score)").font(.system(size: 44, weight: .bold))
                    Text("/100").foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: scoreSymbol(assessment.score))
                        .foregroundStyle(scoreColor(assessment.score))
                        .font(.title)
                }
                if assessment.factors.isEmpty {
                    Text("All looks good.").foregroundStyle(.secondary)
                } else {
                    ForEach(assessment.factors) { factor in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(factor.label).font(.subheadline.weight(.medium))
                                Text(factor.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(factor.delta > 0 ? "+\(factor.delta)" : "\(factor.delta)")
                                .foregroundStyle(factor.delta < 0 ? .red : .green)
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                        }
                    }
                }
            } else {
                Text("Calculating…").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var weatherSection: some View {
        Section("Weather-aware watering") {
            Toggle("Lives outdoors", isOn: $isOutdoor)
                .onChange(of: isOutdoor) { _, new in
                    dataLoader.setOutdoor(plantId: myPlant.plantId, outdoor: new)
                    Task { await syncWeather() }
                }
            if let note = myPlant.wateringAdjustmentNote {
                Label(note, systemImage: "cloud.sun")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("No forecast adjustment active.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button("Refresh forecast") {
                Task { await syncWeather() }
            }
        }
    }

    @ViewBuilder
    private var sensorSection: some View {
        Section("HomeKit sensors") {
            if homeKit.accessories.isEmpty {
                Text("No temperature or humidity accessories found in your home.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                let bound = homeKit.binding(for: myPlant.plantId)
                Picker("Linked sensor", selection: Binding(
                    get: { bound ?? UUID() },
                    set: { homeKit.bind(plantId: myPlant.plantId, accessoryId: $0 == UUID() ? nil : $0) }
                )) {
                    Text("None").tag(UUID())
                    ForEach(homeKit.accessories) { acc in
                        Text(acc.name).tag(acc.id)
                    }
                }

                if let reading = homeKit.reading(for: myPlant.plantId) {
                    if let t = reading.temperatureC {
                        Label("\(t, specifier: "%.1f")°C", systemImage: "thermometer.medium")
                    }
                    if let h = reading.humidityPct {
                        Label("\(h, specifier: "%.0f")% humidity", systemImage: "humidity.fill")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var repotSection: some View {
        Section("Repotting") {
            Stepper(value: $potSize, in: 2...20) {
                Text("Pot size: \(potSize)\"")
            }
            .onChange(of: potSize) { _, new in
                dataLoader.setPotSize(plantId: myPlant.plantId, inches: new)
            }
            if let nextStr = myPlant.nextRepotDate,
               let next = DataLoader.isoFormatter.date(from: nextStr) {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
                if days <= 0 {
                    Label("Repot now — overdue", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } else {
                    Text("Next repot: \(next, format: .dateTime.month().day().year()) (in \(days) days)")
                }
            } else {
                Text("Set pot size to schedule a reminder.")
                    .foregroundStyle(.secondary)
            }
            Button("Mark as repotted today") {
                dataLoader.markRepotted(plantId: myPlant.plantId)
            }
        }
    }

    @ViewBuilder
    private var bloomSection: some View {
        Section("Bloom forecast") {
            if let plant {
                let hemisphere = BloomPredictor.hemisphere(forCountry: dataLoader.userProfile?.locationSettings.country)
                if let window = BloomPredictor.predict(for: plant, hemisphere: hemisphere) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expected: \(window.monthsLabel)").font(.subheadline.weight(.medium))
                        if let days = window.daysUntilNextBloom() {
                            Text("Next window in \(days) day\(days == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text(window.notes).font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Text("No bloom data for this species yet.").foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var journalSection: some View {
        Section("Photo journal") {
            let count = PlantJournalStore.shared.photos(for: myPlant.plantId).count
            NavigationLink {
                PlantJournalView(myPlant: myPlant)
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Open journal")
                    Spacer()
                    Text("\(count)").foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func refresh() {
        assessment = dataLoader.healthAssessment(for: myPlant)
    }

    private func syncWeather() async {
        guard let coord = locationManager.location?.coordinate else { return }
        let adj = await WeatherManager.shared.adjustment(for: coord)
        await MainActor.run {
            dataLoader.recomputeNextWatering(for: myPlant.plantId, weatherAdjustment: adj)
            refresh()
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return .green
        case 50..<80: return .yellow
        default: return .red
        }
    }

    private func scoreSymbol(_ score: Int) -> String {
        switch score {
        case 80...: return "leaf.fill"
        case 50..<80: return "leaf"
        default: return "exclamationmark.triangle.fill"
        }
    }
}
