import SwiftUI

struct PlantDetailView: View {
    let plant: Plant
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCareInfo: (String, String, String, Color)? = nil
    
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
                                image.resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                            case .failure:
                                Rectangle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(maxWidth: .infinity)
                                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.green.opacity(0.3)))
                            @unknown default: EmptyView()
                            }
                        }
                    } else if let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first {
                        Image(String(imageName))
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Gradient shadow for visibility
                    LinearGradient(
                        colors: [.black.opacity(0.6), .clear],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plant.commonName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.7)
                            .lineLimit(2)
                        Text(plant.botanicalName)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
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
                                .background(Circle().fill(Color(UIColor.secondarySystemGroupedBackground)))
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
                            CareItem(icon: "sun.max.fill", title: "Light", value: plant.careGuide.light, color: .orange) {
                                selectedCareInfo = ("Light Requirements", plant.careGuide.light, "sun.max.fill", .orange)
                            }
                            CareItem(icon: "drop.fill", title: "Water", value: plant.careGuide.water, color: .blue) {
                                selectedCareInfo = ("Watering Schedule", plant.careGuide.water, "drop.fill", .blue)
                            }
                            CareItem(icon: "thermometer.medium", title: "Temperature", value: plant.careGuide.temperatureRange, color: .red) {
                                selectedCareInfo = ("Temperature Range", plant.careGuide.temperatureRange, "thermometer.medium", .red)
                            }
                            CareItem(icon: "humidity.fill", title: "Humidity", value: plant.careGuide.humidity, color: .green) {
                                selectedCareInfo = ("Humidity Levels", plant.careGuide.humidity, "humidity.fill", .green)
                            }
                            CareItem(icon: "leaf.fill", title: "Soil", value: plant.careGuide.soil, color: .brown) {
                                selectedCareInfo = ("Soil & Potting", plant.careGuide.soil, "leaf.fill", .brown)
                            }
                            CareItem(icon: "gauge.with.needle.fill", title: "Difficulty", value: plant.careGuide.difficulty, color: .purple) {
                                selectedCareInfo = ("Care Level", plant.careGuide.difficulty, "gauge.with.needle.fill", .purple)
                            }
                        }
                    }
                    .sheet(item: Binding(
                        get: { selectedCareInfo.map { CareDetail(id: $0.0, info: $0.1, icon: $0.2, color: $0.3) } },
                        set: { _ in selectedCareInfo = nil }
                    )) { detail in
                        CareDetailView(detail: detail)
                            .presentationDetents([.medium])
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: Color.primary.opacity(0.04), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(InteractiveCardButtonStyle())
    }
}

// Model for Detail Sheet
struct CareDetail: Identifiable {
    let id: String
    let info: String
    let icon: String
    let color: Color
}

struct CareDetailView: View {
    @Environment(\.dismiss) var dismiss
    let detail: CareDetail
    
    var proTip: String {
        switch detail.id {
        case "Light Requirements": return "Rotate your plant every two weeks to ensure even growth on all sides. Leaning plants usually mean they need more light!"
        case "Watering Schedule": return "Always check the top inch of soil with your finger before watering. If it's still damp, wait a few days to avoid root rot."
        case "Temperature Range": return "Keep plants away from cold drafts and heating vents. Drastic temperature swings can cause leaf drop."
        case "Humidity Levels": return "Grouping plants together naturally increases local humidity. For tropical plants, a pebbles tray with water works wonders!"
        case "Soil & Potting": return "Make sure your pot has drainage holes! Fresh soil every year helps replenish nutrients and prevents compacting."
        case "Care Level": return "Don't be discouraged if a plant struggles. Observation is key—the plant will usually 'tell' you what it needs through its leaves."
        default: return "Consistent observation is the best care strategy."
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(detail.color.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: detail.icon)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(detail.color)
                }
                .padding(.top, 30)
                
                VStack(spacing: 8) {
                    Text(detail.id)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Detailed Guide")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(detail.color)
                        .textCase(.uppercase)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Current Requirement", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundStyle(detail.color)
                    
                    Text(detail.info)
                        .font(.body)
                        .foregroundStyle(.primary.opacity(0.8))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(detail.color.opacity(0.05))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Pro Specialist Tip", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    
                    Text(proTip)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(12)
                }
                
                Button(action: { dismiss() }) {
                    Text("Got it, thanks!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(detail.color)
                        .cornerRadius(16)
                }
                .padding(.top, 10)
            }
            .padding(24)
        }
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

