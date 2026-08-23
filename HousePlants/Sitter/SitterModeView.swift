import SwiftUI

struct SitterModeView: View {
    @Environment(DataLoader.self) var dataLoader

    @State private var selectedIds: Set<String> = []
    @State private var pdfURL: URL?
    @State private var isRendering = false
    @State private var selectedTemplate: SitterCardTemplate = .rich

    var body: some View {
        List {
            Section("Owner") {
                Text(dataLoader.userProfile?.username ?? "—")
                    .foregroundStyle(.secondary)
            }

            // Both sitter card templates are included in this release.
            Section("PDF Template") {
                Picker("Template", selection: $selectedTemplate) {
                    ForEach(SitterCardTemplate.allCases) { template in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.rawValue)
                            Text(template.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(template)
                    }
                }
                .pickerStyle(.inline)
                .onChange(of: selectedTemplate) { _, _ in pdfURL = nil }
            }

            Section("Pick plants to include") {
                if let jungle = dataLoader.userProfile?.myJungle, !jungle.isEmpty {
                    ForEach(jungle) { myPlant in
                        Button {
                            toggle(myPlant.plantId)
                        } label: {
                            HStack {
                                Image(systemName: selectedIds.contains(myPlant.plantId) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(.green)
                                VStack(alignment: .leading) {
                                    Text(myPlant.nickname)
                                    if let plant = dataLoader.plant(for: myPlant.plantId) {
                                        Text(plant.botanicalName).font(.caption).italic().foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("Add a plant to My Jungle first.").foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    Task { await renderPDF() }
                } label: {
                    if isRendering {
                        ProgressView()
                    } else {
                        Label("Generate care PDF", systemImage: "doc.richtext")
                    }
                }
                .disabled(selectedIds.isEmpty || isRendering)

                if let pdfURL {
                    ShareLink(item: pdfURL) {
                        Label("Share with sitter", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("Plant Sitter Mode")
    }

    private func toggle(_ id: String) {
        if selectedIds.contains(id) { selectedIds.remove(id) } else { selectedIds.insert(id) }
        pdfURL = nil
    }

    @MainActor
    private func renderPDF() async {
        isRendering = true
        defer { isRendering = false }

        guard let profile = dataLoader.userProfile else { return }

        let sitterPlants: [SitterPlant] = profile.myJungle
            .filter { selectedIds.contains($0.plantId) }
            .compactMap { myPlant -> SitterPlant? in
                guard let plant = dataLoader.plant(for: myPlant.plantId) else { return nil }
                let next: String = {
                    if let s = myPlant.nextWateringDate, let d = DataLoader.isoFormatter.date(from: s) {
                        return d.formatted(date: .abbreviated, time: .omitted)
                    }
                    return "Set up in app"
                }()
                let hemisphere = BloomPredictor.hemisphere(forCountry: profile.locationSettings.country)
                let bloomText: String? = BloomPredictor.predict(for: plant, hemisphere: hemisphere)
                    .map { "Expected \($0.monthsLabel). \($0.notes)" }

                return SitterPlant(
                    id: myPlant.plantId,
                    nickname: myPlant.nickname,
                    species: plant.botanicalName,
                    waterText: plant.careGuide.water,
                    nextWateringText: next,
                    lightText: plant.careGuide.light,
                    humidityText: plant.careGuide.humidity,
                    toxicityText: plant.toxicity.isPetSafe ? "Pet-safe" : plant.toxicity.warning,
                    locationInHome: myPlant.locationInHome,
                    notes: myPlant.notes,
                    bloomText: bloomText
                )
            }

        pdfURL = SitterCardRenderer.renderPDF(
            owner: profile.username,
            ownerContact: "",
            plants: sitterPlants,
            template: selectedTemplate
        )
    }
}
