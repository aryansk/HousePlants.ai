import SwiftUI

struct SitterModeView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @ObservedObject private var proManager = ProManager.shared

    @State private var selectedIds: Set<String> = []
    @State private var pdfURL: URL?
    @State private var isRendering = false
    @State private var selectedTemplate: SitterCardTemplate = .rich
    @State private var showProUpgrade = false

    var body: some View {
        List {
            Section("Owner") {
                Text(dataLoader.userProfile?.username ?? "—")
                    .foregroundStyle(.secondary)
            }

            // Template picker — full access for Pro, locked for free users
            Section("PDF Template") {
                if proManager.isPro {
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
                } else {
                    Button(action: { showProUpgrade = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Minimal Template")
                                    .foregroundStyle(.primary)
                                Text("Upgrade to Pro to unlock the black & white minimal design.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Pro")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(.orange))
                        }
                    }
                    .buttonStyle(.plain)
                }
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
                                    if let plant = dataLoader.plants.first(where: { $0.id == myPlant.plantId }) {
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
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
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
                guard let plant = dataLoader.plants.first(where: { $0.id == myPlant.plantId }) else { return nil }
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
            template: proManager.isPro ? selectedTemplate : .rich
        )
    }
}
