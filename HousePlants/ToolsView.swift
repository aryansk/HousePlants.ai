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

struct SunSeekerARView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isScanning = false
    @State private var windowDirection: WindowDirection = .south
    @State private var isDirectSun: Bool = true
    @State private var showInfoSheet = false

    enum WindowDirection: String, CaseIterable {
        case north = "North", south = "South", east = "East", west = "West"
        var lightLevel: Double {
            switch self {
            case .north: return 0.15
            case .east, .west: return 0.55
            case .south: return 0.85
            }
        }
    }

    var effectiveLightLevel: Double {
        isDirectSun ? windowDirection.lightLevel : windowDirection.lightLevel * 0.6
    }

    var lightStatus: (String, Color) {
        if effectiveLightLevel < 0.3 {
            return ("Low Light", .blue)
        } else if effectiveLightLevel < 0.7 {
            return ("Medium Light", .green)
        } else {
            return ("Bright Light", .orange)
        }
    }

    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Sun Seeker",
                    subtitle: "Find the perfect spot for your plants.",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.orange.opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )

                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {

                            // Light level readout
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.1))
                                        .frame(width: 120, height: 120)
                                    ForEach(0..<3) { i in
                                        Circle()
                                            .stroke(Color.orange.opacity(0.2), lineWidth: 2)
                                            .frame(width: 120 + CGFloat(i * 30), height: 120 + CGFloat(i * 30))
                                            .scaleEffect(isScanning ? 1.1 : 1.0)
                                            .opacity(isScanning ? 0.3 : 0.1)
                                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(i) * 0.3), value: isScanning)
                                    }
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.orange)
                                        .shadow(color: .orange.opacity(0.3), radius: 10)
                                        .onAppear { isScanning = true }
                                }

                                Text(lightStatus.0.uppercased())
                                    .font(.claudeSans(size: 14, weight: .bold))
                                    .foregroundColor(lightStatus.1)
                                    .tracking(2)

                                Text("\(Int(effectiveLightLevel * 100))%")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundColor(.claudePrimaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)

                            // Window direction picker
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Window Direction")
                                    .font(.claudeSans(size: 14, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .textCase(.uppercase)
                                    .tracking(1.5)
                                    .padding(.horizontal, 24)

                                HStack(spacing: 12) {
                                    ForEach(WindowDirection.allCases, id: \.self) { dir in
                                        Button(action: { windowDirection = dir }) {
                                            Text(dir.rawValue)
                                                .font(.claudeSans(size: 15, weight: windowDirection == dir ? .bold : .regular))
                                                .foregroundColor(windowDirection == dir ? .white : .claudePrimaryText)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(windowDirection == dir ? Color.orange : Color.claudeSecondaryBackground)
                                                .cornerRadius(14)
                                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.claudeBorder, lineWidth: windowDirection == dir ? 0 : 1))
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }

                            // Direct sun toggle
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Conditions")
                                    .font(.claudeSans(size: 14, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .textCase(.uppercase)
                                    .tracking(1.5)
                                    .padding(.horizontal, 24)

                                HStack {
                                    Text(isDirectSun ? "Direct sunlight" : "Filtered / indirect light")
                                        .font(.claudeSans(size: 15))
                                        .foregroundColor(.claudePrimaryText)
                                    Spacer()
                                    Toggle("", isOn: $isDirectSun)
                                        .tint(.orange)
                                }
                                .padding(16)
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
                                .padding(.horizontal, 24)
                            }

                            // Light guide
                            VStack(alignment: .leading, spacing: 12) {
                                Text("The Light Spectrum")
                                    .font(.claudeSans(size: 14, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .textCase(.uppercase)
                                    .tracking(1.5)

                                VStack(spacing: 0) {
                                    LightGuideRow(title: "Low Light", desc: "North windows or deep room corners.", color: .blue)
                                    Divider().padding(.leading, 60)
                                    LightGuideRow(title: "Medium Light", desc: "East/West windows with filtered light.", color: .green)
                                    Divider().padding(.leading, 60)
                                    LightGuideRow(title: "Bright Light", desc: "South windows or direct sun exposure.", color: .orange)
                                }
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
                            }
                            .padding(.horizontal, 24)

                        }
                        .frame(width: geometry.size.width)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showInfoSheet) {
            SunSeekerInfoSheet()
        }
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct LightGuideRow: View {
    let title: String
    let desc: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.claudeSans(size: 15, weight: .bold))
                    .foregroundColor(.claudePrimaryText)
                Text(desc)
                    .font(.claudeSans(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }
}


struct PotSizeCalculatorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentDiameter: Double = 4
    @State private var isRootBound = false
    @State private var growthRate = 1 // 0: Slow, 1: Moderate, 2: Fast
    @State private var showInfoSheet = false
    
    var recommendedSize: Double {
        var increase = 1.0
        if isRootBound { increase += 1.0 }
        if growthRate == 2 { increase += 1.0 }
        if growthRate == 0 { increase = max(0.5, increase - 0.5) }
        return currentDiameter + increase
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Repotting Helper",
                    subtitle: "Find the perfect pot size",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.brown.opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )
                
                ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                        // Pot Growth Visualization
                        VStack(spacing: 20) {
                            PotGrowthView(current: currentDiameter, recommended: recommendedSize)
                                .frame(height: 200)
                                .shadow(color: Color.brown.opacity(0.1), radius: 20, x: 0, y: 10)

                            HStack(alignment: .center) {
                                Text("REC. DIAMETER: ")
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1.5)
                                Text("\(Int(recommendedSize))\"")
                                    .font(.claudeSerif(size: 16, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(12)
                        }
                        .padding(.top, 10)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("CURRENT POT")
                                    .font(.claudeSans(size: 12, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1)
                            
                                HStack {
                                    Text("\(Int(currentDiameter))\"")
                                        .font(.claudeSerif(size: 24, weight: .bold))
                                        .frame(width: 60)
                                    Slider(value: $currentDiameter, in: 2...20, step: 1)
                                        .tint(.brown)
                                }
                                .padding(20)
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
                            }
                            
                            Toggle(isOn: $isRootBound) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Root Bound?")
                                        .font(.claudeSans(size: 16, weight: .bold))
                                    Text("Visible roots escaping drainage holes")
                                        .font(.claudeSans(size: 13))
                                        .foregroundColor(.claudeSecondaryText)
                                }
                            }
                            .padding(20)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.claudeBorder, lineWidth: 1))
                            .tint(Color.claudeAccent)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("GROWTH RATE")
                                    .font(.claudeSans(size: 12, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1)
                                
                                Picker("Growth Rate", selection: $growthRate) {
                                    Text("Slow").tag(0)
                                    Text("Moderate").tag(1)
                                    Text("Fast").tag(2)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(4)
                                .background(Color.claudeSecondaryBackground)
                                .cornerRadius(12)
                            }
                            
                            VStack(alignment: .center, spacing: 16) {
                                Text("RECOMMENDATION")
                                    .font(.claudeSans(size: 12, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(2)
                                
                                Text("\(Int(recommendedSize))\"")
                                    .font(.system(size: 72, weight: .black, design: .serif))
                                    .foregroundColor(Color.claudeAccent)
                                
                                Text("Ideal Diameter")
                                    .font(.claudeSans(size: 16, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                                
                                Text(isRootBound ? "Your plant is feeling cramped. A two-inch increase will give those roots the sanctuary they deserve." : "A modest one-inch increase provides space without risking waterlogged soil.")
                                    .font(.claudeSans(size: 14))
                                    .foregroundColor(.claudeSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.claudeSecondaryBackground)
                                    .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 10)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.claudeBorder, lineWidth: 1))
                        }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showInfoSheet) {
            RepottingHelperInfoSheet()
        }
    }
}

struct DetailStat: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.purple)
            Text(title)
                .font(.claudeSans(size: 12, weight: .bold))
                .foregroundColor(.claudeSecondaryText)
            Text(value)
                .font(.claudeSans(size: 14, weight: .medium))
                .foregroundColor(.claudePrimaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PotGrowthView: View {
    let current: Double
    let recommended: Double
    
    var body: some View {
        ZStack {
            // Container
            RoundedRectangle(cornerRadius: 35)
                .fill(Color.white.opacity(0.05))
                .background(BlurView(style: .systemThinMaterial).clipShape(RoundedRectangle(cornerRadius: 35)))
                .overlay(
                    RoundedRectangle(cornerRadius: 35)
                        .stroke(Color.claudeBorder, lineWidth: 1)
                )
            
            // Outer Pot (Recommended)
            Circle()
                .stroke(Color.claudeAccent.opacity(0.3), lineWidth: 4)
                .frame(width: CGFloat(recommended * 10), height: CGFloat(recommended * 10))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: recommended)
            
            // Inner Pot (Current)
            Circle()
                .fill(Color.brown.opacity(0.6))
                .frame(width: CGFloat(current * 10), height: CGFloat(current * 10))
                .overlay(
                    Circle()
                        .stroke(Color.brown, lineWidth: 2)
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: current)
            
            // Legend
            VStack {
                Spacer()
                Text("GROWTH CAPACITY")
                    .font(.claudeSans(size: 9, weight: .bold))
                    .foregroundColor(.claudeSecondaryText)
                    .tracking(1)
                    .padding(.bottom, 12)
            }
        }
        .frame(width: 160)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sun Seeker Info Sheet
struct SunSeekerInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How the Sun Seeker Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Tell Sun Seeker about your window direction and lighting conditions to find the perfect spot for every plant.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "sun.max.fill", title: "Light Estimator", text: "Select your window direction and whether you get direct sun to instantly estimate light intensity, measured as a percentage of full sun exposure.", color: .orange)
                            
                            InfoRow(icon: "circle.fill", title: "Low Light (0-30%)", text: "North-facing windows and deep corners. Perfect for snake plants, ZZ plants, pothos, and peace lilies.", color: .blue)
                            
                            InfoRow(icon: "circle.fill", title: "Medium Light (30-70%)", text: "East or west-facing windows with filtered light. Ideal for most tropical houseplants and ferns.", color: .green)
                            
                            InfoRow(icon: "circle.fill", title: "Bright Light (70-100%)", text: "South-facing windows or direct sun. Best for succulents, cacti, herbs, and sun-loving tropicals.", color: .orange)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Guide")
                        .font(.claudeSans(size: 16, weight: .bold))
                }
            }
        }
    }
}

// MARK: - Repotting Helper Info Sheet
struct RepottingHelperInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How the Repotting Helper Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Calculate the ideal new pot size based on your current pot diameter, root condition, and the plant's growth rate.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "arrow.up.left.and.arrow.down.right.circle.fill", title: "Size Calculation", text: "We recommend going up 1-2 inches in diameter. Too large a jump can lead to waterlogged soil and root rot.", color: .brown)
                            
                            InfoRow(icon: "arrow.triangle.branch", title: "Root Bound Signs", text: "Roots circling the pot, poking from drainage holes, or pushing the plant upward all indicate it's time to repot.", color: .green)
                            
                            InfoRow(icon: "chart.line.uptrend.xyaxis", title: "Growth Rate Factor", text: "Fast growers like pothos may need a larger size jump, while slow growers like snake plants prefer a snugger fit.", color: .blue)
                            
                            InfoRow(icon: "calendar", title: "Best Timing", text: "Spring is the ideal repotting season when plants are actively growing and can recover quickly from root disturbance.", color: .orange)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Guide")
                        .font(.claudeSans(size: 16, weight: .bold))
                }
            }
        }
    }
}

#Preview {
    ToolsView()
}

