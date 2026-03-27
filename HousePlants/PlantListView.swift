import SwiftUI

struct PlantListView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @State private var selectedCategory: String?
    @Namespace private var categoryNamespace
    
    var filteredPlants: [Plant] {
        if let category = selectedCategory {
            return dataLoader.plants.filter { $0.categoryId == category }
        }
        return dataLoader.plants
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let errorMessage = dataLoader.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.red)
                        Text("Data Load Error")
                            .font(.headline)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Header Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "location.fill")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                            Text(dataLoader.userProfile?.locationSettings.city ?? "Unknown")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text("Discover")
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                        Text("Find your next houseplant")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(action: {
                                        // Location request
                                    }) {
                                        Image(systemName: "bell.fill")
                                            .font(.title3)
                                            .foregroundStyle(.green)
                                            .padding(10)
                                            .background(Circle().fill(Color(UIColor.secondarySystemGroupedBackground)))
                                            .shadow(color: Color.primary.opacity(0.05), radius: 4, x: 0, y: 2)
                                    }
                                    .buttonStyle(NotificationButtonStyle())
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }
                            
                            // Recommended Section
                            if let profile = dataLoader.userProfile {
                                let recommendedPlants = dataLoader.plants.filter { $0.careGuide.difficulty == profile.preferences.difficultyLevel }
                                if !recommendedPlants.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Recommended for You")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                Text("Based on your \(profile.preferences.difficultyLevel.lowercased()) level")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 20)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(recommendedPlants.prefix(5)) { plant in
                                                    NavigationLink(destination: PlantDetailView(plant: plant)) {
                                                        ModernPlantCard(plant: plant, isFeatured: true)
                                                            .frame(width: 220)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            }
                            
                            // Category Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ModernCategoryPill(title: "All", icon: "leaf", isSelected: selectedCategory == nil, namespace: categoryNamespace) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            selectedCategory = nil
                                        }
                                    }
                                    
                                    ForEach(dataLoader.categories) { category in
                                        ModernCategoryPill(title: category.name, icon: category.icon, isSelected: selectedCategory == category.id, namespace: categoryNamespace) {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                selectedCategory = category.id
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                            
                            // Explore All Section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Explore All Plants")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("\(filteredPlants.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(Color.green.opacity(0.15)))
                                }
                                .padding(.horizontal, 20)
                                
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                                    ForEach(filteredPlants) { plant in
                                        NavigationLink(destination: PlantDetailView(plant: plant)) {
                                            ModernPlantCard(plant: plant, isFeatured: false)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// Modern Plant Card
struct ModernPlantCard: View {
    let plant: Plant
    let isFeatured: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            GeometryReader { geometry in
                ZStack {
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
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color.green.opacity(0.2))
                                    .overlay(
                                        Image(systemName: "leaf.fill")
                                            .font(.largeTitle)
                                            .foregroundStyle(.green.opacity(0.5))
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else if let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first {
                        Image(String(imageName))
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Text(plant.commonName.prefix(1))
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                    }
                }
            }
            .frame(height: isFeatured ? 180 : 140)
            .overlay(alignment: .topTrailing) {
                DifficultyBadge(difficulty: plant.careGuide.difficulty)
                    .padding(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(plant.commonName)
                    .font(isFeatured ? .headline : .subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                Text(plant.botanicalName)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: plant.toxicity.isPetSafe ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.caption2)
                        .foregroundStyle(plant.toxicity.isPetSafe ? .green : .orange)
                    Text(plant.toxicity.isPetSafe ? "Pet Safe" : "Keep Away from Pets")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.primary.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// Modern Category Pill
struct ModernCategoryPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    if icon.count == 1 {
                        Text(icon).font(.caption)
                    } else {
                        Image(systemName: icon).font(.caption)
                    }
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.green)
                        .matchedGeometryEffect(id: "pill_bg", in: namespace)
                } else {
                    Capsule()
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                }
            }
            .shadow(color: Color.primary.opacity(0.04), radius: 2, x: 0, y: 1)
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(BubblingButtonStyle())
    }
}

// Difficulty Badge
struct DifficultyBadge: View {
    let difficulty: String
    
    var color: Color {
        switch difficulty.lowercased() {
        case "very easy": return .green
        case "easy": return .mint
        case "medium": return .orange
        case "hard", "hard (indoors)": return .red
        default: return .blue
        }
    }
    
    var body: some View {
        Text(difficulty)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}


