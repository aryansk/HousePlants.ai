import SwiftUI

// MARK: - Enhanced Plant Card (Grid View)
struct EnhancedPlantCard: View {
    let plant: Plant
    /// Provided by the parent list so the "Manage"/"Insights" sheets are presented once at the
    /// list level rather than one hidden `.sheet` per card.
    var onManage: (() -> Void)? = nil
    var onInsights: (() -> Void)? = nil
    @Environment(DataLoader.self) var dataLoader
    @State private var justWatered = false
    
    var myPlant: MyPlant? {
        dataLoader.myJungleLookup[plant.id]
    }
    
    var wateringStatus: WateringStatusDisplay {
        dataLoader.wateringStatusDisplay(for: myPlant)
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
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            VStack(alignment: .leading, spacing: 12) {
                // Plant name
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
                
                // Quick water button
                Button(action: {
                    HapticManager.shared.playImpact(style: .medium)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dataLoader.waterPlant(plantId: plant.id)
                        justWatered = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.4)) { justWatered = false }
                    }
                }) {
                    HStack {
                        Image(systemName: justWatered ? "checkmark" : "drop.fill")
                            .font(.system(size: 12, weight: .bold))
                            .contentTransition(.symbolEffect(.replace))
                        Text(justWatered ? "Watered!" : "Water")
                            .font(.claudeSans(size: 13, weight: .bold))
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(justWatered ? Color.blue.opacity(0.18) : wateringStatus.color.opacity(0.12))
                    )
                    .foregroundStyle(justWatered ? Color.blue : wateringStatus.color)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: justWatered)
                }
                .buttonStyle(BubblingButtonStyle())
            }
            .padding(16)
        }
        .background(Color.claudeSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.claudeBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
        .contextMenu {
            Button(action: { onManage?() }) {
                Label("Manage Plant", systemImage: "slider.horizontal.3")
            }
            Button(action: { onInsights?() }) {
                Label("Insights", systemImage: "chart.bar.doc.horizontal")
            }
            Button(action: { dataLoader.waterPlant(plantId: plant.id) }) {
                Label("Water Plant", systemImage: "drop.fill")
            }
        }
    }
}

// MARK: - Enhanced List Row
struct EnhancedJungleListRow: View {
    let plant: Plant
    @Environment(DataLoader.self) var dataLoader
    
    var myPlant: MyPlant? {
        dataLoader.myJungleLookup[plant.id]
    }
    
    var wateringStatus: WateringStatusDisplay {
        dataLoader.wateringStatusDisplay(for: myPlant)
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

            // Quick water button
            Button(action: {
                HapticManager.shared.playImpact(style: .light)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dataLoader.waterPlant(plantId: plant.id)
                }
            }) {
                ZStack {
                    Circle()
                        .fill(wateringStatus.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "drop.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(wateringStatus.color)
                }
            }
            .buttonStyle(WaterButtonStyle())
        }
        .padding(14)
        .background(Color.claudeSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .leading) {
            if let myPlant = myPlant, let daysUntil = dataLoader.daysUntilWatering(myPlant: myPlant), daysUntil <= 0 {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(daysUntil < 0 ? Color.red : Color.orange)
                    .frame(width: 4)
                    .padding(.vertical, 8)
                    .padding(.leading, 2)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.claudeBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 3)
    }
}

struct HealthRing: View {
    let health: Int
    @State private var appeared = false

    var color: Color {
        if health >= 80 { return .green }
        else if health >= 60 { return .yellow }
        else { return .red }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: appeared ? CGFloat(health) / 100.0 : 0)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.1, dampingFraction: 0.7).delay(0.15), value: appeared)

            Text("\(health)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.4), value: appeared)
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
