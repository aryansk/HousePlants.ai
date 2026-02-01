import SwiftUI

struct PlantDetailView: View {
    let plant: Plant
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image
                // Header Image
                if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 300)
                    .clipped()
                } else if let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first {
                    Image(String(imageName))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    // Title Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plant.commonName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(plant.botanicalName)
                            .font(.title3)
                            .italic()
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Badge(text: plant.careGuide.difficulty, color: .blue)
                            if !plant.toxicity.isPetSafe {
                                Badge(text: "Toxic to Pets", color: .red)
                            } else {
                                Badge(text: "Pet Safe", color: .green)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Description
                    Text("About")
                        .font(.headline)
                    Text(plant.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    // Care Guide
                    Text("Care Guide")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        CareItem(icon: "sun.max.fill", title: "Light", value: plant.careGuide.light)
                        CareItem(icon: "drop.fill", title: "Water", value: plant.careGuide.water)
                        CareItem(icon: "thermometer", title: "Temp", value: plant.careGuide.temperatureRange)
                        CareItem(icon: "humidity.fill", title: "Humidity", value: plant.careGuide.humidity)
                    }
                    
                    if let propagation = plant.propagation {
                        Divider()
                        Text("Propagation")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Difficulty:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Badge(text: propagation.difficulty, color: .green)
                            }
                            
                            Text("Methods: \(propagation.methods.joined(separator: ", "))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(propagation.instructions.enumerated()), id: \.offset) { index, instruction in
                                    HStack(alignment: .top) {
                                        Text("\(index + 1).")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.green)
                                        Text(instruction)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if let skincare = plant.skincarePotential, skincare.enabled {
                        Divider()
                        Text("Skincare Potential")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(skincare.benefits)
                                .font(.subheadline)
                            
                            Text("DIY Recipe:")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text(skincare.diyRecipe)
                                .font(.caption)
                                .italic()
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .padding(.bottom, 100)
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarBackButtonHidden(false)
        .overlay(alignment: .bottom) {
            addToJungleButton
        }
    }
    
    @EnvironmentObject var dataLoader: DataLoader
    
    var isInJungle: Bool {
        guard let profile = dataLoader.userProfile else { return false }
        return profile.myJungle.contains(where: { $0.plantId == plant.id })
    }
    
    var addToJungleButton: some View {
        Button(action: {
            dataLoader.toggleJungle(plant: plant)
        }) {
            HStack {
                Image(systemName: isInJungle ? "checkmark.circle.fill" : "plus.circle.fill")
                Text(isInJungle ? "In Your Jungle" : "Add to Jungle")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isInJungle ? Color.gray.opacity(0.9) : Color.green)
            .foregroundStyle(.white)
            .cornerRadius(12)
            .shadow(radius: 4)
            .padding()
        }
    }
}

struct CareItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.green)
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(8)
    }
}
