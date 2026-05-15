import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var store: WatchPlantStore

    var body: some View {
        NavigationStack {
            List {
                if !store.plants.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "flame.fill").foregroundStyle(.orange)
                            Text("Streak").font(.caption)
                            Spacer()
                            Text("\(store.streak)").font(.headline)
                        }
                    }
                }

                Section("Plants") {
                    if store.plants.isEmpty {
                        Text("Open HousePlants on iPhone to sync.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(store.plants) { plant in
                            NavigationLink {
                                WatchPlantDetailView(plant: plant)
                            } label: {
                                row(for: plant)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        store.mistAll()
                    } label: {
                        Label("Mist all plants", systemImage: "humidity.fill")
                    }
                }
            }
            .navigationTitle("Jungle")
        }
    }

    private func row(for plant: WatchPlant) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(plant.nickname).font(.body)
                Text(statusLabel(plant.daysUntilWatering))
                    .font(.caption)
                    .foregroundStyle(statusColor(plant.daysUntilWatering))
            }
            Spacer()
            Text("\(plant.healthScore)").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func statusLabel(_ days: Int) -> String {
        if days == Int.max { return "—" }
        if days < 0 { return "Overdue \(-days)d" }
        if days == 0 { return "Water today" }
        return "in \(days)d"
    }

    private func statusColor(_ days: Int) -> Color {
        if days < 0 { return .red }
        if days <= 1 { return .orange }
        return .secondary
    }
}

struct WatchPlantDetailView: View {
    let plant: WatchPlant
    @EnvironmentObject var store: WatchPlantStore

    var body: some View {
        VStack(spacing: 12) {
            Text(plant.nickname).font(.headline)
            Text("Health \(plant.healthScore)")
                .font(.caption).foregroundStyle(.secondary)
            Button {
                store.water(plant.id)
            } label: {
                Label("Water now", systemImage: "drop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            Spacer()
        }
        .padding(.top)
    }
}
