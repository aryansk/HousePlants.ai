import SwiftUI

struct PlantDetailView: View {
    let plant: Plant
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image with Gradient Overlay
                ZStack(alignment: .bottomLeading) {
                    if plant.images.main.hasPrefix("http"), let url = URL(string: plant.images.main) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(ProgressView())
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.green.opacity(0.1))
                                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.green.opacity(0.3)))
                            @unknown default: EmptyView()
                            }
                        }
                    } else if let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first {
                        Image(String(imageName)).resizable().aspectRatio(contentMode: .fill)
                    }
                    
                    // Gradient shadow for visibility
                    LinearGradient(
                        colors: [.black.opacity(0.6), .clear],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plant.commonName)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                        Text(plant.botanicalName)
                            .font(.headline)
                            .italic()
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(24)
                }
                .frame(height: 350)
                .clipped()
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Badge(text: plant.careGuide.difficulty, color: .green)
                        if !plant.toxicity.isPetSafe {
                            Badge(text: "Toxic", color: .red)
                        } else {
                            Badge(text: "Pet Safe", color: .blue)
                        }
                        
                        Spacer()
                        
                        // Favorite Toggle
                        Button(action: {}) {
                            Image(systemName: "heart")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .padding(10)
                                .background(Circle().fill(Color.gray.opacity(0.1)))
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
                    
                    // Care Guide Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Care Enthusiasts' Guide")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            CareItem(icon: "sun.max.fill", title: "Light", value: plant.careGuide.light, color: .orange)
                            CareItem(icon: "drop.fill", title: "Water", value: plant.careGuide.water, color: .blue)
                            CareItem(icon: "thermometer.medium", title: "Temperature", value: plant.careGuide.temperatureRange, color: .red)
                            CareItem(icon: "humidity.fill", title: "Humidity", value: plant.careGuide.humidity, color: .green)
                        }
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
            HStack(spacing: 12) {
                Image(systemName: isInJungle ? "leaf.fill" : "plus.circle.fill")
                    .font(.title3)
                Text(isInJungle ? "In Your Jungle" : "Add to Jungle")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(isInJungle ? AnyShapeStyle(Color.gray.opacity(0.8)) : AnyShapeStyle(LinearGradient(colors: [.green, Color(hex: "43A047")], startPoint: .leading, endPoint: .trailing)))
                    .shadow(color: (isInJungle ? Color.clear : Color.green.opacity(0.4)), radius: 10, x: 0, y: 5)
            )
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .buttonStyle(BubblingButtonStyle())
    }
}

struct CareItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary.opacity(0.8))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120, alignment: .topLeading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.05), lineWidth: 1)
        )
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

