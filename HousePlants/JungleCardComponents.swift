import SwiftUI

// MARK: - Enhanced Plant Card (Grid View)
struct EnhancedPlantCard: View {
    let plant: Plant
    @Environment(DataLoader.self) var dataLoader
    @State private var justWatered = false
    @State private var celebrating = false
    @State private var rippling = false

    var myPlant: MyPlant? {
        dataLoader.myJungleLookup[plant.id]
    }

    var wateringStatus: WateringStatusDisplay {
        dataLoader.wateringStatusDisplay(for: myPlant)
    }

    /// A plant that has slipped past its watering date gets a slow pulse on its status
    /// icon — enough peripheral movement to draw the eye while scrolling, not enough
    /// to be distracting when several cards are overdue at once.
    private var needsAttention: Bool {
        guard let myPlant, let days = dataLoader.daysUntilWatering(myPlant: myPlant) else { return false }
        return days <= 0
    }

    /// The user's own name for the plant leads; the species name becomes the byline.
    private var displayName: String {
        let nickname = myPlant?.nickname ?? ""
        return nickname.isEmpty ? plant.commonName : nickname
    }

    private var showsSpeciesByline: Bool {
        displayName != plant.commonName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Plant Image
            ZStack(alignment: .topTrailing) {
                GeometryReader { geo in
                    PlantImage(plant: plant)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(height: 160)
                .clipped()

                // Bottom gradient for depth
                LinearGradient(
                    gradient: Gradient(colors: [.clear, Color.black.opacity(0.28)]),
                    startPoint: UnitPoint(x: 0.5, y: 0.45),
                    endPoint: .bottom
                )
                .frame(height: 160)
                .allowsHitTesting(false)

                // Health indicator badge
                if let health = myPlant?.healthScore {
                    HealthRing(health: health)
                        .frame(width: 34, height: 34)
                        .padding(10)
                        .background(Circle().fill(Color.claudeBackground.opacity(0.55)).blur(radius: 3))
                        .padding(8)
                }

                // Repot soon badge
                if let myPlant,
                   let days = dataLoader.daysUntilRepot(myPlant: myPlant),
                   days <= 30 {
                    HStack(spacing: 4) {
                        Image(systemName: days <= 0 ? "exclamationmark.triangle.fill" : "arrow.up.left.and.arrow.down.right.circle.fill")
                        Text(days <= 0 ? "Repot" : "Repot \(days)d")
                    }
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.thinMaterial))
                    .foregroundStyle(days <= 0 ? Color.red : Color.brown)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(IndieHousePalette.ink).frame(height: 1.4)
            }

            VStack(alignment: .leading, spacing: 12) {
                // Plant name (nickname first, species as byline)
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.claudeSerif(size: 18, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(Color.claudePrimaryText)

                    if showsSpeciesByline {
                        Text(plant.commonName)
                            .font(.claudeSans(size: 11, weight: .medium))
                            .foregroundStyle(Color.claudeSecondaryText)
                            .lineLimit(1)
                    }
                }

                // Watering status
                HStack(spacing: 6) {
                    Image(systemName: wateringStatus.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(wateringStatus.color)
                        .breathing(needsAttention && !justWatered, range: 1.0...1.22)
                    Text(wateringStatus.text)
                        .font(.claudeSans(size: 12, weight: .bold))
                        .foregroundStyle(wateringStatus.color)
                        .textCase(.uppercase)
                        .contentTransition(.numericText())
                }
                .motion(Motion.snappy, value: wateringStatus.text)

                // Quick water button
                Button(action: {
                    HapticManager.shared.playImpact(style: .medium)
                    withMotion(Motion.playful) {
                        dataLoader.waterPlant(plantId: plant.id)
                        justWatered = true
                    }
                    celebrating = true
                    rippling = true
                    withMotion(Motion.gentle, after: 1.5) { justWatered = false }
                }) {
                    HStack {
                        Image(systemName: justWatered ? "checkmark" : "drop.fill")
                            .font(.system(size: 12, weight: .bold))
                            .contentTransition(.symbolEffect(.replace))
                            // The droplet tips over and swells the instant it's tapped, so the
                            // button feels like it poured something rather than just toggling.
                            .scaleEffect(justWatered ? 1.25 : 1)
                            .rotationEffect(.degrees(justWatered ? 0 : -8))
                        Text(justWatered ? "Watered!" : "Water")
                            .font(.claudeSans(size: 13, weight: .bold))
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(justWatered ? Color.blue.opacity(0.16) : wateringStatus.color.opacity(0.1))
                    .overlay(Rectangle().stroke(justWatered ? Color.blue : wateringStatus.color, lineWidth: 1.3))
                    .foregroundStyle(justWatered ? Color.blue : wateringStatus.color)
                    .motion(Motion.playful, value: justWatered)
                }
                .buttonStyle(BubblingButtonStyle())
                .paperBurst($celebrating, count: 12, radius: 54)
            }
            .padding(16)
        }
        .indiePaperCard(
            fill: Color.claudeSecondaryBackground,
            border: IndieHousePalette.ink,
            shadow: IndieHousePalette.ink,
            cornerRadius: 3,
            shadowOffset: 4
        )
        // Water visibly travels through the card from the button that poured it.
        // Applied to the finished card so the ripple distorts the artwork and text
        // together rather than one layer sliding under another.
        .waterRipple($rippling, origin: UnitPoint(x: 0.5, y: 0.86))
        .padding(.trailing, 4)
        .padding(.bottom, 4)
    }
}

// MARK: - Enhanced List Row
struct EnhancedJungleListRow: View {
    let plant: Plant
    @Environment(DataLoader.self) var dataLoader
    @State private var celebrating = false

    var myPlant: MyPlant? {
        dataLoader.myJungleLookup[plant.id]
    }

    var wateringStatus: WateringStatusDisplay {
        dataLoader.wateringStatusDisplay(for: myPlant)
    }

    private var isThirsty: Bool {
        guard let myPlant, let days = dataLoader.daysUntilWatering(myPlant: myPlant) else { return false }
        return days <= 0
    }

    private var displayName: String {
        let nickname = myPlant?.nickname ?? ""
        return nickname.isEmpty ? plant.commonName : nickname
    }

    var body: some View {
        HStack(spacing: 16) {
            // Image
            ZStack(alignment: .bottomTrailing) {
                PlantImage(plant: plant, showsProgress: false)
                    .frame(width: 80, height: 80)
                    .clipped()

                // Health indicator
                if let health = myPlant?.healthScore {
                    let healthColor: Color = health >= 80 ? .green : (health >= 60 ? .yellow : .red)
                    Circle()
                        .fill(healthColor)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.claudeBackground, lineWidth: 2))
                        .padding(4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous).stroke(IndieHousePalette.ink, lineWidth: 1.4))

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(displayName)
                        .font(.claudeSerif(size: 20, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(Color.claudePrimaryText)

                    if displayName != plant.commonName {
                        Text(plant.commonName)
                            .font(.claudeSans(size: 12, weight: .medium))
                            .foregroundStyle(Color.claudeSecondaryText)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(wateringStatus.color)
                        .breathing(isThirsty, range: 1.0...1.25)
                    Text(wateringStatus.text)
                        .font(.claudeSans(size: 13, weight: .medium))
                        .foregroundStyle(wateringStatus.color)
                        .contentTransition(.numericText())
                }
                .motion(Motion.snappy, value: wateringStatus.text)
            }

            Spacer()

            // Quick water button
            Button(action: {
                HapticManager.shared.playImpact(style: .light)
                withMotion(Motion.playful) {
                    dataLoader.waterPlant(plantId: plant.id)
                }
                celebrating = true
            }) {
                ZStack {
                    Circle()
                        .fill(wateringStatus.color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "drop.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(wateringStatus.color)
                }
                // The whole target re-colours and re-settles when the schedule changes,
                // so tapping visibly "resets" the row rather than silently updating it.
                .motion(Motion.playful, value: wateringStatus.color)
            }
            .buttonStyle(SquishButtonStyle(scale: 0.82, rotation: -8))
            .paperBurst($celebrating, count: 10, radius: 42)
        }
        .padding(14)
        .indiePaperCard(
            fill: Color.claudeSecondaryBackground,
            border: IndieHousePalette.ink,
            shadow: IndieHousePalette.ink,
            cornerRadius: 2,
            shadowOffset: 3
        )
        .overlay(alignment: .leading) {
            if let myPlant = myPlant, let daysUntil = dataLoader.daysUntilWatering(myPlant: myPlant), daysUntil <= 0 {
                Rectangle()
                    .fill(daysUntil < 0 ? IndieHousePalette.red : IndieHousePalette.orange)
                    .frame(width: 4)
                    .padding(.vertical, 8)
                    .padding(.leading, 2)
                    // Wipes down from the top when a plant becomes due and retracts the
                    // moment it's watered, so the urgency marker has a beginning and an end.
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .motion(Motion.paper, value: isThirsty)
        .padding(.trailing, 3)
        .padding(.bottom, 3)
    }
}

struct HealthRing: View {
    let health: Int
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var color: Color {
        if health >= 80 { return .green }
        else if health >= 60 { return .yellow }
        else { return .red }
    }

    /// Fraction the arc should be drawn to. Reduce Motion skips the sweep entirely and
    /// shows the final value, rather than animating a long 1.1s spring.
    private var trimEnd: CGFloat {
        (appeared || reduceMotion) ? CGFloat(health) / 100.0 : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: trimEnd)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .spring(response: 1.1, dampingFraction: 0.7).delay(0.15), value: appeared)
                // Later score changes re-sweep with a quicker curve than the first draw.
                .animation(reduceMotion ? Motion.reduced : Motion.gentle, value: health)

            Text("\(health)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .popOnChange(of: health)
                .opacity((appeared || reduceMotion) ? 1 : 0)
                .animation(reduceMotion ? nil : .easeIn(duration: 0.3).delay(0.4), value: appeared)
        }
        .background(Circle().fill(Color.claudeBackground.opacity(0.8)))
        .onAppear { appeared = true }
    }
}

// MARK: - Selection Card
struct PlantSelectionCard: View {
    let plant: Plant
    let isSelected: Bool
    let action: () -> Void
    @Environment(DataLoader.self) var dataLoader
    
    var myPlant: MyPlant? {
        dataLoader.myJungleLookup[plant.id]
    }
    
    var wateringStatus: WateringStatusDisplay {
        dataLoader.wateringStatusDisplay(for: myPlant)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    GeometryReader { geo in
                        PlantImage(plant: plant)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .frame(height: 160)
                    .clipped()

                    HStack {
                        if let health = myPlant?.healthScore {
                            HealthRing(health: health)
                                .frame(width: 34, height: 34)
                                .padding(10)
                                .background(Circle().fill(Color.claudeBackground.opacity(0.6)).blur(radius: 4))
                                .padding(8)
                        }
                        
                        Spacer()
                        
                        // Selection indicator
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.claudeAccent : .secondary.opacity(0.5))
                            .padding(10)
                            .background(Circle().fill(Color.claudeBackground).blur(radius: 2))
                            .padding(8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(plant.commonName)
                        .font(.claudeSerif(size: 18, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(Color.claudePrimaryText)
                        
                    // Watering status
                    HStack(spacing: 6) {
                        Image(systemName: wateringStatus.icon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(wateringStatus.color)
                        Text(wateringStatus.text)
                            .font(.claudeSans(size: 12, weight: .bold))
                            .foregroundStyle(wateringStatus.color)
                            .textCase(.uppercase)
                    }
                    
                    // Ghost button to match layout height
                    HStack {
                        Image(systemName: isSelected ? "checkmark" : "plus")
                            .font(.system(size: 12))
                        Text(isSelected ? "Selected" : "Select")
                            .font(.claudeSans(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.claudeAccent.opacity(0.12) : Color.gray.opacity(0.12))
                    )
                    .foregroundStyle(isSelected ? Color.claudeAccent : Color.gray)
                }
                .padding(16)
            }
            .background(Color.claudeSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(isSelected ? Color.claudeAccent : Color.claudeBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(BubblingButtonStyle())
    }
}

// MARK: - Selectable List Row
struct JungleListRowSelectable: View {
    let plant: Plant
    let isSelected: Bool
    let action: () -> Void
    @Environment(DataLoader.self) var dataLoader
    
    var myPlant: MyPlant? {
        dataLoader.myJungleLookup[plant.id]
    }
    
    var wateringStatus: WateringStatusDisplay {
        dataLoader.wateringStatusDisplay(for: myPlant)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Image
                ZStack(alignment: .bottomTrailing) {
                    PlantImage(plant: plant, showsProgress: false)
                        .frame(width: 80, height: 80)
                        .clipped()

                    // Health indicator
                    if let health = myPlant?.healthScore {
                        let healthColor: Color = health >= 80 ? .green : (health >= 60 ? .yellow : .red)
                        Circle()
                            .fill(healthColor)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.claudeBackground, lineWidth: 2))
                            .padding(4)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(plant.commonName)
                        .font(.claudeSerif(size: 20, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(Color.claudePrimaryText)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                            .foregroundStyle(wateringStatus.color)
                        Text(wateringStatus.text)
                            .font(.claudeSans(size: 13, weight: .medium))
                            .foregroundStyle(wateringStatus.color)
                    }
                }
                
                Spacer()
                
                // Selection indicator mimicking the water button size
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.claudeAccent.opacity(0.12) : Color.gray.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isSelected ? "checkmark" : "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isSelected ? Color.claudeAccent : .gray)
                }
            }
            .padding(14)
            .background(Color.claudeSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? Color.claudeAccent : Color.claudeBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.04 : 0.02), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(BubblingButtonStyle())
    }
}


#Preview {
    let dataLoader = DataLoader()
    ScrollView {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                ForEach(dataLoader.plants.prefix(4)) { plant in
                    EnhancedPlantCard(plant: plant)
                }
            }
            ForEach(dataLoader.plants.prefix(3)) { plant in
                EnhancedJungleListRow(plant: plant)
            }
        }
        .padding()
    }
    .environment(dataLoader)
    .background(Color.claudeBackground)
}

// MARK: - Care swipe actions

/// Water / fertilize / mist without leaving the collection.
///
/// These actions existed only in the "Care" menu, which acts on every plant at once —
/// there was no way to fertilize a single plant from this screen. Swipe actions were the
/// obvious home for them but required `List`, and this screen uses free-form lazy layouts
/// so the cut-paper cards can size themselves. iOS 27's `swipeActionsContainer` removes
/// that constraint.
///
/// On iOS 26 the swipe half is inert, so the same three commands are also exposed through
/// a context menu. That isn't only a fallback — swipe is faster once you know it's there,
/// long-press is how you find out — so both routes stay live on iOS 27 rather than the
/// menu being conditionally compiled away.
///
/// Full swipe is deliberately off: every one of these mutates care history, and an
/// accidental full-swipe fertilize is a silent data error the user won't notice.
struct CareSwipeActions<MenuItems: View>: ViewModifier {
    let plant: Plant
    let showToast: (MyJungleView.ActiveToast) -> Void
    /// Extra commands the host row wants in the same menu, so a row doesn't end up with
    /// two separate context menus fighting for the same long-press.
    @ViewBuilder var additionalMenuItems: MenuItems

    @Environment(DataLoader.self) private var dataLoader

    private func water() {
        HapticManager.shared.playImpact(style: .medium)
        withMotion(Motion.playful) {
            dataLoader.waterPlant(plantId: plant.id)
        }
        showToast(.watered)
    }

    private func feed() {
        HapticManager.shared.playImpact(style: .light)
        dataLoader.fertilizePlant(plantId: plant.id)
        showToast(.fertilized)
    }

    private func mist() {
        HapticManager.shared.playImpact(style: .light)
        dataLoader.mistPlant(plantId: plant.id)
        showToast(.misted)
    }

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button(action: water) {
                    Label("Water", systemImage: "drop.fill")
                }
                .tint(IndieHousePalette.blue)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(action: feed) {
                    Label("Feed", systemImage: "leaf.circle.fill")
                }
                .tint(IndieHousePalette.green)

                Button(action: mist) {
                    Label("Mist", systemImage: "humidity.fill")
                }
                .tint(IndieHousePalette.orange)
            }
            .contextMenu {
                additionalMenuItems
                Button(action: water) {
                    Label("Water Plant", systemImage: "drop.fill")
                }
                Button(action: feed) {
                    Label("Feed Plant", systemImage: "leaf.circle.fill")
                }
                Button(action: mist) {
                    Label("Mist Plant", systemImage: "humidity.fill")
                }
            }
    }
}

extension View {
    func careSwipeActions<MenuItems: View>(
        plant: Plant,
        showToast: @escaping (MyJungleView.ActiveToast) -> Void,
        @ViewBuilder additionalMenuItems: () -> MenuItems = { EmptyView() }
    ) -> some View {
        modifier(CareSwipeActions(
            plant: plant,
            showToast: showToast,
            additionalMenuItems: additionalMenuItems()
        ))
    }
}
