import SwiftUI
import PhotosUI

struct PlantJournalView: View {
    let myPlant: MyPlant
    @Environment(DataLoader.self) var dataLoader

    @State private var entries: [JournalEntry] = []
    @State private var pickerItem: PhotosPickerItem?
    @State private var gifURL: URL?
    @State private var isGenerating = false

    var body: some View {
        List {
            Section {
                if entries.isEmpty {
                    Text("No photos yet. Snap one to start the timeline.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries) { entry in
                        HStack(spacing: 12) {
                            thumbnail(entry)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading) {
                                Text(entry.date, style: .date)
                                    .font(.subheadline.weight(.medium))
                                Text(entry.date, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
            } header: {
                Text("\(entries.count) photo\(entries.count == 1 ? "" : "s")")
            }

            Section {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Add photo", systemImage: "photo.badge.plus")
                }

                Button {
                    Task { await makeGIF() }
                } label: {
                    if isGenerating {
                        ProgressView()
                    } else {
                        Label("Make growth GIF", systemImage: "sparkles")
                    }
                }
                .disabled(entries.count < 2 || isGenerating)

                if let gif = gifURL {
                    ShareLink(item: gif) {
                        Label("Share GIF", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("\(myPlant.nickname) journal")
        .onAppear(perform: reload)
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await handlePicked(newItem) }
        }
    }

    @ViewBuilder
    private func thumbnail(_ entry: JournalEntry) -> some View {
        if let data = try? Data(contentsOf: entry.url), let ui = UIImage(data: data) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            Color.gray.opacity(0.2)
        }
    }

    private func reload() {
        entries = PlantJournalStore.shared.photos(for: myPlant.plantId)
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { PlantJournalStore.shared.deletePhoto(entries[i]) }
        reload()
        dataLoader.recomputeHealth(for: myPlant.plantId)
    }

    private func handlePicked(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        _ = PlantJournalStore.shared.addPhoto(image, for: myPlant.plantId)
        await MainActor.run {
            pickerItem = nil
            reload()
            dataLoader.recomputeHealth(for: myPlant.plantId)
        }
    }

    private func makeGIF() async {
        isGenerating = true
        let url = await PlantJournalStore.shared.generateGIF(for: myPlant.plantId)
        await MainActor.run {
            gifURL = url
            isGenerating = false
        }
    }
}
