import SwiftUI

private enum ToolSearchIndex {
    static let essential = [
        "Plant Identifier camera photo scan identify species",
        "Sun Seeker light meter room spot brightness",
        "Watering Guide water schedule climate hydration",
        "Fertilizer Guide nutrition feed growth dose",
        "Soil Mixologist soil substrate recipe mix",
        "Seasonal Care calendar month season reminder",
        "Plant Sitter Mode sitter share care PDF travel"
    ]
    static let health = [
        "Plant Doctor diagnose symptoms pests disease treatment",
        "Repotting Helper pot size roots repot",
        "Toxicity Checker pet child safety toxic",
        "Propagation Station cuttings division multiply",
        "Growth Analytics health timeline watering journal stats"
    ]
    static let exploration = [
        "Climate Matcher city climate environment recommendations",
        "Skincare Lab botanical beauty remedies recipes",
        "Moon Gardening lunar phases moon cycles",
        "Origin Explorer map native habitat countries"
    ]
}

struct ToolsView: View {
    @Environment(DataLoader.self) var dataLoader
    @ObservedObject private var proManager = ProManager.shared
    @State private var showProUpgrade = false
    @State private var showGrowthPicker = false
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private var matchedToolCount: Int {
        (ToolSearchIndex.essential + ToolSearchIndex.health + ToolSearchIndex.exploration)
            .filter(matches)
            .count
    }

    private var hasEssentialMatches: Bool { ToolSearchIndex.essential.contains(where: matches) }
    private var hasHealthMatches: Bool { ToolSearchIndex.health.contains(where: matches) }
    private var hasExplorationMatches: Bool { ToolSearchIndex.exploration.contains(where: matches) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ClaudeHeader(
                        title: "Tools",
                        subtitle: "Practical help for every stage of plant care"
                    )

                    ToolSearchBar(searchText: $searchText, isFocused: $searchFocused)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    
                    GeometryReader { geometry in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 28) {
                            // Featured Highlight
                            if searchText.isEmpty {
                                FeaturedToolCard()
                                    .padding(.horizontal, 20)
                            } else {
                                HStack {
                                    Text("\(matchedToolCount) matching tool\(matchedToolCount == 1 ? "" : "s")")
                                        .font(.claudeSans(size: 13, weight: .bold))
                                        .foregroundStyle(Color.claudeSecondaryText)
                                    Spacer()
                                    Button("Clear") { searchText = "" }
                                        .font(.claudeSans(size: 13, weight: .bold))
                                        .foregroundStyle(Color.claudeAccent)
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Category: Essential Care
                            if hasEssentialMatches {
                                ToolSection(title: "Essential Care") {
                                VStack(spacing: 12) {
                                    if matches(ToolSearchIndex.essential[0]) {
                                        ToolNavigationLink(destination: PlantIdentifierView(), icon: "camera.viewfinder", title: "Plant Identifier", description: "Snap a photo to identify any plant instantly.", color: Color(hex: "16A085"))
                                    }

                                    if matches(ToolSearchIndex.essential[1]) {
                                        ToolNavigationLink(destination: SunSeekerARView(), icon: "sun.max.fill", title: "Sun Seeker", description: "Light meter to find the perfect spot for your plants.", color: .orange, index: 1)
                                    }
                                    
                                    if matches(ToolSearchIndex.essential[2]) {
                                        ToolNavigationLink(destination: WaterCalculatorView(), icon: "drop.fill", title: "Watering Guide", description: "Custom schedules based on your local micro-climate.", color: .blue, index: 2)
                                    }
                                    
                                    if matches(ToolSearchIndex.essential[3]) {
                                        ToolNavigationLink(destination: FertilizerCalculatorView(), icon: "leaf.fill", title: "Fertilizer Guide", description: "Precision nutrition for every growth stage.", color: .green, index: 3)
                                    }
                                    
                                    if matches(ToolSearchIndex.essential[4]) {
                                        ToolNavigationLink(destination: SoilMixBuilderView(), icon: "square.stack.3d.up.fill", title: "Soil Mixologist", description: "Craft bespoke substrates for species.", color: Color(hex: "8B4513"), index: 4)
                                    }
                                    
                                    if matches(ToolSearchIndex.essential[5]) {
                                        ToolNavigationLink(destination: SeasonalCareCalendarView(), icon: "calendar.badge.clock", title: "Seasonal Care", description: "Month-by-month care timeline for every season.", color: Color(hex: "4CAF50"), index: 5)
                                    }

                                    if matches(ToolSearchIndex.essential[6]) {
                                        ToolNavigationLink(destination: SitterModeView(), icon: "person.2.fill", title: "Plant Sitter Mode", description: "Generate a shareable care PDF for your sitter.", color: .pink, index: 6)
                                    }
                                }
                            }
                            }
                            
                            // Category: Health & Growth
                            if hasHealthMatches {
                                ToolSection(title: "Health & Growth") {
                                VStack(spacing: 12) {
                                    if matches(ToolSearchIndex.health[0]) {
                                        ToolNavigationLink(destination: PlantDoctorView(), icon: "cross.case.fill", title: "Plant Doctor", description: "Diagnose pests and diseases with symptom lookup.", color: .red, index: 0)
                                    }

                                    if matches(ToolSearchIndex.health[1]) {
                                        ToolNavigationLink(destination: PotSizeCalculatorView(), icon: "arrow.up.left.and.arrow.down.right.circle.fill", title: "Repotting Helper", description: "Calculate the ideal pot size for root expansion.", color: .brown, index: 1)
                                    }

                                    if matches(ToolSearchIndex.health[2]) {
                                        ToolNavigationLink(destination: ToxicityCheckerView(), icon: "shield.checkered", title: "Toxicity Checker", description: "Verify pet and child safety for every plant.", color: Color(hex: "2ECC71"), index: 2)
                                    }

                                    if matches(ToolSearchIndex.health[3]) {
                                        ToolNavigationLink(destination: PropagationStationView(), icon: "scissors", title: "Propagation Station", description: "Step-by-step guides to multiply your collection.", color: Color(hex: "8E44AD"), index: 3)
                                    }

                                    // Growth Analytics — Pro, opens plant picker then analytics view
                                    if matches(ToolSearchIndex.health[4]) {
                                        Button(action: {
                                        if proManager.isPro { showGrowthPicker = true } else { showProUpgrade = true }
                                    }) {
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.purple.opacity(0.12))
                                                    .frame(width: 48, height: 48)
                                                Image(systemName: "chart.xyaxis.line")
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundStyle(.purple)
                                            }
                                            VStack(alignment: .leading, spacing: 3) {
                                                HStack(spacing: 6) {
                                                    Text("Growth Analytics")
                                                        .font(.claudeSans(size: 16, weight: .bold))
                                                        .foregroundStyle(Color.claudePrimaryText)
                                                    if !proManager.isPro {
                                                        Text("PRO")
                                                            .font(.system(size: 9, weight: .bold))
                                                            .foregroundStyle(.white)
                                                            .padding(.horizontal, 5)
                                                            .padding(.vertical, 2)
                                                            .background(Capsule().fill(Color.orange))
                                                    }
                                                }
                                                Text("Per-plant health timeline, watering adherence & journal stats.")
                                                    .font(.claudeSans(size: 13))
                                                    .foregroundStyle(Color.claudeSecondaryText)
                                            }
                                            Spacer()
                                            Image(systemName: proManager.isPro ? "chevron.right" : "lock.fill")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(Color.claudeBorder)
                                        }
                                        .padding(16)
                                        .indiePaperCard(shadow: .purple, cornerRadius: 2, shadowOffset: 3)
                                        .padding(.trailing, 3)
                                        .padding(.bottom, 3)
                                    }
                                        .buttonStyle(InteractiveCardButtonStyle())
                                        .accessibilityLabel("Growth Analytics")
                                        .accessibilityValue(proManager.isPro ? "Available" : "Requires Pro")
                                    }
                                }
                            }
                            }
                            
                            // Category: Deep Exploration
                            if hasExplorationMatches {
                                ToolSection(title: "Exploration") {
                                VStack(spacing: 12) {
                                    if matches(ToolSearchIndex.exploration[0]) {
                                        ToolNavigationLink(destination: ClimateMatcherToolView(), icon: "thermometer.sun.fill", title: "Climate Matcher", description: "Find plants perfectly suited to your local environment.", color: .orange, index: 0)
                                    }
                                    
                                    if matches(ToolSearchIndex.exploration[1]) {
                                        ToolNavigationLink(destination: SkincareLabView(), icon: "flask.fill", title: "Skincare Lab", description: "Botanical remedies from your garden.", color: .purple, index: 1)
                                    }
                                    
                                    if matches(ToolSearchIndex.exploration[2]) {
                                        ToolNavigationLink(destination: CelestialMoonPhaseView(), icon: "moon.stars.fill", title: "Moon Gardening", description: "Align your planting with lunar cycles.", color: .indigo, index: 2)
                                    }
                                    
                                    if matches(ToolSearchIndex.exploration[3]) {
                                        ToolNavigationLink(destination: OriginExplorerView(), icon: "globe.americas.fill", title: "Origin Explorer", description: "Interactive map of where your plants call home.", color: .teal, index: 3)
                                    }
                                }
                            }
                            }

                            if matchedToolCount == 0 {
                                ToolSearchEmptyView(clearSearch: { searchText = "" })
                                    .padding(.horizontal, 20)
                            }
                            }
                            .frame(width: geometry.size.width)
                            .padding(.top, 12)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
        .sheet(isPresented: $showGrowthPicker) {
            GrowthPlantPickerView()
                .environment(dataLoader)
        }
    }

    private func matches(_ searchableText: String) -> Bool {
        let tokens = searchText
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
        guard !tokens.isEmpty else { return true }
        let haystack = searchableText.lowercased()
        return tokens.allSatisfy { haystack.contains($0) }
    }
}

private struct ToolSearchBar: View {
    @Binding var searchText: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isFocused.wrappedValue ? Color.claudeAccent : Color.claudeSecondaryText)
                .accessibilityHidden(true)

            TextField("Search tools by task", text: $searchText)
                .font(.claudeSans(size: 16))
                .focused(isFocused)
                .submitLabel(.search)
                .accessibilityIdentifier("tools.search")
                .accessibilityLabel("Search plant care tools")

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.claudeSecondaryText)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear tool search")
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .background(Color.claudeSecondaryBackground)
        .overlay(Rectangle().stroke(isFocused.wrappedValue ? Color.claudeAccent : Color.claudeBorder, lineWidth: isFocused.wrappedValue ? 2 : 1.5))
        .background(IndieHousePalette.ink.offset(x: 4, y: 4))
        .padding(.trailing, 4)
        .padding(.bottom, 4)
    }
}

private struct ToolSearchEmptyView: View {
    let clearSearch: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(IndieHousePalette.orange)
            Text("No matching tools")
                .font(.claudeSerif(size: 22, weight: .bold))
            Text("Try a task like water, pet safety, light, or repotting.")
                .font(.claudeSans(size: 14))
                .foregroundStyle(Color.claudeSecondaryText)
                .multilineTextAlignment(.center)
            Button("Show every tool", action: clearSearch)
                .font(.claudeSans(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(Color.claudeAccent)
                .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.5))
                .buttonStyle(BubblingButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .indiePaperCard(shadow: IndieHousePalette.orange, cornerRadius: 2, shadowOffset: 5)
        .padding(.trailing, 5)
        .padding(.bottom, 5)
    }
}

// MARK: - Growth plant picker

/// Shown from ToolsView; lets the user choose which plant to view analytics for.
private struct GrowthPlantPickerView: View {
    @Environment(DataLoader.self) var dataLoader
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let jungle = dataLoader.userProfile?.myJungle, !jungle.isEmpty {
                    ForEach(jungle) { myPlant in
                        if let plant = dataLoader.plant(for: myPlant.plantId) {
                            NavigationLink(destination: PlantGrowthView(plant: plant)
                                .environment(dataLoader)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(myPlant.nickname)
                                        .font(.claudeSans(size: 15, weight: .semibold))
                                    Text(plant.botanicalName)
                                        .font(.claudeSans(size: 12))
                                        .italic()
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } else {
                    Text("Add plants to My Jungle to see their analytics.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Select Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Components

// MARK: - Featured Tool Data

struct FeaturedToolInfo: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let description: String
    let ctaLabel: String
    let gradientColors: [Color]
}

private let allFeaturedTools: [FeaturedToolInfo] = [
    FeaturedToolInfo(id: 0, icon: "sun.max.fill", title: "Sun Seeker", description: "Find the perfect light intensity for every corner of your home.", ctaLabel: "Start Measuring", gradientColors: [Color.claudeAccent, Color(hex: "E69173")]),
    FeaturedToolInfo(id: 1, icon: "drop.fill", title: "Watering Guide", description: "Build custom watering schedules tuned to your home's micro-climate and each plant's needs.", ctaLabel: "Build Schedule", gradientColors: [Color(hex: "2980B9"), Color(hex: "6DD5FA")]),
    FeaturedToolInfo(id: 2, icon: "leaf.fill", title: "Fertilizer Guide", description: "Precision nutrition plans for every growth stage — from seedling to mature specimen.", ctaLabel: "Plan Nutrition", gradientColors: [Color(hex: "27AE60"), Color(hex: "A8E063")]),
    FeaturedToolInfo(id: 3, icon: "square.stack.3d.up.fill", title: "Soil Mixologist", description: "Craft bespoke substrates optimized for your species' native growing conditions.", ctaLabel: "Mix Substrate", gradientColors: [Color(hex: "8B4513"), Color(hex: "D2691E")]),
    FeaturedToolInfo(id: 4, icon: "calendar.badge.clock", title: "Seasonal Care", description: "A month-by-month care calendar so you never miss a beat through every season.", ctaLabel: "View Calendar", gradientColors: [Color(hex: "4CAF50"), Color(hex: "81C784")]),
    FeaturedToolInfo(id: 5, icon: "cross.case.fill", title: "Plant Doctor", description: "Diagnose pests and diseases with an interactive symptom checker and treatment guide.", ctaLabel: "Start Diagnosis", gradientColors: [Color(hex: "E74C3C"), Color(hex: "F1948A")]),
    FeaturedToolInfo(id: 6, icon: "arrow.up.left.and.arrow.down.right.circle.fill", title: "Repotting Helper", description: "Calculate the ideal pot size and timing for stress-free root expansion.", ctaLabel: "Calculate Size", gradientColors: [Color(hex: "795548"), Color(hex: "A1887F")]),
    FeaturedToolInfo(id: 7, icon: "shield.checkered", title: "Toxicity Checker", description: "Instantly verify which plants are safe around your pets and children.", ctaLabel: "Check Safety", gradientColors: [Color(hex: "2ECC71"), Color(hex: "58D68D")]),
    FeaturedToolInfo(id: 8, icon: "scissors", title: "Propagation Station", description: "Step-by-step guides to multiply your collection through cuttings, division, and more.", ctaLabel: "Start Propagating", gradientColors: [Color(hex: "8E44AD"), Color(hex: "BB8FCE")]),
    FeaturedToolInfo(id: 9, icon: "flask.fill", title: "Skincare Lab", description: "Discover botanical skincare remedies you can craft from your own houseplant garden.", ctaLabel: "Explore Recipes", gradientColors: [Color(hex: "9B59B6"), Color(hex: "D7BDE2")]),
    FeaturedToolInfo(id: 10, icon: "moon.stars.fill", title: "Moon Gardening", description: "Align your planting, pruning, and watering with lunar cycles for optimal growth.", ctaLabel: "View Phases", gradientColors: [Color(hex: "3F51B5"), Color(hex: "7986CB")]),
    FeaturedToolInfo(id: 11, icon: "globe.americas.fill", title: "Origin Explorer", description: "Explore the native habitats of your houseplants on an interactive world map.", ctaLabel: "Explore Origins", gradientColors: [Color(hex: "009688"), Color(hex: "4DB6AC")]),
    FeaturedToolInfo(id: 12, icon: "camera.viewfinder", title: "Plant Identifier", description: "Snap a photo of any plant and instantly discover its name and care guide.", ctaLabel: "Identify Now", gradientColors: [Color(hex: "16A085"), Color(hex: "48C9B0")])
]

struct FeaturedToolCard: View {
    /// Determines which tool is featured based on the current ISO week of the year.
    private var currentTool: FeaturedToolInfo {
        let weekOfYear = Calendar.current.component(.weekOfYear, from: Date())
        let index = weekOfYear % allFeaturedTools.count
        return allFeaturedTools[index]
    }
    
    var body: some View {
        let tool = currentTool
        
        NavigationLink(destination: destinationView(for: tool.id)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: tool.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FEATURED TOOL")
                            .font(.claudeSans(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1)
                        
                        Text(tool.title)
                            .font(.claudeSerif(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text(tool.description)
                    .font(.claudeSans(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                
                HStack {
                    Text(tool.ctaLabel)
                        .font(.claudeSans(size: 14, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.2))
                .overlay(Rectangle().stroke(Color.white.opacity(0.65), lineWidth: 1))
            }
            .padding(24)
            .background(
                LinearGradient(colors: tool.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 2))
            .background(IndieHousePalette.ink.offset(x: 7, y: 8))
            .rotationEffect(.degrees(-0.6))
            .padding(.trailing, 7)
            .padding(.bottom, 8)
        }
        .buttonStyle(InteractiveCardButtonStyle())
    }
    
    /// Maps a tool ID to its destination view.
    @ViewBuilder
    private func destinationView(for id: Int) -> some View {
        switch id {
        case 0:  SunSeekerARView()
        case 1:  WaterCalculatorView()
        case 2:  FertilizerCalculatorView()
        case 3:  SoilMixBuilderView()
        case 4:  SeasonalCareCalendarView()
        case 5:  PlantDoctorView()
        case 6:  PotSizeCalculatorView()
        case 7:  ToxicityCheckerView()
        case 8:  PropagationStationView()
        case 9:  SkincareLabView()
        case 10: CelestialMoonPhaseView()
        case 11: OriginExplorerView()
        case 12: PlantIdentifierView()
        default: SunSeekerARView()
        }
    }
}

struct ToolSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            IndieCutLabel(text: title, color: sectionColor)
                .padding(.horizontal, 24)
            
            content
                .padding(.horizontal, 20)
        }
    }

    private var sectionColor: Color {
        switch title {
        case "Essential Care": IndieHousePalette.green
        case "Health & Growth": IndieHousePalette.yellow
        default: IndieHousePalette.pink
        }
    }
}

struct ToolNavigationLink<Destination: View>: View {
    let destination: Destination
    let icon: String
    let title: String
    let description: String
    let color: Color
    /// Position within its section, used to stagger the entrance. Defaults to 0 so
    /// existing call sites keep working and simply appear immediately.
    var index: Int = 0

    var body: some View {
        NavigationLink(destination: destination) {
            ToolCardView(icon: icon, title: title, description: description, color: color)
        }
        .buttonStyle(PaperPressButtonStyle(shadowOffset: 3, haptic: false))
        .staggeredAppear(index: index, step: 0.05, cap: 5, offset: 12, tilt: 1)
    }
}

struct ToolCardView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Rectangle()
                    .fill(color.opacity(0.1))
                    .frame(width: 52, height: 52)
                    .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1))
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.claudeSerif(size: 18, weight: .bold))
                    .foregroundColor(.claudePrimaryText)
                
                Text(description)
                    .font(.claudeSans(size: 13))
                    .foregroundColor(.claudeSecondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.claudeBorder)
        }
        .padding(16)
        .indiePaperCard(shadowOffset: 3)
        .padding(.trailing, 3)
        .padding(.bottom, 3)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(description)
        .accessibilityHint("Opens this tool")
    }
}

#Preview {
    ToolsView()
}
