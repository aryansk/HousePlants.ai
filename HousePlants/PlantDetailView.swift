import SwiftUI

struct PlantDetailView: View {
    let plant: Plant
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCareInfo: (String, String, String, Color)? = nil
    @EnvironmentObject var dataLoader: DataLoader
    
    // Tools states
    @State private var showWaterCalculator = false
    @State private var showSoilBuilder = false
    @State private var showFertilizerCalculator = false
    @State private var showOriginCountries = false
    
    var isInJungle: Bool {

        guard let profile = dataLoader.userProfile else { return false }
        return profile.myJungle.contains(where: { $0.plantId == plant.id })
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Standard App Header
                ClaudeHeader(
                    title: plant.commonName,
                    subtitle: plant.botanicalName,
                    trailingActions: AnyView(favoriteButton),
                    showBackButton: true
                )
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                        // Card Layout Header
                        headerImage
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // Info & Badges Section
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ClaudeBadge(text: plant.careGuide.difficulty, icon: "gauge.medium", color: .green, isGlassy: false)
                                    if !plant.toxicity.isPetSafe {
                                        ClaudeBadge(text: "Toxic", icon: "exclamationmark.triangle.fill", color: .red, isGlassy: false)
                                    } else {
                                        ClaudeBadge(text: "Pet Safe", icon: "pawprint.fill", color: .blue, isGlassy: false)
                                    }
                                    
                                    Button(action: {
                                        if plant.origin.countries != nil {
                                            HapticManager.shared.playImpact(style: .light)
                                            showOriginCountries = true
                                        }
                                    }) {
                                        ClaudeBadge(text: plant.origin.region, icon: "mappin.and.ellipse", color: .orange, isGlassy: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 8)
                            
                            // Description Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("About")
                                    .font(.claudeSerif(size: 22, weight: .bold))
                                    .foregroundStyle(Color.claudePrimaryText)
                                
                                Text(plant.description)
                                    .font(.claudeSans(size: 16))
                                    .foregroundStyle(Color.claudeSecondaryText)
                                    .lineSpacing(6)
                            }
                            
                            Divider().background(Color.claudeBorder)
                            
                            // Care Guide Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Care Essentials")
                                    .font(.claudeSerif(size: 22, weight: .bold))
                                    .foregroundStyle(Color.claudePrimaryText)
                                
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                                    CareItem(icon: "sun.max.fill", title: "Light", value: plant.careGuide.light, color: .orange) {
                                        selectedCareInfo = ("Light Requirements", plant.careGuide.light, "sun.max.fill", .orange)
                                    }
                                    CareItem(icon: "drop.fill", title: "Water", value: plant.careGuide.water, color: .blue) {
                                        selectedCareInfo = ("Watering Schedule", plant.careGuide.water, "drop.fill", .blue)
                                    }
                                    CareItem(icon: "thermometer.medium", title: "Temperature", value: plant.careGuide.temperatureRange, color: .red) {
                                        selectedCareInfo = ("Temperature", plant.careGuide.temperatureRange, "thermometer.medium", .red)
                                    }
                                    CareItem(icon: "humidity.fill", title: "Humidity", value: plant.careGuide.humidity, color: .green) {
                                        selectedCareInfo = ("Humidity Levels", plant.careGuide.humidity, "humidity.fill", .green)
                                    }
                                    CareItem(icon: "leaf.fill", title: "Soil", value: plant.careGuide.soil, color: .brown) {
                                        selectedCareInfo = ("Soil & Potting", plant.careGuide.soil, "leaf.fill", .brown)
                                    }
                                    CareItem(icon: "sparkles", title: "Difficulty", value: plant.careGuide.difficulty, color: .purple) {
                                        selectedCareInfo = ("Care Level", plant.careGuide.difficulty, "sparkles", .purple)
                                    }
                                }
                            }
                            .padding(.bottom, 4)
                            
                            // Origin Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Origin & Heritage")
                                    .font(.claudeSerif(size: 22, weight: .bold))
                                    .foregroundStyle(Color.claudePrimaryText)
                                
                                Button(action: {
                                    if plant.origin.countries != nil {
                                        HapticManager.shared.playImpact(style: .medium)
                                        showOriginCountries = true
                                    }
                                }) {
                                    HStack(spacing: 20) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange.opacity(0.1))
                                                .frame(width: 60, height: 60)
                                            Image(systemName: "globe.americas.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(.orange)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Native Region")
                                                .font(.claudeSans(size: 14, weight: .bold))
                                                .foregroundStyle(.secondary)
                                                .textCase(.uppercase)
                                            Text(plant.origin.region)
                                                .font(.claudeSans(size: 18, weight: .medium))
                                                .foregroundStyle(Color.claudePrimaryText)
                                            
                                            if let countries = plant.origin.countries {
                                                Text("\(countries.count) Countries Identified")
                                                    .font(.claudeSans(size: 12))
                                                    .foregroundStyle(.orange)
                                                    .padding(.top, 2)
                                            }
                                        }
                                        Spacer()
                                        
                                        if plant.origin.countries != nil {
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(Color.orange.opacity(0.3))
                                        }
                                    }
                                    .padding(20)
                                    .background(Color.claudeSecondaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                                }
                                .buttonStyle(InteractiveCardButtonStyle())
                            }
                            .padding(.bottom, 4)
                            
                            // Botanist Quote Section
                            if let quote = plant.botanistQuote {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "quote.opening")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundStyle(Color.claudeAccent.opacity(0.3))
                                        
                                        Text("Botanist's Journal")
                                            .font(.claudeSerif(size: 22, weight: .bold))
                                            .foregroundStyle(Color.claudePrimaryText)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(quote.quote)
                                            .font(.claudeSerif(size: 18))
                                            .italic()
                                            .foregroundStyle(Color.claudePrimaryText)
                                            .lineSpacing(6)
                                        
                                        HStack {
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("— \(quote.botanist)")
                                                    .font(.claudeSans(size: 14, weight: .bold))
                                                    .foregroundStyle(Color.claudeAccent)
                                                Text("Historical Registry")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .textCase(.uppercase)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(24)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        ZStack {
                                            Color.claudeAccent.opacity(0.03)
                                            Image(systemName: "leaf.fill")
                                                .font(.system(size: 120))
                                                .foregroundStyle(Color.claudeAccent.opacity(0.02))
                                                .offset(x: 120, y: 40)
                                        }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 28))
                                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.claudeAccent.opacity(0.1), lineWidth: 1))
                                }
                                .padding(.bottom, 4)
                            }
    
                            Divider().background(Color.claudeBorder)
    
                            // Toxicity Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Toxicity & Safety")
                                    .font(.claudeSerif(size: 22, weight: .bold))
                                    .foregroundStyle(Color.claudePrimaryText)
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 12) {
                                        Image(systemName: plant.toxicity.isPetSafe ? "pawprint.fill" : "exclamationmark.triangle.fill")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(plant.toxicity.isPetSafe ? .blue : .red)
                                        
                                        Text(plant.toxicity.isPetSafe ? "Safe for Pets" : "Toxic to Pets")
                                            .font(.claudeSans(size: 18, weight: .bold))
                                            .foregroundStyle(plant.toxicity.isPetSafe ? .blue : .red)
                                    }
                                    
                                    Text(plant.toxicity.warning)
                                        .font(.claudeSans(size: 15))
                                        .foregroundStyle(Color.claudeSecondaryText)
                                        .lineSpacing(4)
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(plant.toxicity.isPetSafe ? Color.blue.opacity(0.05) : Color.red.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(plant.toxicity.isPetSafe ? Color.blue.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 1))
                            }
                            .padding(.bottom, 4)
                            
                            // Propagation Section
                            Divider().background(Color.claudeBorder)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Propagation")
                                    .font(.claudeSerif(size: 22, weight: .bold))
                                    .foregroundStyle(Color.claudePrimaryText)
                                
                                let propagation = plant.effectivePropagation
                                VStack(alignment: .leading, spacing: 20) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Methods")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.secondary)
                                            Text(propagation.methods.joined(separator: ", "))
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        Spacer()
                                        Badge(text: propagation.difficulty, icon: "target", color: .purple)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(Array(propagation.instructions.enumerated()), id: \.offset) { index, instruction in
                                            HStack(alignment: .top, spacing: 12) {
                                                Text("\(index + 1)")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                    .frame(width: 22, height: 22)
                                                    .background(Circle().fill(Color.claudeAccent))
                                                
                                                Text(instruction)
                                                    .font(.subheadline)
                                                    .foregroundStyle(Color.claudeSecondaryText)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    }
                                }
                                .padding(20)
                                .background(Color.claudeSecondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                            }
                            .padding(.bottom, 4)
                            
                            // Skincare Section
                            if let skincare = plant.skincarePotential, skincare.enabled {
                                Divider().background(Color.claudeBorder)
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Skincare Benefits")
                                        .font(.claudeSerif(size: 22, weight: .bold))
                                        .foregroundStyle(Color.claudePrimaryText)
                                    
                                    VStack(alignment: .leading, spacing: 20) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(skincare.benefits)
                                                .font(.claudeSans(size: 16))
                                                .foregroundStyle(Color.claudePrimaryText)
                                            
                                            if let categories = skincare.categories {
                                                HStack(spacing: 8) {
                                                    ForEach(categories, id: \.self) { cat in
                                                        Text(cat)
                                                            .font(.system(size: 10, weight: .bold))
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 4)
                                                            .background(Color.purple.opacity(0.1))
                                                            .foregroundStyle(.purple)
                                                            .clipShape(Capsule())
                                                    }
                                                }
                                            }
                                        }
                                        
                                        Divider()
                                        
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Image(systemName: "wand.and.stars")
                                                    .foregroundStyle(.purple)
                                                Text("DIY Beauty Recipe")
                                                    .font(.claudeSerif(size: 18, weight: .bold))
                                                    .foregroundStyle(.purple)
                                            }
                                            
                                            Text(skincare.diyRecipe)
                                                .font(.claudeSans(size: 15))
                                                .italic()
                                                .foregroundStyle(Color.claudeSecondaryText)
                                            
                                            if let ingredients = skincare.ingredients {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("Ingredients")
                                                        .font(.claudeSans(size: 14, weight: .bold))
                                                        .foregroundStyle(.secondary)
                                                    
                                                    ForEach(ingredients, id: \.self) { ing in
                                                        HStack(spacing: 8) {
                                                            Circle().fill(.purple).frame(width: 4, height: 4)
                                                            Text("**\(ing.amount)** \(ing.name)")
                                                                .font(.claudeSans(size: 14))
                                                            if let purpose = ing.purpose {
                                                                Text("— \(purpose)")
                                                                    .font(.claudeSans(size: 12))
                                                                    .foregroundStyle(.secondary)
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(.top, 4)
                                            }
                                            
                                            if let steps = skincare.instructions {
                                                VStack(alignment: .leading, spacing: 10) {
                                                    Text("Steps")
                                                        .font(.claudeSans(size: 14, weight: .bold))
                                                        .foregroundStyle(.secondary)
                                                    
                                                    ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                                                        HStack(alignment: .top, spacing: 10) {
                                                            Text("\(i + 1)")
                                                                .font(.system(size: 10, weight: .bold))
                                                                .foregroundStyle(.white)
                                                                .frame(width: 18, height: 18)
                                                                .background(Circle().fill(.purple))
                                                            Text(step)
                                                                .font(.claudeSans(size: 14))
                                                                .foregroundStyle(Color.claudeSecondaryText)
                                                        }
                                                    }
                                                }
                                                .padding(.top, 4)
                                            }
                                        }
                                    }
                                    .padding(24)
                                    .background(Color.purple.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 28))
                                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.purple.opacity(0.1), lineWidth: 1))
                                }
                                .padding(.bottom, 4)
                            }
    
                            // Smart Care Tools Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Smart Care Tools")
                                    .font(.claudeSerif(size: 22, weight: .bold))
                                    .foregroundStyle(Color.claudePrimaryText)
                                
                                VStack(spacing: 12) {
                                    ToolLinkRow(title: "Hydration Calculator", subtitle: "Personalized watering schedule", icon: "drop.fill", color: .blue) {
                                        showWaterCalculator = true
                                    }
                                    ToolLinkRow(title: "Soil Mix Architect", subtitle: "Custom substrate blueprints", icon: "leaf.fill", color: .brown) {
                                        showSoilBuilder = true
                                    }
                                    ToolLinkRow(title: "Nutrition Optimizer", subtitle: "Balanced fertilization guide", icon: "sparkles", color: .purple) {
                                        showFertilizerCalculator = true
                                    }
                                }
                            }
    
                            .padding(.bottom, 10)
                        }
                        .padding(20)
                        .padding(.bottom, 100)
                        }
                        .frame(width: geometry.size.width)
                    }
                }
                .coordinateSpace(name: "scroll")
            }
            
            // Bottom Action Bar
            VStack {
                Spacer()
                addToJungleButton
            }
        }
        .background(Color.claudeBackground)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.visible, for: .tabBar)

        .sheet(item: Binding(
            get: { selectedCareInfo.map { CareDetail(id: $0.0, info: $0.1, icon: $0.2, color: $0.3) } },
            set: { _ in selectedCareInfo = nil }
        )) { detail in
            CareDetailView(detail: detail)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showWaterCalculator) {
            WaterCalculatorView()
        }
        .sheet(isPresented: $showSoilBuilder) {
            SoilMixBuilderView()
        }
        .sheet(isPresented: $showFertilizerCalculator) {
            FertilizerCalculatorView()
        }
        .sheet(isPresented: $showOriginCountries) {
            if let countries = plant.origin.countries {
                OriginCountriesView(region: plant.origin.region, countries: countries)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    
    private var favoriteButton: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .medium)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                dataLoader.toggleFavorite(plantId: plant.id)
            }
        }) {
            let isFav = dataLoader.isFavorite(plantId: plant.id)
            Image(systemName: isFav ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isFav ? .red : Color.claudeAccent)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.claudeSecondaryBackground))
                .shadow(color: Color.primary.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(BubblingButtonStyle())
    }
    
    
    var headerImage: some View {
        ZStack(alignment: .bottom) {
            if plant.images.main.hasPrefix("http") {
                AsyncImage(url: URL(string: plant.images.main)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        Color.claudeSecondaryBackground
                            .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary.opacity(0.3)))
                    @unknown default: EmptyView()
                    }
                }
            } else {
                let imageName = plant.images.main.split(separator: "/").last?.split(separator: ".").first ?? ""
                Image(String(imageName))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            
            // Subtle gradient for depth
            LinearGradient(
                colors: [.clear, .black.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: 380)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    var addToJungleButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                dataLoader.toggleJungle(plant: plant)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: isInJungle ? "leaf.fill" : "plus")
                    .font(.system(size: 20, weight: .bold))
                Text(isInJungle ? "My Jungle Resident" : "Add to Jungle")
                    .font(.claudeSans(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                ZStack {
                    if isInJungle {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    } else {
                        Capsule()
                            .fill(Color.claudeAccent)
                            .shadow(color: Color.claudeAccent.opacity(0.3), radius: 15, y: 8)
                    }
                }
            )
            .foregroundStyle(isInJungle ? Color.claudePrimaryText : .white)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .buttonStyle(BubblingButtonStyle())
    }
}

// MARK: - Components

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
                        .font(.claudeSans(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                
                Text(value)
                    .font(.claudeSans(size: 14, weight: .medium))
                    .foregroundStyle(Color.claudePrimaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(Color.claudeSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.claudeBorder, lineWidth: 1)
            )
        }
        .buttonStyle(InteractiveCardButtonStyle())
    }
}

struct Badge: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        ClaudeBadge(text: text, icon: icon, color: color, isGlassy: false)
    }
}

struct ToolLinkRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.claudeSans(size: 16, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                    Text(subtitle)
                        .font(.claudeSans(size: 13))
                        .foregroundStyle(Color.claudeSecondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.claudeBorder)
            }
            .padding(16)
            .background(Color.claudeSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
        }
        .buttonStyle(InteractiveCardButtonStyle())
    }
}


// MARK: - Utilities

// Re-using CareDetail models from original file or defining them if needed

// Re-using CareDetail models from original file or defining them if needed
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
        case "Watering Schedule": return "Always check the top inch of soil with your finger before watering. If it's still damp, wait a few days."
        case "Temperature": return "Keep plants away from cold drafts and heating vents. Drastic temperature swings can cause leaf drop."
        case "Humidity Levels": return "Grouping plants together naturally increases local humidity. For tropical plants, a pebble tray works wonders!"
        case "Soil & Potting": return "Make sure your pot has drainage holes! Fresh soil every year helps replenish nutrients."
        case "Care Level": return "Don't be discouraged if a plant struggles. Observation is key—the plant will tell you what it needs."
        default: return "Consistent observation is the best care strategy."
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(detail.color.opacity(0.1))
                        .frame(width: 90, height: 90)
                    Image(systemName: detail.icon)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(detail.color)
                }
                .padding(.top, 40)
                
                VStack(spacing: 12) {
                    Text(detail.id)
                        .font(.claudeSerif(size: 28, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                    
                    Text("Specialist Insight")
                        .font(.claudeSans(size: 14, weight: .bold))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(detail.color)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Current Requirement", systemImage: "info.circle.fill")
                            .font(.claudeSans(size: 16, weight: .bold))
                            .foregroundStyle(detail.color)
                        
                        Text(detail.info)
                            .font(.claudeSans(size: 16))
                            .foregroundStyle(Color.claudePrimaryText.opacity(0.8))
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(detail.color.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Pro Plant Tip", systemImage: "lightbulb.fill")
                            .font(.claudeSans(size: 16, weight: .bold))
                            .foregroundStyle(.orange)
                        
                        Text(proTip)
                            .font(.claudeSans(size: 16))
                            .italic()
                            .foregroundStyle(Color.claudeSecondaryText)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                
                Button(action: { dismiss() }) {
                    Text("I've Got This")
                        .font(.claudeSans(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(detail.color)
                        .clipShape(Capsule())
                }
                .padding(.top, 12)
                }
                .frame(width: geometry.size.width)
                .padding(32)
            }
        }
        .background(Color.claudeBackground)
    }
}

struct OriginCountriesView: View {
    @Environment(\.dismiss) var dismiss
    let region: String
    let countries: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            // Modal Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Native Distribution")
                        .font(.claudeSerif(size: 24, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                    Text(region)
                        .font(.claudeSans(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary.opacity(0.3))
                }
            }
            .padding(24)
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 12) {
                    ForEach(countries, id: \.self) { country in
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(.orange)
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.orange.opacity(0.1)))
                            
                            Text(country)
                                .font(.claudeSans(size: 16, weight: .medium))
                                .foregroundStyle(Color.claudePrimaryText)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.claudeSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
                    }
                    }
                    .frame(width: geometry.size.width)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color.claudeBackground)
    }
}
