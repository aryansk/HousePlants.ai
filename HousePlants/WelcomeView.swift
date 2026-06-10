import SwiftUI

// MARK: - WelcomeView
struct WelcomeView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @State private var currentStep: Int = 0
    @State private var username = ""
    @State private var city = ""
    @State private var country = ""
    @State private var difficulty = "Beginner"
    @State private var petSafeOnly = false
    @State private var selectedGoal: PlantGoal? = nil
    @State private var plantCount: PlantCount? = nil
    @State private var showError = false
    @State private var appearAnimation = false
    @StateObject private var locationManager = LocationManager()
    @Binding var isCompleted: Bool
    
    private let totalSteps = 5 // intro, goal, aboutYou, experience, personalizedPlan
    
    private var sectionLabel: String {
        switch currentStep {
        case 0: return ""
        case 1: return "Step 1 of 3 · Your Goals"
        case 2: return "Step 2 of 3 · About You"
        case 3: return "Step 2 of 3 · About You"
        case 4: return "Step 3 of 3 · Your Plan"
        default: return ""
        }
    }
    
    var body: some View {
        ZStack {
            backgroundView.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if currentStep > 0 && currentStep < 4 {
                    headerView
                }
                
                Group {
                    switch currentStep {
                    case 0: introStep
                    case 1: goalStep
                    case 2: profileStep
                    case 3: experienceStep
                    case 4: personalizedPlanStep
                    default: introStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(currentStep)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentStep)
                
                if currentStep > 0 && currentStep < 4 {
                    navigationControls
                }
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { appearAnimation = true } }
    }
    
    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            Color.claudeBackground
            Circle()
                .fill(Color.claudeAccent.opacity(0.05))
                .frame(width: 400, height: 400)
                .offset(x: 200, y: -300)
                .blur(radius: 80)
            Circle()
                .fill(Color.claudeSecondaryText.opacity(0.05))
                .frame(width: 300, height: 300)
                .offset(x: -150, y: 400)
                .blur(radius: 60)
        }
    }
    
    // MARK: - Header with chunked progress
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text(sectionLabel)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Button(action: { skipOnboarding() }) {
                    Text("Skip")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            // 3-section progress (goals, about you, plan)
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { section in
                    let sectionProgress: CGFloat = {
                        switch section {
                        case 0: return currentStep >= 1 ? 1.0 : 0.0
                        case 1: return currentStep >= 3 ? 1.0 : (currentStep == 2 ? 0.5 : 0.0)
                        case 2: return currentStep >= 4 ? 1.0 : 0.0
                        default: return 0.0
                        }
                    }()
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.claudeBorder)
                            Capsule().fill(Color.claudeAccent)
                                .frame(width: geo.size.width * sectionProgress)
                        }
                    }
                    .frame(height: 6)
                    .animation(.spring(), value: currentStep)
                }
            }
            .padding(.horizontal, 30)
        }
    }
    
    // MARK: - Navigation
    private var navigationControls: some View {
        HStack(spacing: 20) {
            if currentStep > 1 {
                Button(action: {
                    withAnimation { currentStep -= 1 }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundColor(Color.claudeAccent)
                        .frame(width: 56, height: 56)
                        .background(Circle().stroke(Color.claudeAccent.opacity(0.3), lineWidth: 2))
                }
                .buttonStyle(BubblingButtonStyle())
            }
            
            Button(action: { advanceStep() }) {
                HStack {
                    Text(currentStep == 3 ? "See My Plan" : "Continue")
                        .font(.headline.bold())
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 16).fill(canAdvance ? Color.claudeAccent : Color.claudeAccent.opacity(0.4)))
            }
            .buttonStyle(BubblingButtonStyle())
            .disabled(!canAdvance)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
    }
    
    private var canAdvance: Bool {
        switch currentStep {
        case 1: return selectedGoal != nil
        case 2: return !username.isEmpty && !city.isEmpty && !country.isEmpty
        case 3: return true
        default: return true
        }
    }
    
    private func advanceStep() {
        if currentStep == 2 && (username.isEmpty || city.isEmpty || country.isEmpty) {
            withAnimation { showError = true }
            return
        }
        showError = false
        withAnimation { currentStep += 1 }
    }
    
    private func skipOnboarding() {
        saveUserInfo()
        withAnimation { isCompleted = true }
    }
    
    func saveUserInfo() {
        dataLoader.updateProfile(username: username.isEmpty ? "Plant Lover" : username, city: city.isEmpty ? "Unknown" : city, country: country.isEmpty ? "Unknown" : country)
        dataLoader.updatePreferences(difficulty: difficulty, petSafeOnly: petSafeOnly, notifyOnSundays: false)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        if let goal = selectedGoal {
            UserDefaults.standard.set(goal.rawValue, forKey: "plantGoal")
        }
        if let count = plantCount {
            UserDefaults.standard.set(count.rawValue, forKey: "plantCount")
        }
    }
    
    // MARK: - Step 0: Outcome-First Intro
    private var introStep: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 28) {
                Image("onboarding_1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 10)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 30)
                
                VStack(spacing: 14) {
                    Text("Never Lose a\nPlant Again")
                        .font(.claudeSerif(size: 36, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                        .multilineTextAlignment(.center)
                        .opacity(appearAnimation ? 1 : 0)
                    
                    Text("Join 50,000+ plant parents who've turned\nbrown thumbs into green jungles.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(appearAnimation ? 1 : 0)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: { withAnimation { currentStep = 1 } }) {
                    Text("Let's Get Started")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.claudeAccent))
                        .shadow(color: Color.claudeAccent.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(BubblingButtonStyle())
                
                Button(action: { skipOnboarding() }) {
                    Text("I'll explore on my own")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Step 1: What's Your Goal (Personalization Q1)
    private var goalStep: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What brings you here?")
                            .font(.claudeSerif(size: 28, weight: .bold))
                            .foregroundColor(Color.claudePrimaryText)
                        
                        Text("Pick the one that sounds most like you — we'll tailor everything around it.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(PlantGoal.allCases) { goal in
                            Button(action: { withAnimation(.spring(response: 0.3)) { selectedGoal = goal } }) {
                                HStack(spacing: 16) {
                                    Image(systemName: goal.icon)
                                        .font(.title2)
                                        .foregroundColor(selectedGoal == goal ? .white : goal.color)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle().fill(selectedGoal == goal ? goal.color : goal.color.opacity(0.12))
                                        )
                                    
                                    Text(goal.rawValue)
                                        .font(.body.bold())
                                        .foregroundColor(selectedGoal == goal ? Color.claudePrimaryText : Color.claudeSecondaryText)
                                    
                                    Spacer()
                                    
                                    if selectedGoal == goal {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.claudeAccent)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedGoal == goal ? Color.claudeSecondaryBackground : Color.claudeSecondaryBackground.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedGoal == goal ? Color.claudeAccent : Color.claudeBorder, lineWidth: selectedGoal == goal ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .frame(width: geo.size.width, alignment: .leading)
            }
        }
    }
    
    // MARK: - Step 2: Tell Us About You (Profile — Human Copy)
    private var profileStep: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    Image("onboarding_2")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Tell us about yourself")
                                .font(.claudeSerif(size: 24, weight: .bold))
                                .foregroundColor(Color.claudePrimaryText)
                            
                            Spacer()
                            
                            Button(action: {
                                locationManager.requestLocation()
                            }) {
                                HStack(spacing: 4) {
                                    if locationManager.isUpdating {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 12))
                                    }
                                    Text("Auto-detect")
                                        .font(.claudeSans(size: 12, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.claudeAccent)
                                .cornerRadius(20)
                            }
                        }
                        
                        Text("So we can personalize your care tips and suggestions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .onChange(of: locationManager.cityName) { _, newValue in
                        if let newValue = newValue { city = newValue }
                    }
                    .onChange(of: locationManager.countryName) { _, newValue in
                        if let newValue = newValue { country = newValue }
                    }
                    
                    ClaudeTextField(title: "What should we call you?", placeholder: "e.g. Robin", text: $username, icon: "person")
                    
                    HStack(alignment: .top, spacing: 15) {
                        VStack(alignment: .leading, spacing: 10) {
                            ClaudeCitySearchField(title: "Your City", placeholder: "London", text: $city, icon: "mappin.circle") { cityName, countryName in
                                city = cityName
                                country = countryName
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        ClaudeTextField(title: "Country", placeholder: "UK", text: $country, icon: "globe")
                            .frame(maxWidth: .infinity)
                    }
                    
                    if showError {
                        Label("We need these details to personalize your experience", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .frame(width: geo.size.width, alignment: .leading)
            }
        }
    }
    
    // MARK: - Step 3: Experience & Quick Preferences
    private var experienceStep: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    // Plant count question
                    VStack(alignment: .leading, spacing: 14) {
                        Text("How many plants do you have?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(PlantCount.allCases) { count in
                                Button(action: { withAnimation { plantCount = count } }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: count.icon)
                                            .font(.title2)
                                        Text(count.rawValue)
                                            .font(.caption.bold())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(plantCount == count ? Color.claudeAccent : Color.claudeSecondaryBackground)
                                    .foregroundColor(plantCount == count ? .white : Color.claudePrimaryText)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(plantCount == count ? Color.claudeAccent : Color.claudeBorder, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Experience level
                    VStack(alignment: .leading, spacing: 14) {
                        Text("How would you describe yourself?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        let levels = ["Beginner", "Enthusiast", "Botany Pro"]
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], alignment: .leading, spacing: 12) {
                            ForEach(levels, id: \.self) { level in
                                Button(action: { difficulty = level }) {
                                    Text(level)
                                        .font(.subheadline.bold())
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(difficulty == level ? Color.claudeAccent : Color.claudeSecondaryBackground)
                                        .foregroundColor(difficulty == level ? .white : Color.claudePrimaryText)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(difficulty == level ? Color.claudeAccent : Color.claudeBorder, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Pet-safe toggle (kept here — relevant context)
                    Toggle(isOn: $petSafeOnly) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🐶 I have pets at home")
                                .font(.body.bold())
                            Text("We'll flag any toxic plants for you.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.claudeAccent))
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .frame(width: geo.size.width, alignment: .leading)
            }
        }
    }
    
    // MARK: - Step 4: Personalized Outcome with Real Plant Recommendations
    private var personalizedPlanStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Hero header
                ZStack(alignment: .bottomTrailing) {
                    Image("onboarding_3")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: .black.opacity(0.12), radius: 15, x: 0, y: 10)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.claudeAccent)
                        .clipShape(Circle())
                        .offset(x: -10, y: 10)
                        .shadow(color: Color.claudeAccent.opacity(0.3), radius: 8)
                }
                
                VStack(spacing: 8) {
                    Text(personalizedTitle)
                        .font(.claudeSerif(size: 26, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(personalizedSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // Personalized plan bullets
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(personalizedBullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "sparkle")
                                .font(.caption)
                                .foregroundColor(Color.claudeAccent)
                                .padding(.top, 2)
                            Text(bullet)
                                .font(.subheadline)
                                .foregroundColor(Color.claudePrimaryText)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.claudeSecondaryBackground)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.claudeBorder, lineWidth: 1))
                )
                
                // MARK: - Recommended Plants Section
                if !recommendedPlants.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "leaf.circle.fill")
                                .foregroundColor(Color.claudeAccent)
                            Text("Recommended for You")
                                .font(.headline.bold())
                                .foregroundColor(Color.claudePrimaryText)
                        }
                        
                        if !city.isEmpty {
                            Text("Based on \(city)'s climate, your \(difficulty.lowercased()) level, and preferences")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ForEach(recommendedPlants.prefix(5)) { plant in
                            RecommendedPlantCard(plant: plant, climateNote: climateNote(for: plant))
                        }
                    }
                }
                
                // CTA
                VStack(spacing: 12) {
                    Button(action: {
                        saveUserInfo()
                        withAnimation(.spring()) { isCompleted = true }
                    }) {
                        Text("Enter Your Jungle 🌿")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.black)
                            .cornerRadius(20)
                            .shadow(radius: 10, y: 5)
                    }
                    .buttonStyle(BubblingButtonStyle())
                    
                    Text("Free · No credit card needed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Recommendation Engine

    private var recommender: OnboardingRecommender {
        OnboardingRecommender(difficulty: difficulty, petSafeOnly: petSafeOnly,
                              goal: selectedGoal, country: country)
    }

    private var recommendedPlants: [Plant] {
        recommender.recommend(from: dataLoader.plants)
    }

    private func climateNote(for plant: Plant) -> String {
        recommender.climateNote(for: plant, city: city)
    }

    // MARK: - Personalized Content Generators
    
    private var personalizedTitle: String {
        let name = username.isEmpty ? "Plant Lover" : username
        switch selectedGoal {
        case .keepAlive: return "You're all set, \(name)!"
        case .growCollection: return "Your jungle awaits, \(name)!"
        case .learnMore: return "Class is in session, \(name)!"
        case .decorate: return "Time to beautify, \(name)!"
        case .none: return "Welcome, \(name)!"
        }
    }
    
    private var personalizedSubtitle: String {
        switch selectedGoal {
        case .keepAlive: return "We've built a care plan to help you keep every leaf thriving."
        case .growCollection: return "We'll help you discover the perfect next addition to your collection."
        case .learnMore: return "Botanical knowledge, simplified. Explore at your own pace."
        case .decorate: return "Curated picks to transform your space into a living masterpiece."
        case .none: return "Your personalized plant care journey is ready."
        }
    }
    
    private var personalizedBullets: [String] {
        var bullets: [String] = []
        
        // Goal-based
        switch selectedGoal {
        case .keepAlive:
            bullets.append("Smart watering reminders so you never over- or under-water")
            bullets.append("Plant doctor to diagnose issues early")
        case .growCollection:
            bullets.append("Discover 200+ species curated by difficulty and style")
            bullets.append("Propagation guides to multiply your favorites")
        case .learnMore:
            bullets.append("Deep-dive care sheets with botanical details")
            bullets.append("Origin explorer with native habitat maps")
        case .decorate:
            bullets.append("Browse plants by aesthetic and room compatibility")
            bullets.append("Seasonal care calendar to keep everything picture-perfect")
        case .none:
            bullets.append("Personalized care tips based on your location")
        }
        
        // Experience-based
        if difficulty == "Beginner" {
            bullets.append("Beginner-friendly guidance — no jargon, just results")
        } else if difficulty == "Botany Pro" {
            bullets.append("Advanced tools: soil mix builder, fertilizer calculator")
        }
        
        // Pet-safe
        if petSafeOnly {
            bullets.append("All suggestions filtered for pet safety 🐾")
        }
        
        // Location-based
        if !city.isEmpty {
            let zone = recommender.climateZone
            let desc: String = {
                switch zone {
                case "tropical": return "warm, humid"
                case "arid": return "hot, dry"
                case "mediterranean": return "warm, sunny"
                case "cold": return "cool, seasonal"
                default: return "temperate"
                }
            }()
            bullets.append("Care tips optimized for \(city)'s \(desc) climate")
        }
        
        return bullets
    }
}

#Preview {
    WelcomeView(isCompleted: .constant(false))
        .environmentObject(DataLoader())
}

