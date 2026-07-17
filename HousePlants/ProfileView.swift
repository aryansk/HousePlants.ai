import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(DataLoader.self) var dataLoader
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = true
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppAppearance.system.rawValue
    @AppStorage("hapticFeedback") var hapticFeedback: Bool = true
    @State private var showDeleteDataAlert = false
    
    // Photo management
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showAvatarPicker = false
    let cuteAvatars = ["avatar_cactus", "avatar_monstera", "avatar_succulent", "avatar_fern"]
    
    private var profileImage: UIImage? {
        // profileImage now holds a cache-busting token; the JPEG lives in ProfileImageStore.
        // Reading the token off the published profile keeps this view refreshing on change.
        guard let token = dataLoader.userProfile?.profileImage, !token.isEmpty else { return nil }
        if let image = ProfileImageStore.shared.loadImage() { return image }
        // Pre-migration profiles may still carry the raw base64 payload.
        guard let data = Data(base64Encoded: token) else { return nil }
        return UIImage(data: data)
    }


    private var username: String {
        dataLoader.isProfileComplete ? (dataLoader.userProfile?.username ?? "Gardener") : "Gardener"
    }
    
    private var city: String {
        guard dataLoader.isProfileComplete,
              let city = dataLoader.userProfile?.locationSettings.city,
              !city.isEmpty,
              city.lowercased() != "unknown" else {
            return "Location not set"
        }
        return city
    }

    private var plantCount: Int {
        dataLoader.userProfile?.myJungle.count ?? 0
    }

    private var gardenerLevel: String {
        switch plantCount {
        case 0: return "Seedling"
        case 1...3: return "Sprout"
        case 4...9: return "Plant Keeper"
        default: return "Botanist"
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ClaudeHeader(
                        title: dataLoader.isProfileComplete ? "Profile" : "Welcome!",
                        subtitle: dataLoader.isProfileComplete ? "\(gardenerLevel) · \(plantCount) plant\(plantCount == 1 ? "" : "s")" : "Set up your gardener profile",
                        location: dataLoader.isProfileComplete ? dataLoader.userProfile?.locationSettings.city : nil
                    )
                    
                    Form {
                        Section {
                            HStack(spacing: 20) {
                                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                    ZStack(alignment: .bottomTrailing) {
                                        if let image = profileImage {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                        } else {
                                            Circle()
                                                .fill(LinearGradient(colors: [.green.opacity(0.8), .mint.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 80, height: 80)
                                        
                                            Text(String(username.prefix(1)).uppercased())
                                                .font(.claudeSerif(size: 32, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white)
                                            .padding(6)
                                            .background(Color.claudeAccent)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                            .offset(x: 4, y: 4)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(profileImage == nil ? "Add profile photo" : "Change profile photo")
                                .onChange(of: selectedItem) { oldItem, newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                            withAnimation {
                                                dataLoader.updateProfileImage(imageData: data)
                                            }
                                        }
                                    }
                                }
                            
                                VStack(alignment: .leading, spacing: 4) {
                                    if dataLoader.isProfileComplete {
                                        Text(username)
                                            .font(.claudeSerif(size: 20, weight: .bold))
                                            .foregroundStyle(Color.claudePrimaryText)
                                    
                                        HStack {
                                            Image(systemName: "location.fill")
                                                .font(.caption)
                                            Text(city)
                                                .font(.subheadline)
                                        }
                                        .foregroundStyle(.secondary)
                                    } else {
                                        Text("Anonymous Gardener")
                                            .font(.claudeSerif(size: 20, weight: .bold))
                                            .foregroundStyle(Color.claudePrimaryText)
                                    
                                        NavigationLink(destination: EditProfileView()) {
                                            Text("Complete your profile →")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(Color.claudeAccent)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                
                                    HStack(spacing: 12) {
                                        StatView(label: "Plants", value: "\(plantCount)")
                                        StatView(label: "Streak", value: "\(dataLoader.userProfile?.currentStreak ?? 0)d")
                                        StatView(label: "Level", value: gardenerLevel)
                                    }
                                    .padding(.top, 4)
                                
                                    Button(action: { showAvatarPicker = true }) {
                                        HStack {
                                            Image(systemName: "sparkles")
                                            Text("Choose Cartoon Avatar")
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(Color.claudeAccent)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .listRowBackground(Color.clear)
                    
                        if !dataLoader.isProfileComplete {
                            Section {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Personalize Your Experience")
                                        .font(.headline)
                                        .foregroundStyle(Color.claudePrimaryText)
                                
                                    Text("Add your name and location to get localized plant care tips and a more personal touch.")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.claudeSecondaryText)
                                
                                    NavigationLink(destination: EditProfileView()) {
                                        Text("Add My Details")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(Color.claudeAccent)
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    
                        Section(header: Text("Account").font(.claudeSans(size: 14)).fontWeight(.semibold).foregroundStyle(Color.claudeSecondaryText)) {
                            NavigationLink(destination: EditProfileView()) {
                                Label("Edit Profile", systemImage: "person.crop.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        
                            NavigationLink(destination: PlantPreferencesView()) {
                                Label("Plant Preferences", systemImage: "leaf.fill")
                                    .foregroundStyle(.green)
                            }
                        
                            NavigationLink(destination: AchievementsView()) {
                                Label("Achievements", systemImage: "trophy.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    
                        Section(header: Text("Settings").font(.claudeSans(size: 14)).fontWeight(.semibold).foregroundStyle(Color.claudeSecondaryText)) {
                            Toggle(isOn: $notificationsEnabled) {
                                Label("Care Reminders", systemImage: "bell.fill")
                            }
                            .tint(Color.claudeAccent)
                            .onChange(of: notificationsEnabled) { _, isEnabled in
                                if isEnabled {
                                    dataLoader.syncAllNotifications()
                                } else {
                                    NotificationScheduler.shared.cancelAll()
                                }
                            }
                        
                            Picker(selection: $appearanceModeRaw) {
                                ForEach(AppAppearance.allCases) { mode in
                                    Text(mode.label).tag(mode.rawValue)
                                }
                            } label: {
                                Label("Appearance", systemImage: "circle.lefthalf.filled")
                            }
                            .tint(Color.claudeAccent)
                        
                            Toggle(isOn: $hapticFeedback) {
                                Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                            }
                            .tint(Color.claudeAccent)
                        }
                    
                        Section(header: Text("Support").font(.claudeSans(size: 14)).fontWeight(.semibold).foregroundStyle(Color.claudeSecondaryText)) {
                            Link(destination: URL(string: "https://houseplants.io")!) {
                                Label("Help Center", systemImage: "questionmark.circle.fill")
                            }
                        
                            NavigationLink(destination: PrivacyPolicyView()) {
                                Label("Privacy Policy", systemImage: "shield.fill")
                            }
                        
                            NavigationLink(destination: TermsOfServiceView()) {
                                Label("Terms of Service", systemImage: "doc.text.fill")
                            }

                            NavigationLink(destination: AcknowledgementsView()) {
                                Label("Acknowledgements", systemImage: "heart.text.square.fill")
                            }
                        
                            HStack {
                                Label("Version", systemImage: "info.circle.fill")
                                Spacer()
                                Text(appVersion)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    
                        Section(header: Text("App Experience").font(.claudeSans(size: 14)).fontWeight(.semibold).foregroundStyle(Color.claudeSecondaryText)) {
                            Button(action: {
                                withAnimation { hasCompletedOnboarding = false }
                            }) {
                                Label("Restart Onboarding", systemImage: "arrow.clockwise.circle.fill")
                                    .foregroundColor(Color.claudeAccent)
                            }
                        }
                    
                        Section(header: Text("Data Management").font(.claudeSans(size: 14)).fontWeight(.semibold).foregroundStyle(Color.claudeSecondaryText)) {
                            Button(role: .destructive) {
                                showDeleteDataAlert = true
                            } label: {
                                Label("Delete All My Data", systemImage: "trash.fill")
                            }
                        }
                    
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Delete All Data", isPresented: $showDeleteDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently erase all your data including your profile, plant collection, watering history, preferences, and notifications. This action cannot be undone.")
            }
            .sheet(isPresented: $showAvatarPicker) {
                NavigationStack {
                    ZStack {
                        Color.claudeBackground.ignoresSafeArea()
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 24) {
                                ForEach(cuteAvatars, id: \.self) { avatar in
                                    Button(action: {
                                        if let image = UIImage(named: avatar), let data = image.pngData() {
                                            withAnimation {
                                                dataLoader.updateProfileImage(imageData: data)
                                            }
                                        }
                                        showAvatarPicker = false
                                    }) {
                                        Image(avatar)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.claudeBorder, lineWidth: 3))
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    }
                                }
                            }
                            .padding(.top, 30)
                            .padding(.horizontal)
                        }
                    }
                    .navigationTitle("Select Avatar")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showAvatarPicker = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    private func deleteAllData() {
        dataLoader.resetUserProfile()
        PlantJournalStore.shared.deleteAll()
        ProfileImageStore.shared.delete()
        NotificationScheduler.shared.cancelAll()
        HomeKitSensorManager.shared.stopThresholdMonitoring()
        CloudSyncManager.shared.clearMirroredData()
        PlantNetService.shared.apiKey = nil

        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // Reset app state back to onboarding
        withAnimation {
            hasCompletedOnboarding = false
        }
    }
}

struct StatView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }
}

struct AchievementsView: View {
    @Environment(DataLoader.self) private var dataLoader

    private var plants: [MyPlant] { dataLoader.userProfile?.myJungle ?? [] }

    private var badges: [AchievementBadge] {
        let wateringCount = plants.reduce(0) { $0 + ($1.wateringHistory?.count ?? 0) }
        let healthiestScore = plants.compactMap(\.healthScore).max() ?? 0
        let favoriteCount = dataLoader.userProfile?.favorites.count ?? 0
        let streak = dataLoader.userProfile?.currentStreak ?? 0

        return [
            AchievementBadge(name: "Seed Sower", icon: "🌱", description: "Add your first plant", current: plants.count, target: 1),
            AchievementBadge(name: "Water Wizard", icon: "💧", description: "Log 10 waterings", current: wateringCount, target: 10),
            AchievementBadge(name: "Green Thumb", icon: "👍", description: "Reach a 90 health score", current: healthiestScore, target: 90),
            AchievementBadge(name: "Jungle Keeper", icon: "🌳", description: "Grow a collection of 5 plants", current: plants.count, target: 5),
            AchievementBadge(name: "Plant Scout", icon: "🔎", description: "Save 5 catalog favorites", current: favoriteCount, target: 5),
            AchievementBadge(name: "Consistent Carer", icon: "🔥", description: "Build a 7-day care streak", current: streak, target: 7)
        ]
    }

    private var unlockedCount: Int { badges.filter(\.isUnlocked).count }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(IndieHousePalette.yellow)
                            .frame(width: 64, height: 64)
                        Image(systemName: "trophy.fill")
                            .font(.title2.bold())
                            .foregroundStyle(IndieHousePalette.ink)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(unlockedCount) of \(badges.count) unlocked")
                            .font(.claudeSerif(size: 22, weight: .bold))
                            .foregroundStyle(Color.claudePrimaryText)
                        Text("Care for your plants to make progress naturally.")
                            .font(.subheadline)
                            .foregroundStyle(Color.claudeSecondaryText)
                    }

                    Spacer(minLength: 0)
                }
                .padding(18)
                .indiePaperCard(fill: Color.claudeSecondaryBackground, shadowOffset: 4)
                .accessibilityElement(children: .combine)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 18) {
                    ForEach(badges) { badge in
                        VStack(spacing: 12) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(badge.isUnlocked ? IndieHousePalette.orange.opacity(0.2) : Color.claudeBorder.opacity(0.12))
                                    .frame(width: 72, height: 72)

                                Text(badge.icon)
                                    .font(.system(size: 36))
                                    .grayscale(badge.isUnlocked ? 0 : 1)
                                    .opacity(badge.isUnlocked ? 1 : 0.45)

                                if badge.isUnlocked {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(IndieHousePalette.green)
                                        .background(Color.claudeSecondaryBackground.clipShape(Circle()))
                                }
                            }

                            VStack(spacing: 5) {
                                Text(badge.name)
                                    .font(.headline)
                                    .foregroundStyle(Color.claudePrimaryText)
                                    .multilineTextAlignment(.center)
                                Text(badge.description)
                                    .font(.caption)
                                    .foregroundStyle(Color.claudeSecondaryText)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if badge.isUnlocked {
                                Text("UNLOCKED")
                                    .font(.caption2.bold())
                                    .tracking(0.8)
                                    .foregroundStyle(IndieHousePalette.green)
                            } else {
                                VStack(spacing: 5) {
                                    ProgressView(value: Double(badge.cappedCurrent), total: Double(badge.target))
                                        .tint(Color.claudeAccent)
                                    Text("\(badge.cappedCurrent) / \(badge.target)")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(Color.claudeSecondaryText)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .top)
                        .padding(16)
                        .indiePaperCard(fill: Color.claudeSecondaryBackground, shadowOffset: 4)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(badge.name), \(badge.description)")
                        .accessibilityValue(badge.isUnlocked ? "Unlocked" : "\(badge.cappedCurrent) of \(badge.target)")
                    }
                }
            }
            .padding(20)
        }
        .background(Color.claudeBackground.ignoresSafeArea())
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AchievementBadge: Identifiable {
    var id: String { name }
    let name: String
    let icon: String
    let description: String
    let current: Int
    let target: Int

    var cappedCurrent: Int { min(current, target) }
    var isUnlocked: Bool { current >= target }
}

struct EditProfileView: View {
    @Environment(DataLoader.self) var dataLoader
    @Environment(\.dismiss) var dismiss
    @State private var username: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                VStack(alignment: .leading, spacing: 20) {
                    ClaudeTextField(title: "Username", placeholder: "e.g. Robin", text: $username, icon: "person")
                    
                    ClaudeCitySearchField(title: "City", placeholder: "London", text: $city, icon: "mappin.circle") { cityName, countryName in
                        city = cityName
                        country = countryName
                    }
                    
                    ClaudeTextField(title: "Country", placeholder: "UK", text: $country, icon: "globe")
                }
                .padding(25)
                .background(Color.claudeBackground)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                Spacer()
            }
            .padding()
        }
        .background(Color.claudeBackground.ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    dataLoader.updateProfile(username: username, city: city, country: country)
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(Color.claudeAccent)
            }
        }
        .onAppear {
            if dataLoader.isProfileComplete {
                username = dataLoader.userProfile?.username ?? ""
                city = dataLoader.userProfile?.locationSettings.city ?? ""
                country = dataLoader.userProfile?.locationSettings.country ?? ""
            }
        }
    }
}

struct PlantPreferencesView: View {
    @Environment(DataLoader.self) var dataLoader
    @Environment(\.dismiss) var dismiss
    @State private var difficulty = "Beginner"
    @State private var petSafeOnly = false
    @State private var notifyOnSundays = true
    
    let difficulties = ["Beginner", "Enthusiast", "Botany Pro"]
    
    var body: some View {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                Form {
                    Section(header: Text("Experience")) {
                        Picker("Experience Level", selection: $difficulty) {
                            ForEach(difficulties, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section(header: Text("Safety")) {
                        Toggle("Pet Safe Plants Only", isOn: $petSafeOnly)
                            .tint(.green)
                    }
                    
                    Section(header: Text("Notifications")) {
                        Toggle("Sunday Care Summary", isOn: $notifyOnSundays)
                            .tint(.green)
                    }
                    
                    Section(footer: Text("These preferences will help us tailor " + "your discovery feed and care reminders.")) {
                        EmptyView()
                    }
                }
                .scrollContentBackground(.hidden)
            }
        .navigationTitle("Plant Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    dataLoader.updatePreferences(difficulty: difficulty, petSafeOnly: petSafeOnly, notifyOnSundays: notifyOnSundays)
                    dismiss()
                }
                .fontWeight(.bold)
            }
        }
        .onAppear {
            if let prefs = dataLoader.userProfile?.preferences {
                difficulty = prefs.difficultyLevel
                petSafeOnly = prefs.petSafeOnly
                notifyOnSundays = prefs.notifyOnSundays
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(DataLoader())
}
