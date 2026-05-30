import SwiftUI

struct FertilizerCalculatorView: View {
    @State private var fertilizerType = FertilizerType.liquid
    @State private var plantType = PlantType.foliage
    @State private var season = Season.springSummer
    @State private var showInfoSheet = false
    
    enum FertilizerType: String, CaseIterable, Identifiable {
        case liquid = "Liquid"
        case granular = "Granular"
        case slowRelease = "Slow Release"
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .liquid: return "drop.fill"
            case .granular: return "circle.grid.hex.fill"
            case .slowRelease: return "clock.fill"
            }
        }
    }
    
    enum PlantType: String, CaseIterable, Identifiable {
        case foliage = "Foliage"
        case flowering = "Flowering"
        case succulent = "Succulent"
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .foliage: return "leaf.fill"
            case .flowering: return "sparkles"
            case .succulent: return "sun.max.fill"
            }
        }
    }
    
    enum Season: String, CaseIterable, Identifiable {
        case springSummer = "Spring/Summer"
        case fallWinter = "Fall/Winter"
        var id: String { self.rawValue }
    }
    
    // Target NPK ratios from standard horticultural sources (e.g. UMN Extension,
    // RHS): foliage favours nitrogen, blooms favour phosphorus, and succulents
    // need a low-nitrogen "cactus" blend to avoid soft, stretched growth.
    private func targetNPK(for plant: PlantType) -> String {
        switch plant {
        case .foliage:   return "3-1-2 NPK (high N)"
        case .flowering: return "1-3-2 NPK (high P)"
        case .succulent: return "2-7-7 NPK (low N)"
        }
    }

    // Dilution at 1/2 strength of a 10-10-10 liquid feed delivers ~150-200 ppm N,
    // matching the EC range UMass / Ball published for indoor foliage plants.
    var recommendation: (dilution: String, frequency: String, note: String, color: Color) {
        if season == .fallWinter {
            return ("None", "Paused", "Most plants rest in winter — soil microbial activity and root uptake drop ~60%. Avoid fertilizing to prevent salt buildup (EC creep) and leggy growth.", .claudeSecondaryText)
        }

        let npk = targetNPK(for: plantType)

        switch (fertilizerType, plantType) {
        case (.liquid, .succulent):
            return ("1/4 Strength", "Every 4-6 weeks", "Succulents are light feeders. Target \(npk) — high N causes soft, stretched growth. Dilute to ~75-100 ppm N to avoid root burn.", .orange)
        case (.liquid, .foliage):
            return ("1/2 Strength", "Every 2-3 weeks", "Aim for \(npk) at ~150-200 ppm N. This is the EC range commercial growers use for tropical foliage.", .green)
        case (.liquid, .flowering):
            return ("Full Strength", "Every 2 weeks", "Bloom phase. Target \(npk) at ~200-250 ppm — phosphorus drives bud formation and flower retention.", .pink)

        case (.granular, .succulent):
            return ("1/4 Amount", "Once per season", "Top dress ~2 g per 4\" pot. Target \(npk). Keep granules ≥1\" from the stem to prevent fertilizer burn.", .orange)
        case (.granular, .foliage):
            return ("1/2 Amount", "Monthly", "Mix into the top 1\" of soil and water in deeply. Target \(npk) — typical dose ~5 g per 6\" pot.", .green)
        case (.granular, .flowering):
            return ("Standard Amount", "Monthly", "Target \(npk). Follow label rate; ~7 g per 6\" pot is typical for a 5-10-10 bloom formula.", .pink)

        case (.slowRelease, .succulent):
            return ("Low Dose", "Once in Spring", "Use a half-rate coated NPK like Osmocote 14-14-14 → ~1 g per 4\" pot. Target \(npk). Releases over ~6 months.", .orange)
        case (.slowRelease, .foliage):
            return ("Standard Dose", "Every 3-6 months", "Label rate of a coated 18-6-12 or similar. Target \(npk) — ~3 g per 6\" pot. Steady release matches indoor light levels well.", .green)
        case (.slowRelease, .flowering):
            return ("Standard Dose", "Every 3 months", "Use a bloom-coated formula. Target \(npk) — refresh as soon as new buds appear so phosphorus stays available.", .pink)
        }
    }
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Fertilizer Guide",
                    subtitle: "Precision nutrition for every growth stage",
                    trailingActions: AnyView(
                        Button(action: { showInfoSheet = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.claudePrimaryText.opacity(0.8))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.green.opacity(0.1)))
                        }
                    ),
                    showBackButton: true
                )
                
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                        
                        // Inputs Section
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Nutrition Parameters", icon: "flask.fill")
                            
                            VStack(spacing: 16) {
                                // Fertilizer Type Selection
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(FertilizerType.allCases) { type in
                                            FertilizerToggle(type: type, isSelected: fertilizerType == type) {
                                                fertilizerType = type
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }
                                
                                // Plant Type Selection
                                HStack(spacing: 12) {
                                    ForEach(PlantType.allCases) { type in
                                        Button(action: { plantType = type }) {
                                            VStack(spacing: 8) {
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 18))
                                                Text(type.rawValue)
                                                    .font(.claudeSans(size: 13, weight: .bold))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(plantType == type ? Color.claudeAccent.opacity(0.1) : Color.claudeSecondaryBackground)
                                            .foregroundColor(plantType == type ? .claudeAccent : .claudeSecondaryText)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(plantType == type ? Color.claudeAccent.opacity(0.3) : Color.claudeBorder, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(InteractiveCardButtonStyle())
                                    }
                                }
                                
                                // Season Toggle
                                CustomSegmentedToggle(selection: $season)
                            }
                            .padding(20)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                        
                        // Result Display
                        VStack(spacing: 32) {
                            VStack(spacing: 8) {
                                Text("RECOMMENDED PROTOCOL")
                                    .font(.claudeSans(size: 11, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(2)
                                
                                Text(recommendation.dilution)
                                    .font(.claudeSerif(size: 36, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                            }
                            
                            HStack(spacing: 0) {
                                ResultStatItem(title: "Frequency", value: recommendation.frequency, icon: "calendar", color: .purple)
                                Divider().frame(height: 40).padding(.horizontal, 24)
                                ResultStatItem(title: "Status", value: season == .springSummer ? "Active Growth" : "Dormancy", icon: "timer", color: recommendation.color)
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(recommendation.color.opacity(0.1))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(recommendation.color)
                                    }
                                    
                                    Text(recommendation.note)
                                        .font(.claudeSans(size: 15))
                                        .foregroundColor(.claudeSecondaryText)
                                        .lineSpacing(4)
                                }
                                .padding(20)
                                .background(Color.claudeBackground.opacity(0.5))
                                .cornerRadius(20)
                            }
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                Color.claudeSecondaryBackground
                                if season == .springSummer {
                                    LinearGradient(colors: [recommendation.color.opacity(0.08), .clear], startPoint: .topTrailing, endPoint: .bottomLeading)
                                }
                            }
                        )
                        .cornerRadius(32)
                        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.claudeBorder, lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Pro Tip
                        HStack(spacing: 16) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pro Tip")
                                    .font(.claudeSans(size: 14, weight: .bold))
                                    .foregroundColor(.claudePrimaryText)
                                Text("Always water your plants BEFORE fertilizing to protect sensitive roots from high salt concentrations.")
                                    .font(.claudeSans(size: 13))
                                    .foregroundColor(.claudeSecondaryText)
                            }
                        }
                        .padding(24)
                        .background(Color.yellow.opacity(0.05))
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
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
            FertilizerGuideInfoSheet()
        }
    }
}

// MARK: - Supporting Components

struct FertilizerToggle: View {
    let type: FertilizerCalculatorView.FertilizerType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                Text(type.rawValue)
            }
            .font(.claudeSans(size: 14, weight: .medium))
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.blue : Color.claudeBackground)
            .foregroundColor(isSelected ? .white : .claudePrimaryText)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.claudeBorder, lineWidth: 1)
            )
        }
        .buttonStyle(BubblingButtonStyle())
    }
}

struct CustomSegmentedToggle: View {
    @Binding var selection: FertilizerCalculatorView.Season
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(FertilizerCalculatorView.Season.allCases) { item in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = item
                    }
                }) {
                    Text(item.rawValue)
                        .font(.claudeSans(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(selection == item ? .claudePrimaryText : .claudeSecondaryText)
                        .background {
                            if selection == item {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.claudeBackground)
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    .matchedGeometryEffect(id: "segment", in: animation)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(Color.claudeBorder.opacity(0.3))
        .cornerRadius(14)
    }
}

struct ResultStatItem: View {
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
                Text(title.uppercased())
                    .font(.claudeSans(size: 10, weight: .bold))
                    .foregroundColor(.claudeSecondaryText)
                    .tracking(1)
            }
            Text(value)
                .font(.claudeSans(size: 16, weight: .bold))
                .foregroundColor(.claudePrimaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Info Sheet View
struct FertilizerGuideInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How the Fertilizer Guide Works")
                                .font(.claudeSerif(size: 32, weight: .bold))
                                .foregroundColor(.claudePrimaryText)
                            
                            Text("Get tailored fertilizer recommendations based on your plant type, preferred fertilizer format, and the current growing season.")
                                .font(.claudeSans(size: 16))
                                .foregroundColor(.claudeSecondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(spacing: 16) {
                            InfoRow(icon: "drop.fill", title: "Fertilizer Types", text: "Liquid fertilizers act fast, granular types release slowly over weeks, and slow-release pellets work for months with minimal effort.", color: .blue)
                            
                            InfoRow(icon: "leaf.fill", title: "Plant Categories", text: "Foliage plants need nitrogen-rich feeds, flowering plants demand more phosphorus, and succulents thrive on minimal, diluted solutions.", color: .green)
                            
                            InfoRow(icon: "snowflake", title: "Seasonal Dormancy", text: "Most houseplants should not be fertilized during fall and winter. Feeding during dormancy causes salt buildup and weak, leggy growth.", color: .cyan)
                            
                            InfoRow(icon: "exclamationmark.triangle.fill", title: "Golden Rule", text: "Always water your plant before fertilizing. Applying nutrients to dry soil can burn delicate root tips and cause lasting damage.", color: .orange)
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
        FertilizerCalculatorView()
    }
}
