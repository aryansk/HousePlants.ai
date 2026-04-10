import SwiftUI

// MARK: - Enhanced Plant Card (Grid View)
struct EnhancedPlantCard: View {
    let plant: Plant
    @EnvironmentObject var dataLoader: DataLoader
    @State private var showCareSheet = false
    
    var myPlant: MyPlant? {
        dataLoader.myJungleLookup[plant.id]
    }
    
    var wateringStatus: (text: String, color: Color, icon: String) {
        guard let myPlant = myPlant else {
            return ("Unknown", .gray, "drop.fill")
        }
        
        if let daysUntil = dataLoader.daysUntilWatering(myPlant: myPlant) {
            if daysUntil < 0 {
                return ("Overdue!", .red, "exclamationmark.triangle.fill")
            } else if daysUntil == 0 {
                return ("Water today", .orange, "drop.fill")
            } else if daysUntil <= 2 {
                return ("In \(daysUntil)d", .blue, "drop.fill")
            } else {
                return ("\(daysUntil) days", .green, "checkmark.circle.fill")
            }
        } else {
            return ("Not set", .gray, "drop.fill")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Plant Image
            ZStack(alignment: .topTrailing) {
                GeometryReader { geo in
                    Group {
                        if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Color.green.opacity(0.1)
                                        .overlay(Image(systemName: "photo").foregroundStyle(.green.opacity(0.3)))
                                case .empty:
                                    Rectangle().fill(Color.gray.opacity(0.1)).overlay(ProgressView())
                                @unknown default: EmptyView()
                                }
                            }
                        } else {
                            let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first ?? ""
                            Image(String(imageName))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(height: 160)
                .clipped()
                
                // Health indicator badge
                if let health = myPlant?.healthScore {
                    HealthRing(health: health)
                        .frame(width: 34, height: 34)
                        .padding(10)
                        .background(Circle().fill(Color.claudeBackground.opacity(0.6)).blur(radius: 4))
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            VStack(alignment: .leading, spacing: 12) {
                // Plant name
                Text(plant.commonName)
                    .font(.claudeSerif(size: 18, weight: .bold))
                    .lineLimit(1)
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
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dataLoader.waterPlant(plantId: plant.id)
                    }
                }) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 12))
                        Text("Water")
                            .font(.claudeSans(size: 13, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(wateringStatus.color.opacity(0.12))
                    )
                    .foregroundStyle(wateringStatus.color)
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
            Button(action: { showCareSheet = true }) {
                Label("Manage Plant", systemImage: "slider.horizontal.3")
            }
            Button(action: { dataLoader.waterPlant(plantId: plant.id) }) {
                Label("Water Plant", systemImage: "drop.fill")
            }
        }
        .sheet(isPresented: $showCareSheet) {
            PlantCareSheet(plant: plant)
                .environmentObject(dataLoader)
        }
    }
}

// MARK: - Enhanced List Row
struct EnhancedJungleListRow: View {
    let plant: Plant
    @EnvironmentObject var dataLoader: DataLoader
    
    var myPlant: MyPlant? {
        dataLoader.myJungleLookup[plant.id]
    }
    
    var wateringStatus: (text: String, color: Color) {
        guard let myPlant = myPlant else {
            return ("Unknown", .gray)
        }
        
        if let daysUntil = dataLoader.daysUntilWatering(myPlant: myPlant) {
            if daysUntil < 0 {
                return ("Overdue!", .red)
            } else if daysUntil == 0 {
                return ("Water today", .orange)
            } else if daysUntil <= 2 {
                return ("In \(daysUntil)d", .blue)
            } else {
                return ("\(daysUntil) days", .green)
            }
        } else {
            return ("Not set", .gray)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray.opacity(0.1)
                            }
                        }
                    } else {
                        let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first ?? ""
                        Image(String(imageName))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
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
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.claudeBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 3)
    }
}

struct HealthRing: View {
    let health: Int
    
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
                .trim(from: 0, to: CGFloat(health) / 100.0)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(health)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .background(Circle().fill(Color.claudeBackground.opacity(0.8)))
    }
}

// MARK: - Selection Card
struct PlantSelectionCard: View {
    let plant: Plant
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    GeometryReader { geo in
                        Group {
                            if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Color.gray.opacity(0.1)
                                    }
                                }
                            } else {
                                let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first ?? ""
                                Image(String(imageName))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .frame(height: 150)
                    .clipped()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.claudeAccent : .secondary.opacity(0.5))
                        .padding(10)
                        .background(Circle().fill(Color.claudeBackground).blur(radius: 2))
                        .padding(8)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                Text(plant.commonName)
                    .font(.claudeSerif(size: 17, weight: .bold))
                    .lineLimit(1)
                    .padding(14)
                    .foregroundStyle(Color.claudePrimaryText)
            }
            .background(Color.claudeSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? Color.claudeAccent : Color.claudeBorder, lineWidth: 2)
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
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Image
                ZStack {
                    Group {
                        if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Color.gray.opacity(0.1)
                                }
                            }
                        } else {
                            let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first ?? ""
                            Image(String(imageName))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: 70, height: 70)
                    .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.commonName)
                        .font(.claudeSerif(size: 19, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                    Text(plant.botanicalName)
                        .font(.claudeSans(size: 13))
                        .foregroundStyle(Color.claudeSecondaryText)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.claudeAccent : .secondary.opacity(0.5))
                    .font(.title2)
            }
            .padding(14)
            .background(Color.claudeSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? Color.claudeAccent : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.04 : 0.02), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(BubblingButtonStyle())
    }
}

