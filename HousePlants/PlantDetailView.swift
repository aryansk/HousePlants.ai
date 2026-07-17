import SwiftUI

struct PlantDetailView: View {
    let plant: Plant
    @State private var selectedCareInfo: (String, String, String, Color)? = nil
    @Environment(DataLoader.self) var dataLoader
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Tools states
    @State private var showWaterCalculator = false
    @State private var showSoilBuilder = false
    @State private var showFertilizerCalculator = false
    @State private var showOriginCountries = false
    @State private var showGrowthView = false
    @State private var showARPlacement = false
    @State private var showProUpgrade = false
    @ObservedObject private var proManager = ProManager.shared
    
    var isInJungle: Bool {
        guard let profile = dataLoader.userProfile else { return false }
        return profile.myJungle.contains(where: { $0.plantId == plant.id })
    }

    private var careColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    }

    private var heroHeight: CGFloat {
        horizontalSizeClass == .regular ? 380 : 290
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.claudeBackground.ignoresSafeArea()

            GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                        // Card Layout Header
                        headerImage
                        detailTitle
                        
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
                                
                                LazyVGrid(columns: careColumns, spacing: 14) {
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
                                    ToolLinkRow(
                                        title: "Growth Analytics",
                                        subtitle: proManager.isPro ? "Health trends & watering adherence" : "Pro — health trends & watering adherence",
                                        icon: "chart.xyaxis.line", color: .purple,
                                        badge: proManager.isPro ? nil : "PRO"
                                    ) {
                                        if proManager.isPro { showGrowthView = true } else { showProUpgrade = true }
                                    }
                                    if dataLoader.appData?.appConfig.features.arPlacement == true {
                                        ToolLinkRow(
                                            title: "AR Plant Placement",
                                            subtitle: proManager.isPro ? "Preview plants in your room" : "Pro — preview plants in your room",
                                            icon: "arkit", color: .teal,
                                            badge: proManager.isPro ? nil : "PRO"
                                        ) {
                                            if proManager.isPro { showARPlacement = true } else { showProUpgrade = true }
                                        }
                                    }
                                }
                            }
    
                            .padding(.bottom, 10)
                        }
                        .padding(20)
                        .padding(.bottom, 24)
                        }
                        .frame(width: geometry.size.width)
                    }
                }
                .coordinateSpace(name: "scroll")
        }
        .background(Color.claudeBackground)
        .navigationTitle(plant.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                favoriteButton
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            addToJungleButton
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) { Divider() }
        }

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
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
        .sheet(isPresented: $showGrowthView) {
            NavigationStack {
                PlantGrowthView(plant: plant)
                    .environment(dataLoader)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showGrowthView = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showARPlacement) {
            NavigationStack {
                ARPlantPlacementView(plant: plant)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showARPlacement = false }
                        }
                    }
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
                .foregroundStyle(isFav ? IndieHousePalette.ink : Color.claudePrimaryText)
                .frame(width: 44, height: 44)
                .background(isFav ? IndieHousePalette.pink : Color.claudeSecondaryBackground)
                .overlay(Rectangle().stroke(Color.claudeBorder, lineWidth: 1.5))
        }
        .buttonStyle(BubblingButtonStyle())
        .accessibilityLabel(dataLoader.isFavorite(plantId: plant.id) ? "Remove from favorites" : "Add to favorites")
    }

    private var detailTitle: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let category = dataLoader.categories.first(where: { $0.id == plant.categoryId }) {
                IndieCutLabel(text: category.name, color: IndieHousePalette.green)
                    .padding(.bottom, 4)
            }
            Text(plant.commonName)
                .font(.claudeSerif(size: 32, weight: .bold))
                .foregroundStyle(Color.claudePrimaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text(plant.botanicalName)
                .font(.claudeSans(size: 16, weight: .medium))
                .italic()
                .foregroundStyle(Color.claudeSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    var headerImage: some View {
        ZStack(alignment: .bottom) {
            PlantImage(plant: plant)

            // Subtle gradient for depth
            LinearGradient(
                colors: [.clear, .black.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .clipped()
        .indiePaperCard(shadow: IndieHousePalette.green, cornerRadius: 2, shadowOffset: 6)
        .padding(.horizontal, 20)
        .padding(.trailing, 6)
        .padding(.bottom, 6)
        .accessibilityHidden(true)
    }
    
    var addToJungleButton: some View {
        Button(action: {
            let atLimit = !proManager.isPro &&
                          (dataLoader.userProfile?.myJungle.count ?? 0) >= ProManager.freePlantLimit
            if !isInJungle && atLimit {
                HapticManager.shared.playNotification(type: .warning)
                showProUpgrade = true
            } else {
                HapticManager.shared.playNotification(type: .success)
                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                    dataLoader.toggleJungle(plant: plant)
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: isInJungle ? "checkmark" : "plus")
                    .font(.system(size: 17, weight: .black))
                Text(isInJungle ? "Added to My Jungle" : "Add to My Jungle")
                    .font(.claudeSans(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(isInJungle ? IndieHousePalette.green : Color.claudeAccent)
            .foregroundStyle(isInJungle ? Color.claudePrimaryText : .white)
            .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.5))
            .background(IndieHousePalette.ink.offset(x: 4, y: 4))
            .padding(.trailing, 4)
            .padding(.bottom, 4)
        }
        .buttonStyle(BubblingButtonStyle())
        .accessibilityIdentifier("plant-detail.jungle-toggle")
        .accessibilityLabel(isInJungle ? "Added to My Jungle" : "Add to My Jungle")
        .accessibilityHint(isInJungle ? "Removes this plant from My Jungle" : "Adds this plant to your collection")
    }
}
