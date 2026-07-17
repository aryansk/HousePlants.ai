import SwiftUI

struct WaterCalculatorView: View {
    @State private var selectedPlantType = PlantType.tropical
    @State private var potSize = PotSize.medium
    @State private var season = Season.summer
    @State private var locationName: String = "San Francisco, CA"
    @State private var humidityLevel: Double = 60
    @State private var temperature: Double = 22
    @State private var showInfoSheet = false
    
    enum PlantType: String, CaseIterable, Identifiable {
        case tropical = "Tropical"
        case succulent = "Succulent"
        case fern = "Fern"
        case herb = "Herb"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .tropical: return "leaf.fill"
            case .succulent: return "sun.max.fill"
            case .fern: return "camera.macro"
            case .herb: return "fork.knife"
            }
        }
        
        var baseWateringDays: Int {
            switch self {
            case .tropical: return 7
            case .succulent: return 14
            case .fern: return 4
            case .herb: return 3
            }
        }
    }
    
    enum PotSize: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        
        var id: String { self.rawValue }
        
        var label: String {
            switch self {
            case .small: return "4-6\""
            case .medium: return "8-10\""
            case .large: return "12\"+"
            }
        }
        
        var multiplier: Double {
            // Soil volume scales roughly with diameter^2.5 for typical pot proportions;
            // root density partially offsets, giving these empirical ratios vs. a 9" pot.
            switch self {
            case .small: return 0.65
            case .medium: return 1.0
            case .large: return 1.7
            }
        }

        var volume: String {
            // Rule of thumb: water ~20% of pot soil volume to saturate to drainage.
            switch self {
            case .small: return "150-300 ml"
            case .medium: return "750 ml - 1.2 L"
            case .large: return "2-3 L"
            }
        }
    }

    enum Season: String, CaseIterable, Identifiable {
        case summer = "Spring/Summer"
        case winter = "Fall/Winter"

        var id: String { self.rawValue }

        var icon: String {
            switch self {
            case .summer: return "sun.max.fill"
            case .winter: return "snowflake"
            }
        }

        // Dormancy reduces transpiration / root uptake — extend interval by ~40%.
        var multiplier: Double {
            switch self {
            case .summer: return 1.0
            case .winter: return 1.4
            }
        }
    }

    // Tetens equation: saturation vapor pressure in kPa.
    private func saturationVaporPressure(_ tC: Double) -> Double {
        return 0.6108 * exp(17.27 * tC / (tC + 237.3))
    }

    // Vapor pressure deficit drives transpiration: higher VPD → faster soil drying.
    private func vaporPressureDeficit(tempC: Double, rhPercent: Double) -> Double {
        let rh = max(0, min(100, rhPercent)) / 100.0
        return saturationVaporPressure(tempC) * (1 - rh)
    }

    var calculatedFrequency: String {
        let base = Double(selectedPlantType.baseWateringDays)
        // Reference condition for `baseWateringDays`: 22 °C, 60% RH → VPD ≈ 1.06 kPa.
        let referenceVPD = vaporPressureDeficit(tempC: 22, rhPercent: 60)
        let currentVPD = max(0.15, vaporPressureDeficit(tempC: temperature, rhPercent: humidityLevel))
        let envFactor = referenceVPD / currentVPD

        let raw = base * potSize.multiplier * envFactor * season.multiplier
        let finalDays = max(1, Int(raw.rounded()))
        let upper = finalDays + max(1, finalDays / 4) // ±25% window
        return "Every \(finalDays)-\(upper) days"
    }
    
    var calculatedMethod: String {
        switch selectedPlantType {
        case .fern: return "Mist & Soak"
        case .succulent: return "Soil Soak (Dry)"
        case .tropical: return "Soil Soak"
        case .herb: return "Keep Moist"
        }
    }
    
    var waterLevel: Double {
        var level: Double
        switch potSize {
        case .small: level = 0.3
        case .medium: level = 0.5
        case .large: level = 0.8
        }
        
        switch selectedPlantType {
        case .succulent: level -= 0.15
        case .tropical: level += 0.0
        case .fern: level += 0.15
        case .herb: level += 0.05
        }
        
        level += (season == .summer) ? 0.05 : -0.1
        level += (temperature - 22.0) * 0.008
        level += (60.0 - humidityLevel) * 0.003
        
        return max(0.1, min(0.95, level))
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Watering Guide",
                    subtitle: "Precision hydration for your botanical sanctuary",
                    location: locationName,
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.blue.opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                        
                        // Water Tank Visualization
                        VStack(spacing: 20) {
                            WaterTankView(level: waterLevel, color: .blue)
                                .frame(height: 200)
                                .shadow(color: Color.blue.opacity(0.1), radius: 20, x: 0, y: 10)
                            
                            HStack(alignment: .center, spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 14))
                                    .foregroundColor(.claudeSecondaryText)
                                
                                Text("ESTIMATED FREQUENCY: ")
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1.5)
                                Text(calculatedFrequency)
                                    .font(.claudeSerif(size: 16, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(12)
                        }
                        .padding(.top, 10)
                        
                        // Plant Type Selection
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Botanical Family", icon: "leaf.fill")
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(PlantType.allCases) { type in
                                        SelectionCard(
                                            title: type.rawValue,
                                            icon: type.icon,
                                            isSelected: selectedPlantType == type,
                                            color: .blue
                                        ) {
                                            selectedPlantType = type
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Condition Sliders
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Environmental Conditions", icon: "thermometer.medium")
                            
                            VStack(spacing: 20) {
                                ConditionSlider(title: "Humidity", value: $humidityLevel, range: 0...100, unit: "%", icon: "humidity.fill")
                                ConditionSlider(title: "Temperature", value: $temperature, range: 10...40, unit: "°C", icon: "thermometer.medium")
                                
                                HStack(spacing: 12) {
                                    ForEach(Season.allCases) { s in
                                        Button(action: { season = s }) {
                                            HStack {
                                                Image(systemName: s.icon)
                                                Text(s.rawValue)
                                            }
                                            .font(.claudeSans(size: 14, weight: .medium))
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(season == s ? Color.blue.opacity(0.1) : Color.claudeSecondaryBackground)
                                            .foregroundColor(season == s ? .blue : .claudeSecondaryText)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(season == s ? Color.blue.opacity(0.3) : Color.claudeBorder, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(BubblingButtonStyle())
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                        
                        // Pot Size
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Vessel Size", icon: "square.dashed")
                            
                            HStack(spacing: 12) {
                                ForEach(PotSize.allCases) { size in
                                    Button(action: { potSize = size }) {
                                        VStack(spacing: 4) {
                                            Text(size.rawValue)
                                                .font(.claudeSans(size: 15, weight: .bold))
                                            Text(size.label)
                                                .font(.claudeSans(size: 12))
                                                .opacity(0.7)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(potSize == size ? Color.claudeAccent.opacity(0.1) : Color.claudeSecondaryBackground)
                                        .foregroundColor(potSize == size ? .claudeAccent : .claudePrimaryText)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(potSize == size ? Color.claudeAccent.opacity(0.3) : Color.claudeBorder, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(InteractiveCardButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Results Card
                        VStack(spacing: 24) {
                            VStack(spacing: 8) {
                                Text("ESTIMATED SCHEDULE")
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(.blue.opacity(0.6))
                                    .tracking(2)
                                
                                Text(calculatedFrequency)
                                    .font(.claudeSerif(size: 32, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                            }
                            
                            HStack(spacing: 0) {
                                ResultItem(title: "Hydration Volume", value: potSize.volume, icon: "drop.fill", color: .blue)
                                Divider().frame(height: 40).padding(.horizontal, 20)
                                ResultItem(title: "Watering Method", value: calculatedMethod, icon: "hand.tap.fill", color: .teal)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue.opacity(0.5))
                                    Text("These estimates are adjusted for your local \(humidityLevel < 40 ? "dry" : "humid") conditions in \(locationName). Always test the top inch of soil.")
                                        .font(.claudeSans(size: 13))
                                        .foregroundColor(.claudeSecondaryText)
                                        .lineSpacing(2)
                                }
                                .padding(16)
                                .background(Color.blue.opacity(0.04))
                                .cornerRadius(16)
                            }
                        }
                        .padding(32)
                        .background(
                            ZStack {
                                Color.claudeSecondaryBackground
                                LinearGradient(colors: [.blue.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                            }
                        )
                        .cornerRadius(32)
                        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.claudeBorder, lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Location Search
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Adjust Location", icon: "magnifyingglass")
                            
                            ClaudeCitySearchField(
                                title: "Search City",
                                placeholder: "e.g. London, Tokyo...",
                                text: .constant(""),
                                icon: "location.magnifyingglass"
                            ) { city, country in
                                withAnimation {
                                    locationName = "\(city), \(country)"
                                    // Simulate changing conditions based on location
                                    temperature = Double.random(in: 18...28)
                                    humidityLevel = Double.random(in: 30...80)
                                }
                            }
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
        .navigationBarHidden(true)
        .sheet(isPresented: $showInfoSheet) {
            WateringGuideInfoSheet()
        }
    }
}

// MARK: - Subcomponents

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.claudeSecondaryText)
            Text(title.uppercased())
                .font(.claudeSans(size: 11, weight: .bold))
                .foregroundColor(.claudeSecondaryText)
                .tracking(1.5)
        }
        .padding(.horizontal, 24)
    }
}

struct SelectionCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.15) : Color.claudeBorder.opacity(0.2))
                        .frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? color : .claudeSecondaryText)
                }
                
                Text(title)
                    .font(.claudeSans(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .claudePrimaryText : .claudeSecondaryText)
            }
            .frame(width: 100, height: 110)
            .background(isSelected ? Color.claudeSecondaryBackground : Color.clear)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? color.opacity(0.3) : Color.claudeBorder, lineWidth: 1)
            )
        }
        .buttonStyle(InteractiveCardButtonStyle())
    }
}

struct ConditionSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    Text(title)
                        .font(.claudeSans(size: 14, weight: .medium))
                        .foregroundColor(.claudePrimaryText)
                }
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(.claudeSans(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            Slider(value: $value, in: range)
                .tint(.blue)
        }
    }
}

struct ResultItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.claudeSans(size: 11, weight: .bold))
                    .foregroundColor(.claudeSecondaryText)
            }
            Text(value)
                .font(.claudeSans(size: 16, weight: .bold))
                .foregroundColor(.claudePrimaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WaterTankView: View {
    let level: Double
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Glass Container
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.05))
                    .background(BlurView(style: .systemThinMaterial).clipShape(RoundedRectangle(cornerRadius: 30)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.claudeBorder, lineWidth: 1)
                    )
                
                // Water Level with Waves
                WaterWave(phase: phase, strength: 6, frequency: 1.5)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: geometry.size.height * CGFloat(level))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: level)
                
                // Top Reflection
                VStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)
                    Spacer()
                }
            }
            .mask(RoundedRectangle(cornerRadius: 30))
            .onAppear {
                if !reduceMotion {
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        phase = .pi * 2
                    }
                }
            }
        }
        .frame(width: 140)
        .frame(maxWidth: .infinity)
    }
}

struct WaterWave: Shape {
    var phase: Double
    var strength: Double
    var frequency: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let mid = height / 2
        
        path.move(to: CGPoint(x: 0, y: mid))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * frequency + phase)
            let y = mid + CGFloat(sine) * CGFloat(strength)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Info Sheet View
struct WateringGuideInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How the Watering Guide Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("This calculator estimates an ideal watering schedule based on your plant type, pot size, local climate, and the current season.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "leaf.fill", title: "Plant Type", text: "Different species have vastly different water needs. Ferns love moisture while succulents prefer drought between drinks.", color: .green)
                            
                            InfoRow(icon: "square.dashed", title: "Pot Size", text: "Larger pots retain moisture longer, reducing watering frequency. Smaller pots dry out faster and need more attention.", color: .brown)
                            
                            InfoRow(icon: "humidity.fill", title: "Humidity & Temperature", text: "Higher humidity slows evaporation, while warmer temperatures increase water demand. Adjust these to match your home.", color: .blue)
                            
                            InfoRow(icon: "sun.max.fill", title: "Seasonal Adjustment", text: "Plants need significantly less water in fall and winter when growth slows. Always reduce frequency during dormancy.", color: .orange)
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
    NavigationView {
        WaterCalculatorView()
    }
}
