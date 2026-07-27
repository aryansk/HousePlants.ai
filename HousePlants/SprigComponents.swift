import SwiftUI

enum SprigMood {
    case curious
    case thirsty
    case proud
    case resting

    var accessibilityText: String {
        switch self {
        case .curious: return "curious"
        case .thirsty: return "ready to help with watering"
        case .proud: return "proud of your care"
        case .resting: return "resting"
        }
    }
}

/// Sprig is deliberately built from simple original shapes so the personality belongs to
/// HousePlants.ai's cut-paper world rather than copying Pool's mascot.
struct SprigView: View {
    let stage: SprigStage
    let mood: SprigMood
    var onTap: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    private var leafCount: Int {
        switch stage {
        case .seedling: return 1
        case .sprout: return 2
        case .leafy: return 3
        case .blooming: return 4
        }
    }

    var body: some View {
        let content = ZStack {
            Circle()
                .fill(IndieHousePalette.blue.opacity(0.14))
                .frame(width: 104, height: 104)
            Circle()
                .stroke(IndieHousePalette.blue.opacity(0.35), lineWidth: 1.5)
                .frame(width: 104, height: 104)

            VStack(spacing: 0) {
                ZStack {
                    ForEach(0..<leafCount, id: \.self) { index in
                        Ellipse()
                            .fill(index.isMultiple(of: 2) ? IndieHousePalette.green : IndieHousePalette.blue)
                            .frame(width: 25 + CGFloat(index * 2), height: 42)
                            .rotationEffect(.degrees(Double(index - 1) * 28))
                            .offset(x: CGFloat(index - 1) * 14, y: -CGFloat(index) * 4)
                    }
                }
                .frame(height: 48)

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(IndieHousePalette.orange)
                    .frame(width: 52, height: 32)
                    .overlay {
                        HStack(spacing: 9) {
                            Circle().fill(IndieHousePalette.ink).frame(width: 5, height: 5)
                            Circle().fill(IndieHousePalette.ink).frame(width: 5, height: 5)
                        }
                        .offset(y: -2)
                    }
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(IndieHousePalette.ink)
                            .frame(width: mood == .proud ? 18 : 10, height: 2)
                            .offset(y: -7)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(IndieHousePalette.ink, lineWidth: 1.5)
                    }
            }
            .offset(y: isFloating && !reduceMotion ? -3 : 0)
        }
        .frame(width: 116, height: 116)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sprig, \(stage.title) companion, \(mood.accessibilityText)")
        .accessibilityIdentifier("today.sprig")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }

        if let onTap {
            return AnyView(
                Button(action: onTap) {
                    content
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shows a short plant-care tip")
            )
        }
        return AnyView(content)
    }
}

struct CareRhythmPill: View {
    let rhythm: CareRhythmSummary

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 12, weight: .bold))
            Text("\(rhythm.activeDays)/\(rhythm.windowDays) care days")
                .font(.claudeSans(size: 12, weight: .bold))
        }
        .foregroundStyle(IndieHousePalette.ink)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(IndieHousePalette.yellow)
        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.2))
        .background(IndieHousePalette.ink.offset(x: 3, y: 3))
        .accessibilityIdentifier("today.careRhythm")
        .accessibilityLabel("Care rhythm, \(rhythm.activeDays) of \(rhythm.windowDays) days active")
    }
}

struct CareRhythmBadge: View {
    let rhythm: CareRhythmSummary

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(IndieHousePalette.green)
            Text("\(rhythm.activeDays)/7")
                .font(.claudeSans(size: 13, weight: .bold))
                .foregroundStyle(Color.claudePrimaryText)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(Capsule().fill(Color.claudeSecondaryBackground))
        .overlay(Capsule().stroke(IndieHousePalette.ink.opacity(0.45), lineWidth: 1))
        .accessibilityIdentifier("today.careRhythmBadge")
        .accessibilityLabel("Care rhythm, \(rhythm.activeDays) active days this week")
    }
}

struct TodayCareHero: View {
    @Environment(CareExperienceStore.self) private var careExperience

    let tasks: [Plant]
    let dataLoader: DataLoader
    let onWater: (Plant) -> Void
    let onViewAll: () -> Void
    let onShowRecap: () -> Void
    let onSprigTap: () -> Void

    private var primaryTask: Plant? { tasks.first }
    private var rhythm: CareRhythmSummary { careExperience.rhythm() }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    IndieCutLabel(text: "Today in your jungle", color: IndieHousePalette.green)
                    Text(primaryTask == nil ? "A happy little jungle" : "A little care goes a long way")
                        .font(.claudeSerif(size: 25, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                    Text(primaryTask == nil ? "Everything is watered and settled." : "Sprig found the next plant that needs you.")
                        .font(.claudeSans(size: 14, weight: .medium))
                        .foregroundStyle(Color.claudeSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                SprigView(
                    stage: careExperience.stage,
                    mood: primaryTask == nil ? .proud : .thirsty,
                    onTap: onSprigTap
                )
                .scaleEffect(0.78)
                .frame(width: 88, height: 88)
            }

            if let plant = primaryTask {
                focusedTaskCard(plant)
                HStack(spacing: 12) {
                    CareRhythmPill(rhythm: rhythm)
                    Spacer(minLength: 0)
                    if tasks.count > 1 {
                        Button("View all \(tasks.count) tasks", action: onViewAll)
                            .font(.claudeSans(size: 12, weight: .bold))
                            .foregroundStyle(Color.claudeAccent)
                            .accessibilityIdentifier("today.viewAllTasks")
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(IndieHousePalette.green)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("All caught up")
                            .font(.claudeSans(size: 16, weight: .bold))
                            .foregroundStyle(Color.claudePrimaryText)
                        Text("Your plants are happy today. Sprig is proud of you.")
                            .font(.claudeSans(size: 13))
                            .foregroundStyle(Color.claudeSecondaryText)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .indiePaperCard(fill: Color.claudeSecondaryBackground, shadow: IndieHousePalette.green, shadowOffset: 4)
                .accessibilityIdentifier("today.allCaughtUp")
                CareRhythmPill(rhythm: rhythm)
            }

            if careExperience.recapAvailable, careExperience.recap() != nil {
                Button(action: onShowRecap) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("See your Jungle Recap")
                            .font(.claudeSans(size: 13, weight: .bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(Color.claudePrimaryText)
                    .padding(13)
                    .background(IndieHousePalette.pink.opacity(0.35))
                    .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.2))
                }
                .buttonStyle(BubblingButtonStyle())
                .accessibilityIdentifier("today.recap")
            }
        }
        .padding(18)
        .indiePaperCard(fill: Color.claudeSecondaryBackground, border: IndieHousePalette.ink, shadow: IndieHousePalette.blue, rotation: -0.25, shadowOffset: 5)
        .padding(.horizontal, 20)
        .accessibilityIdentifier("today.hero")
    }

    private func focusedTaskCard(_ plant: Plant) -> some View {
        let myPlant = dataLoader.myJungleLookup[plant.id]
        let status = dataLoader.wateringStatusDisplay(for: myPlant)
        return HStack(spacing: 13) {
            PlantImage(plant: plant, showsProgress: false)
                .frame(width: 74, height: 74)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(IndieHousePalette.ink, lineWidth: 1.3))

            VStack(alignment: .leading, spacing: 5) {
                Text(myPlant?.nickname ?? plant.commonName)
                    .font(.claudeSans(size: 16, weight: .bold))
                    .foregroundStyle(Color.claudePrimaryText)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Image(systemName: "drop.fill")
                    Text(status.text)
                }
                .font(.claudeSans(size: 12, weight: .semibold))
                .foregroundStyle(status.color)
                Text("A drink will keep this one thriving.")
                    .font(.claudeSans(size: 12))
                    .foregroundStyle(Color.claudeSecondaryText)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Button(action: { onWater(plant) }) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(IndieHousePalette.blue))
                    .overlay(Circle().stroke(IndieHousePalette.ink, lineWidth: 1.3))
            }
            .buttonStyle(BubblingButtonStyle())
            .accessibilityIdentifier("today.primaryCareAction")
            .accessibilityLabel("Water \(myPlant?.nickname ?? plant.commonName)")
        }
        .padding(12)
        .background(Color.claudeBackground.opacity(0.55))
        .overlay(Rectangle().stroke(IndieHousePalette.ink.opacity(0.35), lineWidth: 1.2))
    }
}

struct JungleRecapView: View {
    @Environment(CareExperienceStore.self) private var careExperience
    @Environment(DataLoader.self) private var dataLoader
    @Environment(\.dismiss) private var dismiss

    private var recap: JungleRecap? { careExperience.recap() }
    private var primaryPlantName: String {
        guard let id = recap?.mostCaredPlantID else { return "your jungle" }
        return dataLoader.plant(for: id)?.commonName ?? "your jungle"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                if let recap {
                    ScrollView {
                        VStack(spacing: 16) {
                            RecapShareCard(recap: recap, plantName: primaryPlantName)
                                .padding(.horizontal, 20)

                            if let imageData = renderedPNG(for: recap) {
                                ShareLink(
                                    item: imageData,
                                    preview: SharePreview("Jungle Recap", image: Image(systemName: "leaf.fill"))
                                ) {
                                    Label("Share your recap", systemImage: "square.and.arrow.up")
                                        .font(.claudeSans(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 15)
                                        .background(Color.claudeAccent)
                                        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.4))
                                        .background(IndieHousePalette.ink.offset(x: 4, y: 4))
                                        .padding(.trailing, 4)
                                        .padding(.bottom, 4)
                                }
                                .buttonStyle(BubblingButtonStyle())
                                .padding(.horizontal, 24)
                                .accessibilityIdentifier("recap.share")
                            }
                        }
                        .padding(.vertical, 22)
                    }
                } else {
                    Text("Your first recap will bloom after you care for a plant.")
                        .font(.claudeSerif(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(32)
                }
            }
            .navigationTitle("Jungle Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { careExperience.markRecapSeen() }
        }
    }

    private func renderedPNG(for recap: JungleRecap) -> Data? {
        let renderer = ImageRenderer(content: RecapShareCard(recap: recap, plantName: primaryPlantName).frame(width: 390, height: 680))
        renderer.scale = 3
        return renderer.uiImage?.pngData()
    }
}

private struct RecapShareCard: View {
    let recap: JungleRecap
    let plantName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            IndieCutLabel(text: "Jungle recap", color: IndieHousePalette.yellow)
            Text("A week of showing up")
                .font(.claudeSerif(size: 32, weight: .bold))
                .foregroundStyle(Color.claudePrimaryText)
            Text(recap.weekLabel)
                .font(.claudeSans(size: 14, weight: .semibold))
                .foregroundStyle(Color.claudeSecondaryText)

            HStack(spacing: 10) {
                recapStat("\(recap.activeDays)", "active days", IndieHousePalette.green)
                recapStat("\(recap.actionCount)", "care actions", IndieHousePalette.blue)
                recapStat("\(recap.plantsCaredFor)", "plants", IndieHousePalette.pink)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Sprig is now \(recap.stage.title.lowercased()).")
                    .font(.claudeSerif(size: 19, weight: .bold))
                Text("You gave \(plantName) the most attention this week.")
                    .font(.claudeSans(size: 14))
                    .foregroundStyle(Color.claudeSecondaryText)
            }
            SprigView(stage: recap.stage, mood: .proud)
                .frame(maxWidth: .infinity)
        }
        .padding(22)
        .background(Color.claudeSecondaryBackground)
        .indiePaperCard(fill: Color.claudeSecondaryBackground, shadow: IndieHousePalette.blue, rotation: -0.5, shadowOffset: 5)
        .accessibilityIdentifier("recap.card")
    }

    private func recapStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.claudeSerif(size: 25, weight: .bold))
            Text(label)
                .font(.claudeSans(size: 10, weight: .bold))
                .foregroundStyle(Color.claudeSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.24))
        .overlay(Rectangle().stroke(IndieHousePalette.ink.opacity(0.4), lineWidth: 1))
    }
}
