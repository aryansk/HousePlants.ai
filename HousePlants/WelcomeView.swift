import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @State private var currentStep: OnboardingStep = .intro
    @State private var username: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var difficulty: String = "Beginner"
    @State private var petSafeOnly: Bool = false
    @State private var notifyOnSundays: Bool = true
    @State private var showError: Bool = false
    @Binding var isCompleted: Bool
    @Namespace private var animation
    
    enum OnboardingStep: Int, CaseIterable {
        case intro = 0
        case profile = 1
        case experience = 2
        case final = 3
        
        var title: String {
            switch self {
            case .intro: return "Welcome"
            case .profile: return "Profile"
            case .experience: return "Experience"
            case .final: return "Ready"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background Layer
            backgroundView
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header & Progress
                if currentStep != .final {
                    headerView
                }
                
                // Content
                TabView(selection: $currentStep) {
                    IntroStepView()
                        .tag(OnboardingStep.intro)
                    
                    ProfileStepView(username: $username, city: $city, country: $country, showError: showError)
                        .tag(OnboardingStep.profile)
                    
                    ExperienceStepView(difficulty: $difficulty, petSafeOnly: $petSafeOnly, notifyOnSundays: $notifyOnSundays)
                        .tag(OnboardingStep.experience)
                    
                    FinalStepView(isCompleted: $isCompleted, saveAction: saveUserInfo)
                        .tag(OnboardingStep.final)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                
                // Navigation Buttons (Next/Back)
                if currentStep != .final {
                    navigationControls
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var backgroundView: some View {
        ZStack {
            Color.claudeBackground
            
            // Subtle texture or just plain background
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
    
    private var headerView: some View {
        VStack(spacing: 20) {
            HStack {
                Text(currentStep.title)
                    .font(.claudeSerif(size: 34, weight: .bold))
                    .foregroundColor(Color.claudePrimaryText)
                
                Spacer()
                
                Button(action: {
                    withAnimation { isCompleted = true }
                }) {
                    Text("Skip")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            // Progress Bar
            HStack(spacing: 8) {
                ForEach(OnboardingStep.allCases.dropLast(), id: \.self) { step in
                    Capsule()
                        .fill(currentStep.rawValue >= step.rawValue ? Color.claudeAccent : Color.claudeBorder)
                        .frame(height: 6)
                        .frame(maxWidth: .infinity)
                        .animation(.spring(), value: currentStep)
                }
            }
            .padding(.horizontal, 30)
        }
    }
    
    private var navigationControls: some View {
        HStack(spacing: 20) {
            if currentStep != .intro {
                Button(action: {
                    withAnimation { currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .intro }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundColor(Color.claudeAccent)
                        .frame(width: 56, height: 56)
                        .background(Circle().stroke(Color.claudeAccent.opacity(0.3), lineWidth: 2))
                }
                .buttonStyle(BubblingButtonStyle())
            }
            
            Button(action: {
                if validateCurrentStep() {
                    withAnimation { currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? .final }
                }
            }) {
                HStack {
                    Text(currentStep == .experience ? "Finish Setup" : "Continue")
                        .font(.headline.bold())
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.claudeAccent)
                )
            }
            .buttonStyle(BubblingButtonStyle())
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
    }
    
    // MARK: - Validation & Saving
    
    private func validateCurrentStep() -> Bool {
        if currentStep == .profile {
            if username.isEmpty || city.isEmpty || country.isEmpty {
                withAnimation { showError = true }
                return false
            }
        }
        showError = false
        return true
    }
    
    func saveUserInfo() {
        dataLoader.updateProfile(username: username, city: city, country: country)
        dataLoader.updatePreferences(difficulty: difficulty, petSafeOnly: petSafeOnly, notifyOnSundays: notifyOnSundays)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Step Views

struct IntroStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Image card
            VStack(spacing: 24) {
                Image("onboarding_1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 10)
                
                VStack(spacing: 12) {
                    Text("Cultivate Your\nPrivate Oasis")
                        .font(.claudeSerif(size: 32, weight: .bold))
                        .foregroundStyle(Color.claudePrimaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Text("HousePlants.ai helps you track, care for, and discover your botanical collection.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
}

struct ProfileStepView: View {
    @Binding var username: String
    @Binding var city: String
    @Binding var country: String
    var showError: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                Image("onboarding_2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 10)

                Text("Let's personalize your jungle.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
                
                ClaudeTextField(title: "Preferred Name", placeholder: "e.g. Robin", text: $username, icon: "person")
                
                HStack(alignment: .top, spacing: 15) {
                    VStack(alignment: .leading, spacing: 10) {
                        ClaudeCitySearchField(title: "City", placeholder: "London", text: $city, icon: "mappin.circle") { cityName, countryName in
                            city = cityName
                            country = countryName
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    ClaudeTextField(title: "Country", placeholder: "UK", text: $country, icon: "globe")
                        .frame(maxWidth: .infinity)
                }
                
                if showError {
                    Label("Please fill in all details to continue", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .padding(30)
            }
        }
    }
}

struct ExperienceStepView: View {
    @Binding var difficulty: String
    @Binding var petSafeOnly: Bool
    @Binding var notifyOnSundays: Bool
    
    let levels = ["Beginner", "Enthusiast", "Botany Pro"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's your skill level?")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        ForEach(levels, id: \.self) { level in
                            Button(action: { difficulty = level }) {
                                Text(level)
                                    .font(.subheadline.bold())
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
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
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Quick Preferences")
                        .font(.headline)
                    
                    Toggle(isOn: $petSafeOnly) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🐶 Show Pet-Safe Only")
                                .font(.body.bold())
                            Text("Only suggest plants non-toxic to pets.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.claudeAccent))
                    
                    Toggle(isOn: $notifyOnSundays) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🔔 Sunday Reminders")
                                .font(.body.bold())
                            Text("Get care alerts on Sunday mornings.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.claudeAccent))
                }
                }
                .frame(width: geometry.size.width, alignment: .leading)
                .padding(30)
            }
        }
    }
}

struct FinalStepView: View {
    @Binding var isCompleted: Bool
    var saveAction: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack(alignment: .bottomTrailing) {
                Image("onboarding_3")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 15)
                    .padding(.horizontal, 30)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .padding(20)
                    .background(Color.claudeAccent)
                    .clipShape(Circle())
                    .offset(x: -15, y: 15)
                    .shadow(color: Color.claudeAccent.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            VStack(spacing: 12) {
                Text("All Set!")
                    .font(.claudeSerif(size: 40, weight: .bold))
                    .foregroundStyle(Color.claudePrimaryText)
                
                Text("Your personalized plant care journey\nis ready to begin.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: {
                saveAction()
                withAnimation(.spring()) { isCompleted = true }
            }) {
                Text("Enter Your Jungle")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.black)
                    .cornerRadius(20)
                    .padding(.horizontal, 40)
                    .shadow(radius: 10, y: 5)
            }
            .padding(.bottom, 50)
        }
    }
}

extension Color {
    static let emerald = Color(hex: "059669")
}

#Preview {
    WelcomeView(isCompleted: .constant(false))
        .environmentObject(DataLoader())
}
