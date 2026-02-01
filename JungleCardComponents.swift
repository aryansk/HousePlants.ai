import SwiftUI

// MARK: - Enhanced Plant Card (Grid View)
struct EnhancedPlantCard: View {
    let plant: Plant
    @EnvironmentObject var dataLoader: DataLoader
    @State private var showCareSheet = false
    
    var myPlant: MyPlant? {
        dataLoader.userProfile?.myJungle.first(where: { $0.plantId == plant.id })
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
    
    var healthColor: Color {
        let health = myPlant?.healthScore ?? 80
        if health >= 80 { return .green }
        else if health >= 60 { return .yellow }
        else { return .red }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Plant Image
            ZStack(alignment: .topTrailing) {
                if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color.gray.opacity(0.1)
                        }
                    }
                } else if let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first {
                    Image(String(imageName))
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.green.opacity(0.2)
                }
                
                // Health indicator badge
                if let health = myPlant?.healthScore {
                    Circle()
                        .fill(healthColor)
                        .frame(width: 12, height: 12)
                        .padding(8)
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 8) {
                // Plant name
                Text(plant.commonName)
                    .font(.headline)
                    .lineLimit(1)
                
                // Watering status
                HStack(spacing: 4) {
                    Image(systemName: wateringStatus.icon)
                        .font(.caption)
                        .foregroundStyle(wateringStatus.color)
                    Text(wateringStatus.text)
                        .font(.caption)
                        .foregroundStyle(wateringStatus.color)
                        .fontWeight(.medium)
                }
                
                // Quick water button
                Button(action: {
                    dataLoader.waterPlant(plantId: plant.id)
                }) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .font(.caption)
                        Text("Water")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
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
        dataLoader.userProfile?.myJungle.first(where: { $0.plantId == plant.id })
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
                if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color.gray.opacity(0.1)
                        }
                    }
                } else if let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first {
                    Image(String(imageName))
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.green.opacity(0.2)
                }
                
                // Health indicator
                if let health = myPlant?.healthScore {
                    let healthColor: Color = health >= 80 ? .green : (health >= 60 ? .yellow : .red)
                    Circle()
                        .fill(healthColor)
                        .frame(width: 10, height: 10)
                        .padding(4)
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(wateringStatus.color)
                    Text(wateringStatus.text)
                        .font(.caption)
                        .foregroundStyle(wateringStatus.color)
                }
            }
            
            Spacer()
            
            // Quick water button
            Button(action: {
                dataLoader.waterPlant(plantId: plant.id)
            }) {
                Image(systemName: "drop.fill")
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                    if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color.gray.opacity(0.1)
                            }
                        }
                    } else if let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first {
                        Image(String(imageName))
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.green.opacity(0.2)
                    }
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? .green : .white)
                        .padding(8)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                        .padding(8)
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(plant.commonName)
                    .font(.headline)
                    .lineLimit(1)
                    .padding(12)
            }
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
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
                    if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color.gray.opacity(0.1)
                            }
                        }
                    } else if let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first {
                        Image(String(imageName))
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.green.opacity(0.2)
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.commonName)
                        .font(.headline)
                    Text(plant.botanicalName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .green : .secondary)
                    .font(.title3)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}
