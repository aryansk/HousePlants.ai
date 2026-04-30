import SwiftUI

struct ClimateMatcherToolView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @StateObject private var locationManager = LocationManager()
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var difficulty: String = "Beginner"
    @State private var petSafeOnly: Bool = false
    @State private var selectedGoal: PlantGoal = .keepAlive
    
    @State private var showingRecommendations = false
    
    var body: some View {
        ZStack {
            Color.claudeBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ClaudeHeader(
                    title: "Climate Matcher",
                    subtitle: "Find plants that love your home's environment",
                    showBackButton: true
                )
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Location Input Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("LOCATION")
                                    .font(.claudeSans(size: 12, weight: .bold))
                                    .foregroundColor(.claudeSecondaryText)
                                    .tracking(1.5)
                                
                                Spacer()
                                
                                Button(action: {
                                    locationManager.requestLocation()
                                }) {
                                    HStack(spacing: 4) {
                                        if locationManager.isUpdating {
                                            ProgressView().scaleEffect(0.6)
                                        } else {
                                            Image(systemName: "location.fill").font(.system(size: 10))
                                        }
                                        Text("Auto-detect").font(.claudeSans(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.claudeAccent)
                                    .cornerRadius(15)
                                }
                            }
                            .onChange(of: locationManager.cityName) { _, newValue in
                                if let newValue = newValue { city = newValue }
                            }
                            .onChange(of: locationManager.countryName) { _, newValue in
                                if let newValue = newValue { country = newValue }
                            }
                            
                            VStack(spacing: 20) {
                                ClaudeCitySearchField(title: "City", placeholder: "e.g. London", text: $city, icon: "mappin.circle") { cityName, countryName in
                                    city = cityName
                                    country = countryName
                                }
                                
                                ClaudeTextField(title: "Country", placeholder: "e.g. UK", text: $country, icon: "globe")
                            }
                            .padding(20)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                        }
                        
                        // Preferences Section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("PREFERENCES")
                                .font(.claudeSans(size: 12, weight: .bold))
                                .foregroundColor(.claudeSecondaryText)
                                .tracking(1.5)
                            
                            VStack(spacing: 25) {
                                // Goal
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Primary Goal")
                                        .font(.claudeSans(size: 14, weight: .bold))
                                    
                                    Picker("Goal", selection: $selectedGoal) {
                                        ForEach(PlantGoal.allCases) { goal in
                                            Text(goal.rawValue).tag(goal)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.claudeBackground)
                                    .cornerRadius(12)
                                }
                                
                                // Difficulty
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Experience Level")
                                        .font(.claudeSans(size: 14, weight: .bold))
                                    
                                    Picker("Level", selection: $difficulty) {
                                        Text("Beginner").tag("Beginner")
                                        Text("Enthusiast").tag("Enthusiast")
                                        Text("Botany Pro").tag("Botany Pro")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                // Pet Safe
                                Toggle(isOn: $petSafeOnly) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Pet Safe Only")
                                            .font(.claudeSans(size: 14, weight: .bold))
                                        Text("Only show non-toxic species")
                                            .font(.claudeSans(size: 12))
                                            .foregroundColor(.claudeSecondaryText)
                                    }
                                }
                                .tint(Color.claudeAccent)
                            }
                            .padding(24)
                            .background(Color.claudeSecondaryBackground)
                            .cornerRadius(24)
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.claudeBorder, lineWidth: 1))
                        }
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showingRecommendations = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Find My Matches")
                            }
                            .font(.claudeSans(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.claudeAccent)
                            .cornerRadius(18)
                            .shadow(color: Color.claudeAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        
                        if showingRecommendations {
                            RecommendationResultsSection(
                                city: city,
                                country: country,
                                difficulty: difficulty,
                                petSafeOnly: petSafeOnly,
                                selectedGoal: selectedGoal
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Pre-fill from profile if available
            if let profile = dataLoader.userProfile {
                city = profile.locationSettings.city
                country = profile.locationSettings.country
                difficulty = profile.preferences.difficultyLevel
                petSafeOnly = profile.preferences.petSafeOnly
            }
        }
    }
}

struct RecommendationResultsSection: View {
    @EnvironmentObject var dataLoader: DataLoader
    let city: String
    let country: String
    let difficulty: String
    let petSafeOnly: Bool
    let selectedGoal: PlantGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("YOUR MATCHES")
                    .font(.claudeSans(size: 12, weight: .bold))
                    .foregroundColor(.claudeSecondaryText)
                    .tracking(1.5)
                Spacer()
                if !city.isEmpty {
                    Text(city)
                        .font(.claudeSans(size: 10, weight: .bold))
                        .foregroundColor(.claudeAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.claudeAccent.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            VStack(spacing: 16) {
                ForEach(recommendedPlants.prefix(8)) { plant in
                    RecommendedPlantCard(plant: plant, climateNote: climateNote(for: plant))
                }
            }
        }
    }
    
    // Logic duplicated from WelcomeView for consistency
    private var recommendedPlants: [Plant] {
        let allPlants = dataLoader.plants
        guard !allPlants.isEmpty else { return [] }
        
        let userClimate = climateZone(for: country)
        let avgTemp = averageTemp(for: userClimate)
        
        let scored = allPlants.map { plant -> (Plant, Double) in
            var score: Double = 0
            
            let tempRange = parseTempRange(plant.careGuide.temperatureRange)
            if let (low, high) = tempRange {
                if avgTemp >= Double(low) && avgTemp <= Double(high) {
                    score += 40
                } else {
                    let distance = avgTemp < Double(low) ? Double(low) - avgTemp : avgTemp - Double(high)
                    score += max(0, 40 - distance * 4)
                }
            } else {
                score += 20
            }
            
            let plantDiff = plant.careGuide.difficulty.lowercased()
            switch difficulty {
            case "Beginner":
                if plantDiff.contains("very easy") || plantDiff.contains("beginner") { score += 30 }
                else if plantDiff.contains("easy") { score += 25 }
                else if plantDiff.contains("medium") || plantDiff.contains("intermediate") { score += 10 }
            case "Enthusiast":
                if plantDiff.contains("medium") || plantDiff.contains("intermediate") { score += 30 }
                else if plantDiff.contains("easy") { score += 20 }
                else if plantDiff.contains("hard") { score += 15 }
            case "Botany Pro":
                if plantDiff.contains("hard") { score += 30 }
                else if plantDiff.contains("medium") || plantDiff.contains("intermediate") { score += 25 }
                else if plantDiff.contains("easy") { score += 15 }
            default: score += 15
            }
            
            if petSafeOnly {
                score += plant.toxicity.isPetSafe ? 20 : -50
            }
            
            switch selectedGoal {
            case .keepAlive:
                if plantDiff.contains("easy") || plantDiff.contains("very easy") || plantDiff.contains("beginner") { score += 10 }
            case .growCollection:
                if plant.propagation != nil { score += 10 }
            case .learnMore:
                if plant.botanistQuote != nil { score += 5 }
                score += 5
            case .decorate:
                if plant.images.main.count > 0 { score += 10 }
            }
            
            return (plant, score)
        }
        
        return scored
            .filter { petSafeOnly ? $0.0.toxicity.isPetSafe : true }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
    
    private func climateNote(for plant: Plant) -> String {
        let tempRange = parseTempRange(plant.careGuide.temperatureRange)
        let userClimate = climateZone(for: country)
        let avgTemp = averageTemp(for: userClimate)
        
        if let (low, high) = tempRange {
            if avgTemp >= Double(low) && avgTemp <= Double(high) {
                return "Perfect for \(city.isEmpty ? "your" : city + "'s") climate"
            } else if avgTemp < Double(low) {
                return "Best kept indoors during cold months"
            } else {
                return "Provide shade during extreme heat"
            }
        }
        return "Versatile indoor plant"
    }
    
    // Helper methods (cloned from WelcomeView)
    private func parseTempRange(_ range: String) -> (Int, Int)? {
        let numbers = range.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        guard numbers.count >= 2 else { return nil }
        return (numbers[0], numbers[1])
    }
    
    private func climateZone(for country: String) -> String {
        let c = country.lowercased().trimmingCharacters(in: .whitespaces)
        let tropical = ["india", "thailand", "indonesia", "malaysia", "philippines", "vietnam", "singapore", "brazil", "colombia", "nigeria", "kenya", "tanzania", "sri lanka", "mexico", "costa rica"]
        if tropical.contains(c) { return "tropical" }
        let arid = ["saudi arabia", "uae", "egypt", "iraq", "iran", "australia", "morocco"]
        if arid.contains(c) { return "arid" }
        let med = ["italy", "spain", "greece", "portugal", "turkey", "israel", "south africa"]
        if med.contains(c) { return "mediterranean" }
        let cold = ["russia", "canada", "norway", "sweden", "finland", "iceland", "poland"]
        if cold.contains(c) { return "cold" }
        return "temperate"
    }
    
    private func averageTemp(for climate: String) -> Double {
        switch climate {
        case "tropical": return 28
        case "arid": return 32
        case "mediterranean": return 22
        case "cold": return 10
        case "temperate": return 18
        default: return 20
        }
    }
}
