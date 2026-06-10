import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ClaudeHeader(
                        title: "Tools",
                        subtitle: "Advanced aids for your interior ecosystem"
                    )
                    
                    GeometryReader { geometry in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 28) {
                            // Featured Highlight
                            FeaturedToolCard()
                                .padding(.horizontal, 20)
                            
                            // Category: Essential Care
                            ToolSection(title: "Essential Care") {
                                VStack(spacing: 12) {
                                    ToolNavigationLink(destination: SunSeekerARView(), icon: "sun.max.fill", title: "Sun Seeker", description: "Light meter to find the perfect spot for your plants.", color: .orange)
                                    
                                    ToolNavigationLink(destination: WaterCalculatorView(), icon: "drop.fill", title: "Watering Guide", description: "Custom schedules based on your local micro-climate.", color: .blue)
                                    
                                    ToolNavigationLink(destination: FertilizerCalculatorView(), icon: "leaf.fill", title: "Fertilizer Guide", description: "Precision nutrition for every growth stage.", color: .green)
                                    
                                    ToolNavigationLink(destination: SoilMixBuilderView(), icon: "square.stack.3d.up.fill", title: "Soil Mixologist", description: "Craft bespoke substrates for species.", color: Color(hex: "8B4513"))
                                    
                                    ToolNavigationLink(destination: SeasonalCareCalendarView(), icon: "calendar.badge.clock", title: "Seasonal Care", description: "Month-by-month care timeline for every season.", color: Color(hex: "4CAF50"))

                                    ToolNavigationLink(destination: SitterModeView(), icon: "person.2.fill", title: "Plant Sitter Mode", description: "Generate a shareable care PDF for your sitter.", color: .pink)
                                }
                            }
                            
                            // Category: Health & Growth
                            ToolSection(title: "Health & Growth") {
                                VStack(spacing: 12) {
                                    ToolNavigationLink(destination: PlantDoctorView(), icon: "cross.case.fill", title: "Plant Doctor", description: "Diagnose pests and diseases with symptom lookup.", color: .red)
                                    
                                    ToolNavigationLink(destination: PotSizeCalculatorView(), icon: "arrow.up.left.and.arrow.down.right.circle.fill", title: "Repotting Helper", description: "Calculate the ideal pot size for root expansion.", color: .brown)
                                    
                                    ToolNavigationLink(destination: ToxicityCheckerView(), icon: "shield.checkered", title: "Toxicity Checker", description: "Verify pet and child safety for every plant.", color: Color(hex: "2ECC71"))
                                    
                                    ToolNavigationLink(destination: PropagationStationView(), icon: "scissors", title: "Propagation Station", description: "Step-by-step guides to multiply your collection.", color: Color(hex: "8E44AD"))
                                }
                            }
                            
                            // Category: Deep Exploration
                            ToolSection(title: "Exploration") {
                                VStack(spacing: 12) {
                                    ToolNavigationLink(destination: ClimateMatcherToolView(), icon: "thermometer.sun.fill", title: "Climate Matcher", description: "Find plants perfectly suited to your local environment.", color: .orange)
                                    
                                     ToolNavigationLink(destination: SkincareLabView(), icon: "flask.fill", title: "Skincare Lab", description: "Botanical remedies from your garden.", color: .purple)
                                    
                                    ToolNavigationLink(destination: CelestialMoonPhaseView(), icon: "moon.stars.fill", title: "Moon Gardening", description: "Align your planting with lunar cycles.", color: .indigo)
                                    
                                    ToolNavigationLink(destination: OriginExplorerView(), icon: "globe.americas.fill", title: "Origin Explorer", description: "Interactive map of where your plants call home.", color: .teal)
                                }
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
            .toolbar(.visible, for: .tabBar)
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
    FeaturedToolInfo(id: 11, icon: "globe.americas.fill", title: "Origin Explorer", description: "Explore the native habitats of your houseplants on an interactive world map.", ctaLabel: "Explore Origins", gradientColors: [Color(hex: "009688"), Color(hex: "4DB6AC")])
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
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
            }
            .padding(24)
            .background(
                LinearGradient(colors: tool.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(24)
            .shadow(color: tool.gradientColors.first?.opacity(0.25) ?? Color.claudeAccent.opacity(0.25), radius: 15, x: 0, y: 10)
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
            Text(title)
                .font(.claudeSans(size: 13, weight: .bold))
                .foregroundStyle(Color.claudeSecondaryText)
                .textCase(.uppercase)
                .tracking(1.5)
                .padding(.horizontal, 24)
            
            content
                .padding(.horizontal, 20)
        }
    }
}

struct ToolNavigationLink<Destination: View>: View {
    let destination: Destination
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        NavigationLink(destination: destination) {
            ToolCardView(icon: icon, title: title, description: description, color: color)
        }
        .buttonStyle(InteractiveCardButtonStyle())
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
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.1))
                    .frame(width: 52, height: 52)
                
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
        .background(Color.claudeSecondaryBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.claudeBorder, lineWidth: 1)
        )
    }
}

#Preview {
    ToolsView()
}

