import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(DataLoader.self) var dataLoader
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = true
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppAppearance.system.rawValue
    @AppStorage("hapticFeedback") var hapticFeedback: Bool = true
    @State private var showLogoutAlert = false
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
        dataLoader.isProfileComplete ? (dataLoader.userProfile?.locationSettings.city ?? "Plants Lover") : "Plants Lover"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ClaudeHeader(
                        title: dataLoader.isProfileComplete ? "Profile" : "Welcome!",
                        subtitle: dataLoader.isProfileComplete ? "Gardener Level: Expert" : "Set up your gardener profile",
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
                                        StatView(label: "Plants", value: "\(dataLoader.userProfile?.myJungle.count ?? 0)")
                                        StatView(label: "Badges", value: dataLoader.isProfileComplete ? "8" : "0")
                                        StatView(label: "Level", value: dataLoader.isProfileComplete ? "Expert" : "Seedling")
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
                                Label("Watering Reminders", systemImage: "bell.fill")
                            }
                            .tint(Color.claudeAccent)
                        
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
                        
                            Link(destination: URL(string: "https://houseplants.io/privacy")!) {
                                Label("Privacy Policy", systemImage: "shield.fill")
                            }
                        
                            Link(destination: URL(string: "https://houseplants.io/terms")!) {
                                Label("Terms of Service", systemImage: "doc.text.fill")
                            }
                        
                            HStack {
                                Label("Version", systemImage: "info.circle.fill")
                                Spacer()
                                Text("1.2.0")
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
                    
                        Section {
                            Button(role: .destructive) {
                                showLogoutAlert = true
                            } label: {
                                Text("Log Out")
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.visible, for: .tabBar)
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to log out? Your local data will be preserved but you'll need to re-enter your preferences.")
            }
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
    
    private func logout() {
        // Reset onboarding state to show WelcomeView again
        withAnimation { hasCompletedOnboarding = false }
    }
    
    private func deleteAllData() {
        // Remove all stored user data from UserDefaults
        let keysToRemove = [
            "username", "city", "country", "profile_image",
            "userPreferences", "user_favorites", "myJungleExtendedData",
            "current_streak", "last_streak_date", "streak_history",
            "appNotifications", "hasCompletedOnboarding",
            "notificationsEnabled", "appearanceMode", "hapticFeedback"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }

        UserDefaults.standard.synchronize()

        ProfileImageStore.shared.delete()
        PlantNetService.shared.apiKey = nil

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
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

struct AchievementsView: View {
    let badges = [
        AchievementBadge(name: "Seed Sower", icon: "🌱", description: "Added your first plant", isUnlocked: true),
        AchievementBadge(name: "Water Wizard", icon: "💧", description: "Watered plants 10 times", isUnlocked: true),
        AchievementBadge(name: "Green Thumb", icon: "👍", description: "Reached 100% health score", isUnlocked: true),
        AchievementBadge(name: "Jungle Master", icon: "🌳", description: "Have 5+ plants in your collection", isUnlocked: true),
        AchievementBadge(name: "Sun Seeker", icon: "☀️", description: "Used the Sun Seeker tool", isUnlocked: false),
        AchievementBadge(name: "Botanist", icon: "🔬", description: "Identified 3 new species", isUnlocked: false),
        AchievementBadge(name: "Early Bird", icon: "🌅", description: "Morning care routine (before 8 AM)", isUnlocked: true)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 20) {
                ForEach(badges) { badge in
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(badge.isUnlocked ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Text(badge.icon)
                                .font(.system(size: 40))
                                .grayscale(badge.isUnlocked ? 0 : 1.0)
                                .opacity(badge.isUnlocked ? 1.0 : 0.4)
                        }
                        
                        VStack(spacing: 4) {
                            Text(badge.name)
                                .font(.headline)
                                .lineLimit(1)
                            Text(badge.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 4)
                        }
                        
                        if !badge.isUnlocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
            .padding()
        }
        .background(Color.claudeBackground.ignoresSafeArea())
        .navigationTitle("Achievements")
    }
}

struct AchievementBadge: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let isUnlocked: Bool
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
