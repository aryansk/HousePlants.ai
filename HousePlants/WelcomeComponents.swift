import SwiftUI

// MARK: - Recommended Plant Card

struct RecommendedPlantCard: View {
    let plant: Plant
    let climateNote: String

    var body: some View {
        HStack(spacing: 14) {
            // Plant image
            Image(plant.images.main)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)

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
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.claudeSecondaryBackground)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
        )
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
