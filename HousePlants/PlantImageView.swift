import SwiftUI

// MARK: - Shared plant image

/// Single source of truth for rendering a plant's main image. Replaces the ~20-line
/// URL-vs-bundled-asset block that was copy-pasted across every card, row and detail header.
///
/// - Remote URLs go through `AsyncImage`, which reads/writes `URLCache.shared` (enlarged at
///   launch in `HousePlantsApp`) so scrolling past a card doesn't re-download.
/// - Everything else is treated as a bundled asset, resolved via `Plant.assetImageName`.
struct PlantImage: View {
    let plant: Plant
    var contentMode: ContentMode = .fill
    /// List rows use a plain fill; large cards/headers show a spinner while loading.
    var showsProgress: Bool = true

    var body: some View {
        Group {
            if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                AsyncImage(url: url, transaction: Transaction(animation: .easeIn(duration: 0.2))) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: contentMode)
                    case .failure:
                        placeholder(failed: true)
                    case .empty:
                        placeholder(failed: false)
                    @unknown default:
                        Color.claudeSecondaryBackground
                    }
                }
            } else {
                Image(plant.assetImageName)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(plant.commonName) plant"))
    }

    @ViewBuilder
    private func placeholder(failed: Bool) -> some View {
        ZStack {
            Color.green.opacity(0.08)
            if failed {
                Image(systemName: "photo")
                    .foregroundStyle(.green.opacity(0.3))
            } else if showsProgress {
                ProgressView()
            }
        }
    }
}

extension Plant {
    /// Bundled asset name derived from `images.main` (e.g. "images/p_015_main.jpg" → "p_015_main").
    var assetImageName: String {
        let file = images.main.split(separator: "/").last ?? Substring(images.main)
        return String(file.split(separator: ".").first ?? file)
    }
}
