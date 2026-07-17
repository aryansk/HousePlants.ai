import SwiftUI

// MARK: - Recommended Plant Card

struct RecommendedPlantCard: View {
    let plant: Plant
    let climateNote: String
    /// When `onAdd` is provided, the card shows a trailing add-to-jungle button.
    var isAdded: Bool = false
    var onAdd: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            // Plant image
            Image(plant.images.main)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(IndieHousePalette.ink, lineWidth: 1.4)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName)
                    .font(.subheadline.bold())
                    .foregroundColor(Color.claudePrimaryText)
                    .lineLimit(1)

                Text(plant.botanicalName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Difficulty badge
                    HStack(spacing: 3) {
                        Image(systemName: difficultyIcon(plant.careGuide.difficulty))
                            .font(.system(size: 8))
                        Text(plant.careGuide.difficulty)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(difficultyColor(plant.careGuide.difficulty).opacity(0.12))
                    .foregroundColor(difficultyColor(plant.careGuide.difficulty))
                    .clipShape(Capsule())

                    // Pet safe badge
                    if plant.toxicity.isPetSafe {
                        HStack(spacing: 2) {
                            Text("🐾")
                                .font(.system(size: 8))
                            Text("Pet Safe")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                    }
                }

                // Climate note
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 8))
                    Text(climateNote)
                        .font(.system(size: 10))
                }
                .foregroundColor(Color.claudeAccent)
            }

            Spacer()

            if let onAdd {
                Button(action: onAdd) {
                    Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(isAdded ? IndieHousePalette.green : Color.claudeAccent)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(BubblingButtonStyle())
                .accessibilityLabel(isAdded ? "\(plant.commonName) added to your jungle" : "Add \(plant.commonName) to your jungle")
            }
        }
        .padding(12)
        .indiePaperCard(
            fill: Color.claudeSecondaryBackground,
            border: IndieHousePalette.ink,
            shadow: IndieHousePalette.ink,
            cornerRadius: 2,
            shadowOffset: 3
        )
        .padding(.trailing, 4)
        .padding(.bottom, 4)
    }

    private func difficultyIcon(_ diff: String) -> String {
        let d = diff.lowercased()
        if d.contains("easy") || d.contains("beginner") { return "leaf" }
        if d.contains("medium") || d.contains("intermediate") { return "leaf.fill" }
        return "exclamationmark.triangle"
    }

    private func difficultyColor(_ diff: String) -> Color {
        let d = diff.lowercased()
        if d.contains("easy") || d.contains("beginner") { return Color(hex: "27AE60") }
        if d.contains("medium") || d.contains("intermediate") { return Color(hex: "F39C12") }
        return Color(hex: "E74C3C")
    }
}

extension Color {
    static let emerald = Color(hex: "059669")
}
