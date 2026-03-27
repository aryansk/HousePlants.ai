import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = true
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("darkModeEnabled") var darkModeEnabled: Bool = false
    @AppStorage("hapticFeedback") var hapticFeedback: Bool = true
    @State private var showLogoutAlert = false
    
    // Photo management
    @State private var selectedItem: PhotosPickerItem? = nil
    
    // Fallback if dataLoader.userProfile is nil
    private var username: String { dataLoader.userProfile?.username ?? "Gardener" }
    private var city: String { dataLoader.userProfile?.locationSettings.city ?? "Plants Lover" }
    
    private var profileImage: UIImage? {
        guard let base64 = dataLoader.userProfile?.profileImage,
              let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
    
    var body: some View {
        NavigationView {
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
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(Color.green)
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
                            Text(username)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                Text(city)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                            
                            HStack(spacing: 12) {
                                StatView(label: "Plants", value: "\(dataLoader.userProfile?.myJungle.count ?? 0)")
                                StatView(label: "Badges", value: "8")
                                StatView(label: "Level", value: "Expert")
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .listRowBackground(Color.clear)
                
                Section(header: Text("Account").font(.subheadline).fontWeight(.semibold)) {
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
                
                Section(header: Text("Settings").font(.subheadline).fontWeight(.semibold)) {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Watering Reminders", systemImage: "bell.fill")
                    }
                    .tint(.green)
                    
                    Toggle(isOn: $darkModeEnabled) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                    .tint(.green)
                    
                    Toggle(isOn: $hapticFeedback) {
                        Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    .tint(.green)
                }
                
                Section(header: Text("Support").font(.subheadline).fontWeight(.semibold)) {
                    Link(destination: URL(string: "https://houseplants.ai")!) {
                        Label("Help Center", systemImage: "questionmark.circle.fill")
                    }
                    
                    Link(destination: URL(string: "https://houseplants.ai/privacy")!) {
                        Label("Privacy Policy", systemImage: "shield.fill")
                    }
                    
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.2.0")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("App Experience").font(.subheadline).fontWeight(.semibold)) {
                    Button(action: {
                        withAnimation { hasCompletedOnboarding = false }
                    }) {
                        Label("Restart Onboarding", systemImage: "arrow.clockwise.circle.fill")
                            .foregroundColor(.green)
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
            .navigationTitle("Profile")
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to log out? Your local data will be preserved but you'll need to re-enter your preferences.")
            }
        }
    }
    
    private func logout() {
        // Reset onboarding state to show WelcomeView again
        withAnimation { hasCompletedOnboarding = false }
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
        .background(Color(UIColor.systemGroupedBackground))
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
    @EnvironmentObject var dataLoader: DataLoader
    @Environment(\.dismiss) var dismiss
    @State private var username: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Personal Info")) {
                TextField("Username", text: $username)
                TextField("City", text: $city)
                TextField("Country", text: $country)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    dataLoader.updateProfile(username: username, city: city, country: country)
                    dismiss()
                }
                .fontWeight(.bold)
            }
        }
        .onAppear {
            username = dataLoader.userProfile?.username ?? ""
            city = dataLoader.userProfile?.locationSettings.city ?? ""
            country = dataLoader.userProfile?.locationSettings.country ?? ""
        }
    }
}

struct PlantPreferencesView: View {
    @EnvironmentObject var dataLoader: DataLoader
    @Environment(\.dismiss) var dismiss
    @State private var difficulty = "Beginner"
    @State private var petSafeOnly = false
    @State private var notifyOnSundays = true
    
    let difficulties = ["Beginner", "Intermediate", "Expert"]
    
    var body: some View {
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
        .environmentObject(DataLoader())
}
