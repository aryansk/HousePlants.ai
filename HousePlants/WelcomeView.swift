import SwiftUI

// MARK: - WelcomeView
struct WelcomeView: View {
    @Environment(DataLoader.self) var dataLoader
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentStep: Int = 0
    @State private var username = ""
    @State private var city = ""
    @State private var country = ""
    @State private var difficulty = "Beginner"
    @State private var petSafeOnly = false
    @State private var selectedGoal: PlantGoal? = nil
    @State private var plantCount: PlantCount? = nil
    @State private var appearAnimation = false
    @State private var planReady = false
    @State private var visibleCraftingSteps = 0
    @State private var remindersOptedIn = false
    @StateObject private var locationManager = LocationManager()
    @Binding var isCompleted: Bool

    private let totalSteps = 5 // intro, goal, aboutYou, experience, personalizedPlan

    private var sectionLabel: String {
        switch currentStep {
        case 1: return "Step 1 of 3 · Your Goals"
        case 2, 3: return "Step 2 of 3 · About You"
        case 4: return "Step 3 of 3 · Your Plan"
        default: return ""
        }
    }

    private var trimmedName: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    HapticManager.shared.playImpact(style: .light)
                    withAnimation { currentStep -= 1 }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundColor(IndieHousePalette.ink)
                        .frame(width: 56, height: 56)
                        .background(Color.claudeSecondaryBackground)
                        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.5))
                        .background(IndieHousePalette.ink.offset(x: 3, y: 3))
                }
                .buttonStyle(BubblingButtonStyle())
                .accessibilityLabel("Back")
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
                .background(canAdvance ? IndieHousePalette.blue : IndieHousePalette.blue.opacity(0.4))
                .overlay(Rectangle().stroke(IndieHousePalette.ink.opacity(canAdvance ? 1 : 0.4), lineWidth: 1.5))
                .background(IndieHousePalette.ink.opacity(canAdvance ? 1 : 0).offset(x: 4, y: 4))
            }
            .buttonStyle(BubblingButtonStyle())
            .disabled(!canAdvance)
            .animation(.easeOut(duration: 0.2), value: canAdvance)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
    }

    private var canAdvance: Bool {
        switch currentStep {
        case 1: return selectedGoal != nil
        case 2: return !trimmedName.isEmpty
        default: return true
        }
    }

    private func advanceStep() {
        guard canAdvance else { return }
        dismissKeyboard()
        HapticManager.shared.playImpact(style: .light)
        withAnimation { currentStep += 1 }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func skipOnboarding() {
        saveUserInfo()
        withAnimation { isCompleted = true }
    }

    /// Selecting a goal answers the whole step, so after a beat we advance automatically
    /// (Duolingo-style single-select). Changing the answer cancels the pending advance.
    private func selectGoal(_ goal: PlantGoal) {
        HapticManager.shared.playSelection()
        let isFirstSelection = selectedGoal == nil
        withAnimation(.spring(response: 0.3)) { selectedGoal = goal }
        guard isFirstSelection else { return }
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard currentStep == 1, selectedGoal == goal else { return }
            advanceStep()
        }
    }

    private var levelCaption: String {
        switch difficulty {
        case "Beginner": return "We'll keep it simple — forgiving plants, zero jargon."
        case "Enthusiast": return "You know your pothos from your philodendron. We'll go deeper."
        case "Botany Pro": return "Latin names, soil science, the works."
        default: return ""
        }
    }

    private var goalAffirmation: String? {
        switch selectedGoal {
        case .keepAlive: return "Rescue mission accepted — no more crispy leaves."
        case .growCollection: return "A jungle in the making. We love to see it."
        case .learnMore: return "Curiosity is the best fertilizer."
        case .decorate: return "Green is the best accent color."
        case .none: return nil
        }
    }

    func saveUserInfo() {
        let name = trimmedName
        let savedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        dataLoader.updateProfile(username: name.isEmpty ? "Plant Lover" : name, city: savedCity.isEmpty ? "Unknown" : savedCity, country: savedCountry.isEmpty ? "Unknown" : savedCountry)
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
                ZStack(alignment: .topLeading) {
                    Image("onboarding_1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .clipped()
                        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 2))
                        .background(IndieHousePalette.green.offset(x: 8, y: 9))

                    IndieCutLabel(text: "The plant workshop", color: IndieHousePalette.yellow)
                        .offset(x: -8, y: 18)

                    Rectangle()
                        .fill(IndieHousePalette.paperRaised.opacity(0.82))
                        .frame(width: 92, height: 25)
                        .overlay(Rectangle().stroke(IndieHousePalette.ink.opacity(0.15), lineWidth: 1))
                        .rotationEffect(.degrees(-7))
                        .offset(x: 125, y: -10)
                }
                .padding(.trailing, 8)
                .padding(.bottom, 9)
                .rotationEffect(.degrees(-0.8))
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 30)
                .animation(.spring(response: 0.7, dampingFraction: 0.85), value: appearAnimation)

                VStack(spacing: 14) {
                    IndieCutLabel(text: "Care notes · Issue 01", color: IndieHousePalette.pink)
                        .opacity(appearAnimation ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.15), value: appearAnimation)

                    Text("Never lose a\nplant again.")
                        .font(.claudeSerif(size: 42, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                        .multilineTextAlignment(.center)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 12)
                        .animation(.easeOut(duration: 0.5).delay(0.25), value: appearAnimation)

                    Text("A thoughtful little field guide for turning brown thumbs into green rooms.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(appearAnimation ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.35), value: appearAnimation)

                    Text("200+ species · smart reminders · plant doctor")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.0)
                        .opacity(appearAnimation ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.45), value: appearAnimation)
                }
            }
            .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    HapticManager.shared.playImpact(style: .light)
                    withAnimation { currentStep = 1 }
                }) {
                    HStack(spacing: 10) {
                        Text("Come inside")
                        Image(systemName: "arrow.right")
                    }
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(IndieHousePalette.blue)
                        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 2))
                        .background(IndieHousePalette.ink.offset(x: 5, y: 5))
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
            .opacity(appearAnimation ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.55), value: appearAnimation)
        }
    }

    // MARK: - Step 1: What's Your Goal (Personalization Q1)
    private var goalStep: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        IndieCutLabel(text: "Room 01 · Your goals", color: IndieHousePalette.green)
                        Text("What brings you here?")
                            .font(.claudeSerif(size: 28, weight: .bold))
                            .foregroundColor(Color.claudePrimaryText)

                        Text("Pick the one that sounds most like you — we'll tailor everything around it.")
                            .font(.body)
                            .foregroundColor(.secondary)

                        if let affirmation = goalAffirmation {
                            Label(affirmation, systemImage: "sparkles")
                                .font(.subheadline.bold())
                                .foregroundColor(Color.claudeAccent)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.spring(response: 0.35), value: selectedGoal)

                    VStack(spacing: 12) {
                        ForEach(PlantGoal.allCases) { goal in
                            Button(action: { selectGoal(goal) }) {
                                HStack(spacing: 16) {
                                    Image(systemName: goal.icon)
                                        .font(.title2)
                                        .foregroundColor(selectedGoal == goal ? .white : goal.color)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle().fill(selectedGoal == goal ? goal.color : goal.color.opacity(0.12))
                                        )

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(goal.rawValue)
                                            .font(.body.bold())
                                            .foregroundColor(Color.claudePrimaryText)
                                        Text(goal.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer()

                                    if selectedGoal == goal {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.claudeAccent)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding(16)
                                .indiePaperCard(
                                    fill: Color.claudeSecondaryBackground,
                                    border: selectedGoal == goal ? IndieHousePalette.blue : IndieHousePalette.ink,
                                    shadow: selectedGoal == goal ? IndieHousePalette.yellow : IndieHousePalette.ink,
                                    rotation: selectedGoal == goal ? -0.5 : 0,
                                    cornerRadius: 2,
                                    shadowOffset: selectedGoal == goal ? 5 : 3
                                )
                                .padding(.trailing, 5)
                                .padding(.bottom, 5)
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
                        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 2))
                        .background(IndieHousePalette.orange.offset(x: 6, y: 7))
                        .padding(.trailing, 6)
                        .padding(.bottom, 7)
                        .rotationEffect(.degrees(0.6))

                    VStack(alignment: .leading, spacing: 10) {
                        IndieCutLabel(text: "Room 02 · About you", color: IndieHousePalette.orange)
                        Text("Tell us about yourself")
                            .font(.claudeSerif(size: 28, weight: .bold))
                            .foregroundColor(Color.claudePrimaryText)

                        Text("Just a name to get started — add your city and we'll tune care tips to your local climate.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .onChange(of: locationManager.cityName) { _, newValue in
                        if let newValue = newValue { city = newValue }
                    }
                    .onChange(of: locationManager.countryName) { _, newValue in
                        if let newValue = newValue { country = newValue }
                    }

                    ClaudeTextField(title: "What should we call you?", placeholder: "e.g. Robin", text: $username, icon: "person")

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Where do your plants live?")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text("Optional")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.claudeBorder.opacity(0.25)))

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
                                .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.2))
                                .background(IndieHousePalette.ink.offset(x: 2, y: 2))
                            }
                            .buttonStyle(BubblingButtonStyle())
                        }

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
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .frame(width: geo.size.width, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Step 3: Experience & Quick Preferences
    private var experienceStep: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 10) {
                        IndieCutLabel(text: "Room 03 · Your plants", color: IndieHousePalette.pink)
                        Text("Your plant life today")
                            .font(.claudeSerif(size: 28, weight: .bold))
                            .foregroundColor(Color.claudePrimaryText)
                    }

                    // Plant count question
                    VStack(alignment: .leading, spacing: 14) {
                        Text("How many plants do you have?")
                            .font(.headline)
                            .foregroundColor(.primary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(PlantCount.allCases) { count in
                                Button(action: {
                                    HapticManager.shared.playSelection()
                                    withAnimation(.spring(response: 0.3)) { plantCount = count }
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: count.icon)
                                            .font(.title2)
                                        Text(count.rawValue)
                                            .font(.caption.bold())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .foregroundColor(plantCount == count ? .white : Color.claudePrimaryText)
                                    .indiePaperCard(
                                        fill: plantCount == count ? IndieHousePalette.blue : Color.claudeSecondaryBackground,
                                        border: IndieHousePalette.ink,
                                        shadow: plantCount == count ? IndieHousePalette.yellow : IndieHousePalette.ink,
                                        cornerRadius: 2,
                                        shadowOffset: plantCount == count ? 4 : 3
                                    )
                                    .padding(.trailing, 4)
                                    .padding(.bottom, 4)
                                }
                                .buttonStyle(.plain)
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
                                Button(action: {
                                    HapticManager.shared.playSelection()
                                    withAnimation(.spring(response: 0.3)) { difficulty = level }
                                }) {
                                    Text(level)
                                        .font(.subheadline.bold())
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .frame(maxWidth: .infinity)
                                        .foregroundColor(difficulty == level ? .white : Color.claudePrimaryText)
                                        .indiePaperCard(
                                            fill: difficulty == level ? IndieHousePalette.blue : Color.claudeSecondaryBackground,
                                            border: IndieHousePalette.ink,
                                            shadow: difficulty == level ? IndieHousePalette.yellow : IndieHousePalette.ink,
                                            cornerRadius: 2,
                                            shadowOffset: difficulty == level ? 4 : 3
                                        )
                                        .padding(.trailing, 4)
                                        .padding(.bottom, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text(levelCaption)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .id(difficulty)
                            .transition(.opacity)
                            .animation(.easeOut(duration: 0.25), value: difficulty)
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
                    .padding(16)
                    .indiePaperCard(
                        fill: Color.claudeSecondaryBackground,
                        border: IndieHousePalette.ink,
                        shadow: IndieHousePalette.ink,
                        cornerRadius: 2,
                        shadowOffset: 3
                    )
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                    .onChange(of: petSafeOnly) { _, _ in
                        HapticManager.shared.playSelection()
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .frame(width: geo.size.width, alignment: .leading)
            }
        }
    }

    // MARK: - Step 4: Crafting interstitial → Personalized Plan

    private var craftingItems: [String] {
        var items = ["Reading your goal"]
        if city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append("Setting up climate defaults")
        } else {
            items.append("Checking \(city)'s climate")
        }
        items.append("Matching \(difficulty.lowercased())-friendly plants")
        if petSafeOnly {
            items.append("Filtering out pet-toxic plants")
        }
        items.append("Assembling your care plan")
        return items
    }

    private var personalizedPlanStep: some View {
        Group {
            if planReady {
                planRevealView
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                craftingView
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: planReady)
    }

    private var craftingView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 14) {
                IndieCutLabel(text: "The potting bench", color: IndieHousePalette.green)
                Text("Potting up\nyour plan…")
                    .font(.claudeSerif(size: 34, weight: .bold))
                    .foregroundStyle(Color.claudePrimaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(craftingItems.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        Image(systemName: index < visibleCraftingSteps ? "checkmark.circle.fill" : "circle.dotted")
                            .font(.body)
                            .foregroundColor(index < visibleCraftingSteps ? IndieHousePalette.green : Color.claudeSecondaryText.opacity(0.5))
                        Text(item)
                            .font(.subheadline.bold())
                            .foregroundColor(index < visibleCraftingSteps ? Color.claudePrimaryText : Color.claudeSecondaryText.opacity(0.6))
                    }
                    .opacity(index <= visibleCraftingSteps ? 1 : 0.35)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .indiePaperCard(
                fill: Color.claudeSecondaryBackground,
                border: IndieHousePalette.ink,
                shadow: IndieHousePalette.ink,
                rotation: -0.5,
                cornerRadius: 2,
                shadowOffset: 4
            )
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .task {
            guard !planReady else { return }
            if reduceMotion {
                visibleCraftingSteps = craftingItems.count
                try? await Task.sleep(nanoseconds: 600_000_000)
                planReady = true
                HapticManager.shared.playNotification(type: .success)
                return
            }
            for index in 0..<craftingItems.count {
                try? await Task.sleep(nanoseconds: 450_000_000)
                withAnimation(.spring(response: 0.35)) { visibleCraftingSteps = index + 1 }
                HapticManager.shared.playSelection()
            }
            try? await Task.sleep(nanoseconds: 550_000_000)
            planReady = true
            HapticManager.shared.playNotification(type: .success)
        }
    }

    private var planRevealView: some View {
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
                        .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 2))
                        .background(IndieHousePalette.green.offset(x: 7, y: 8))

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(IndieHousePalette.green)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(IndieHousePalette.ink, lineWidth: 1.5))
                        .offset(x: -12, y: 12)
                }
                .padding(.trailing, 7)
                .padding(.bottom, 8)
                .rotationEffect(.degrees(-0.6))

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

                // Answer summary — makes the personalization visible
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(setupSummaryChips, id: \.self) { chip in
                            Text(chip)
                                .font(.caption.bold())
                                .foregroundColor(Color.claudePrimaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.claudeSecondaryBackground)
                                .overlay(Capsule().stroke(IndieHousePalette.ink.opacity(0.5), lineWidth: 1))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .indiePaperCard(
                    fill: Color.claudeSecondaryBackground,
                    border: IndieHousePalette.ink,
                    shadow: IndieHousePalette.ink,
                    cornerRadius: 2,
                    shadowOffset: 4
                )
                .padding(.trailing, 4)
                .padding(.bottom, 4)

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

                        Text(city.isEmpty
                             ? "Tap + to add one now — we'll start its watering schedule right away."
                             : "Matched to \(city)'s climate and your \(difficulty.lowercased()) level. Tap + to add one now — we'll start its watering schedule right away.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(recommendedPlants.prefix(5)) { plant in
                            RecommendedPlantCard(
                                plant: plant,
                                climateNote: climateNote(for: plant),
                                isAdded: dataLoader.myJungleLookup[plant.id] != nil,
                                onAdd: {
                                    HapticManager.shared.playImpact(style: .medium)
                                    withAnimation(.spring(response: 0.3)) {
                                        dataLoader.toggleJungle(plant: plant)
                                    }
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Soft notification ask — the OS prompt only fires if they opt in here
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title2)
                            .foregroundColor(IndieHousePalette.orange)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Never miss a watering")
                                .font(.subheadline.bold())
                                .foregroundColor(Color.claudePrimaryText)
                            Text("One gentle nudge when a plant is thirsty. No spam, ever.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if remindersOptedIn {
                        Label("Reminders on — we'll take it from here", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundColor(IndieHousePalette.green)
                            .transition(.opacity)
                    } else {
                        Button(action: {
                            HapticManager.shared.playNotification(type: .success)
                            UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                            NotificationScheduler.shared.requestAuthorization()
                            withAnimation(.spring(response: 0.3)) { remindersOptedIn = true }
                        }) {
                            Text("Remind me")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(IndieHousePalette.blue)
                                .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 1.4))
                                .background(IndieHousePalette.ink.offset(x: 3, y: 3))
                        }
                        .buttonStyle(BubblingButtonStyle())
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .indiePaperCard(
                    fill: Color.claudeSecondaryBackground,
                    border: IndieHousePalette.ink,
                    shadow: IndieHousePalette.orange,
                    rotation: -0.4,
                    cornerRadius: 2,
                    shadowOffset: 4
                )
                .padding(.trailing, 4)
                .padding(.bottom, 4)

                // CTA
                VStack(spacing: 14) {
                    Button(action: {
                        saveUserInfo()
                        HapticManager.shared.playNotification(type: .success)
                        withAnimation(.spring()) { isCompleted = true }
                    }) {
                        Text("Enter Your Jungle 🌿")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(IndieHousePalette.blue)
                            .overlay(Rectangle().stroke(IndieHousePalette.ink, lineWidth: 2))
                            .background(IndieHousePalette.ink.offset(x: 5, y: 5))
                    }
                    .buttonStyle(BubblingButtonStyle())

                    Button(action: {
                        HapticManager.shared.playImpact(style: .light)
                        withAnimation { currentStep = 3 }
                    }) {
                        Text("Not quite right? Adjust my answers")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(addedPlantCount > 0
                         ? "Your jungle starts with \(addedPlantCount) plant\(addedPlantCount == 1 ? "" : "s") · Free · No credit card needed"
                         : "Free · No credit card needed")
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

    private var setupSummaryChips: [String] {
        var chips: [String] = []
        if let goal = selectedGoal { chips.append("🎯 \(goal.rawValue)") }
        chips.append("🌱 \(difficulty)")
        if let count = plantCount { chips.append("🪴 \(count.rawValue)") }
        if !city.isEmpty { chips.append("📍 \(city)") }
        if petSafeOnly { chips.append("🐾 Pet-safe only") }
        return chips
    }

    private var addedPlantCount: Int {
        dataLoader.myJungleLookup.count
    }

    private var personalizedTitle: String {
        let name = trimmedName.isEmpty ? "Plant Lover" : trimmedName
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

        // First-plant guidance for brand-new owners
        if plantCount == PlantCount.none {
            bullets.append("A hand-picked first plant that's nearly impossible to kill")
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
        .environment(DataLoader())
}
