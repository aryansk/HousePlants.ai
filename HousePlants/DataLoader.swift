import Foundation
import Combine

class DataLoader: ObservableObject {
    static let shared = DataLoader()

    @Published var appData: AppData?
    @Published var plants: [Plant] = []
    @Published var categories: [PlantCategory] = []
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    @Published var myJungleLookup: [String: MyPlant] = [:]
    @Published var notifications: [AppNotification] = []
    
    var isProfileComplete: Bool {
        UserDefaults.standard.string(forKey: "username") != nil
    }
    
    // Shared formatter to save resources
    static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    init() {
        loadData()
        loadUserPreferences()
        loadMyJungleExtendedData()
        loadNotifications()
        scanRepotReminders()
        CloudSyncManager.shared.start()
        WatchConnectivityBridge.shared.start()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cloudPulledRemote),
                                               name: .cloudSyncDidPullRemote,
                                               object: nil)
    }

    @objc private func cloudPulledRemote() {
        loadUserPreferences()
        loadMyJungleExtendedData()
    }
    
    func loadUserPreferences() {
        // Load saved user preferences from UserDefaults
        if let username = UserDefaults.standard.string(forKey: "username"),
           let city = UserDefaults.standard.string(forKey: "city"),
           let country = UserDefaults.standard.string(forKey: "country"),
           var profile = userProfile {
            profile.username = username
            profile.locationSettings.city = city
            profile.locationSettings.country = country
            self.userProfile = profile
        }
        
        if let profileImage = UserDefaults.standard.string(forKey: "profile_image"),
           var profile = userProfile {
            profile.profileImage = profileImage
            self.userProfile = profile
        }
        
        if let savedFavData = UserDefaults.standard.data(forKey: "user_favorites"),
           let favorites = try? JSONDecoder().decode([String].self, from: savedFavData),
           var profile = userProfile {
            profile.favorites = favorites
            self.userProfile = profile
        }

        if let currentStreak = UserDefaults.standard.object(forKey: "current_streak") as? Int,
           var profile = userProfile {
            profile.currentStreak = currentStreak
            self.userProfile = profile
        }
        
        if let lastStreakDate = UserDefaults.standard.string(forKey: "last_streak_date"),
           var profile = userProfile {
            profile.lastStreakDate = lastStreakDate
            self.userProfile = profile
        }
        
        if let historyData = UserDefaults.standard.data(forKey: "streak_history"),
           let history = try? JSONDecoder().decode([String].self, from: historyData),
           var profile = userProfile {
            profile.streakHistory = history
            self.userProfile = profile
        }
        
        if let savedPrefs = UserDefaults.standard.data(forKey: "userPreferences"),
           let prefs = try? JSONDecoder().decode(Preferences.self, from: savedPrefs),
           var profile = userProfile {
            profile.preferences = prefs
            self.userProfile = profile
        }
    }
    
    func updateProfile(username: String, city: String, country: String) {
        guard var profile = userProfile else { return }
        profile.username = username
        profile.locationSettings.city = city
        profile.locationSettings.country = country
        self.userProfile = profile
        saveProfile()
    }
    
    func updatePreferences(difficulty: String, petSafeOnly: Bool, notifyOnSundays: Bool) {
        guard var profile = userProfile else { return }
        profile.preferences.difficultyLevel = difficulty
        profile.preferences.petSafeOnly = petSafeOnly
        profile.preferences.notifyOnSundays = notifyOnSundays
        self.userProfile = profile
        saveProfile()
    }
    
    func updateProfileImage(imageData: Data) {
        guard var profile = userProfile else { return }
        profile.profileImage = imageData.base64EncodedString()
        self.userProfile = profile
        saveProfile()
    }
    
    private func saveProfile() {
        guard let profile = userProfile else { return }
        UserDefaults.standard.set(profile.username, forKey: "username")
        UserDefaults.standard.set(profile.locationSettings.city, forKey: "city")
        UserDefaults.standard.set(profile.locationSettings.country, forKey: "country")
        UserDefaults.standard.set(profile.profileImage, forKey: "profile_image")
        
        if let encoded = try? JSONEncoder().encode(profile.preferences) {
            UserDefaults.standard.set(encoded, forKey: "userPreferences")
        }

        if let encoded = try? JSONEncoder().encode(profile.favorites) {
            UserDefaults.standard.set(encoded, forKey: "user_favorites")
        }
        
        if let streak = profile.currentStreak {
            UserDefaults.standard.set(streak, forKey: "current_streak")
        }
        if let lastStreakDate = profile.lastStreakDate {
            UserDefaults.standard.set(lastStreakDate, forKey: "last_streak_date")
        }
        
        if let history = profile.streakHistory {
            if let encoded = try? JSONEncoder().encode(history) {
                UserDefaults.standard.set(encoded, forKey: "streak_history")
            }
        }
    }
    
    func loadData() {
        guard let url = Bundle.main.url(forResource: "jason", withExtension: "json") else {
            self.errorMessage = "Critical Error: jason.json not found in App Bundle.\n\nPlease add jason.json to your Xcode project target."
            print("Error: jason.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let appData = try decoder.decode(AppData.self, from: data)
            
            self.appData = appData
            self.plants = appData.plantCatalog
            self.categories = appData.plantCategories
            self.userProfile = appData.userProfile
            self.errorMessage = nil
            self.updateLookup()
            
        } catch {
            self.errorMessage = "Error decoding JSON: \(error.localizedDescription)"
            print("Error decoding JSON: \(error)")
        }
    }
    
    func checkAndUpdateStreak() {
        guard var profile = userProfile else { return }
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let todayString = DataLoader.isoFormatter.string(from: today)
        
        var streak = profile.currentStreak ?? 0
        var history = profile.streakHistory ?? []
        
        if let lastDateString = profile.lastStreakDate,
           let lastDate = DataLoader.isoFormatter.date(from: lastDateString) {
            let startOfLast = calendar.startOfDay(for: lastDate)
            
            if let days = calendar.dateComponents([.day], from: startOfLast, to: today).day {
                if days == 1 {
                    streak += 1
                    profile.lastStreakDate = DataLoader.isoFormatter.string(from: now)
                    if !history.contains(todayString) { history.append(todayString) }
                } else if days > 1 {
                    streak = 1
                    profile.lastStreakDate = DataLoader.isoFormatter.string(from: now)
                    if !history.contains(todayString) { history.append(todayString) }
                } else if days == 0 {
                    // Same day, ensure it's in history just in case
                    if !history.contains(todayString) { history.append(todayString) }
                }
            }
        } else {
            streak = 1
            profile.lastStreakDate = DataLoader.isoFormatter.string(from: now)
            history.append(todayString)
        }
        
        profile.currentStreak = streak
        profile.streakHistory = history
        self.userProfile = profile
        saveProfile()
    }
    
    func toggleJungle(plant: Plant) {
        guard var profile = userProfile else { return }
        
        if let index = profile.myJungle.firstIndex(where: { $0.plantId == plant.id }) {
            profile.myJungle.remove(at: index)
        } else {
            let newPlant = MyPlant(
                plantId: plant.id,
                nickname: plant.commonName,
                dateAcquired: Date().formatted(date: .numeric, time: .omitted),
                lastWatered: "Not yet",
                wateringHistory: [],
                nextWateringDate: nil,
                healthScore: 80, // Default healthy score
                healthLastUpdated: DataLoader.isoFormatter.string(from: Date()),
                notes: nil,
                locationInHome: nil,
                customWateringFrequencyDays: nil
            )
            profile.myJungle.append(newPlant)
        }
        
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }
    
    func toggleFavorite(plantId: String) {
        guard var profile = userProfile else { return }
        
        if let index = profile.favorites.firstIndex(of: plantId) {
            profile.favorites.remove(at: index)
        } else {
            profile.favorites.append(plantId)
        }
        
        self.userProfile = profile
        saveProfile() // Favorites are part of user profile
    }
    
    func isFavorite(plantId: String) -> Bool {
        return userProfile?.favorites.contains(plantId) ?? false
    }
    
    private func updateLookup() {

        guard let profile = userProfile else {
            myJungleLookup = [:]
            return
        }
        myJungleLookup = Dictionary(uniqueKeysWithValues: profile.myJungle.map { ($0.plantId, $0) })
    }
    
    // MARK: - Watering Management
    
    func waterPlant(plantId: String) {
        guard var profile = userProfile,
              let plantIndex = profile.myJungle.firstIndex(where: { $0.plantId == plantId }),
              let plant = plants.first(where: { $0.id == plantId }) else { return }
        
        let now = Date()
        let dateString = DataLoader.isoFormatter.string(from: now)
        
        // Update watering history
        var history = profile.myJungle[plantIndex].wateringHistory ?? []
        history.append(dateString)
        profile.myJungle[plantIndex].wateringHistory = history
        
        // Update last watered
        profile.myJungle[plantIndex].lastWatered = now.formatted(date: .numeric, time: .omitted)
        
        // Calculate next watering date
        let frequencyDays = profile.myJungle[plantIndex].customWateringFrequencyDays ?? getWateringFrequency(for: plant)
        guard let nextDate = Calendar.current.date(byAdding: .day, value: frequencyDays, to: now) else { return }
        profile.myJungle[plantIndex].nextWateringDate = DataLoader.isoFormatter.string(from: nextDate)
        
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }
    
    func waterAllPlants() {
        guard let profile = userProfile else { return }
        
        for myPlant in profile.myJungle {
            // Only water plants that need it (overdue or due soon)
            if needsWatering(myPlant: myPlant) {
                waterPlant(plantId: myPlant.plantId)
            }
        }
    }
    
    func needsWatering(myPlant: MyPlant) -> Bool {
        guard let nextWateringString = myPlant.nextWateringDate,
              let nextWateringDate = DataLoader.isoFormatter.date(from: nextWateringString) else {
            // If no next watering date set, consider it needs watering
            return true
        }
        
        // Needs watering if next watering date is today or in the past
        return nextWateringDate <= Date()
    }
    
    func daysUntilWatering(myPlant: MyPlant) -> Int? {
        guard let nextWateringString = myPlant.nextWateringDate,
              let nextWateringDate = DataLoader.isoFormatter.date(from: nextWateringString) else {
            return nil
        }
        
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextWateringDate).day
        return days
    }
    
    // MARK: - Weather-aware watering

    /// Recompute nextWateringDate using the base species frequency plus a forecast adjustment.
    /// Safe to call any time; if no weather info is available the base frequency is used.
    func recomputeNextWatering(for plantId: String, weatherAdjustment: WateringAdjustment? = nil) {
        guard var profile = userProfile,
              let idx = profile.myJungle.firstIndex(where: { $0.plantId == plantId }),
              let plant = plants.first(where: { $0.id == plantId }) else { return }

        let base = profile.myJungle[idx].customWateringFrequencyDays ?? getWateringFrequency(for: plant)
        let isOutdoor = profile.myJungle[idx].isOutdoor ?? false
        let delta = (isOutdoor || (weatherAdjustment?.appliesIndoors ?? false)) ? (weatherAdjustment?.daysDelta ?? 0) : 0
        let effective = max(1, base + delta)

        let anchor: Date = {
            if let last = profile.myJungle[idx].wateringHistory?.last,
               let date = DataLoader.isoFormatter.date(from: last) {
                return date
            }
            return Date()
        }()

        guard let next = Calendar.current.date(byAdding: .day, value: effective, to: anchor) else { return }
        profile.myJungle[idx].nextWateringDate = DataLoader.isoFormatter.string(from: next)
        profile.myJungle[idx].wateringAdjustmentNote = (delta != 0) ? weatherAdjustment?.reason : nil

        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }

    func setOutdoor(plantId: String, outdoor: Bool) {
        guard var profile = userProfile,
              let idx = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        profile.myJungle[idx].isOutdoor = outdoor
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }

    // MARK: - Repotting

    /// Heuristic: pot size sets a base interval (small <6" → 12mo, medium 6–10" → 18mo, large → 24mo),
    /// then growth rate (journal photos / month since last repot) shortens or extends it.
    func recomputeRepotDate(for plantId: String) {
        guard var profile = userProfile,
              let idx = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }

        let pot = profile.myJungle[idx].potSizeInches ?? 6
        let baseMonths: Double = pot < 6 ? 12 : (pot <= 10 ? 18 : 24)

        let anchor: Date = {
            if let last = profile.myJungle[idx].lastRepotted,
               let date = DataLoader.isoFormatter.date(from: last) {
                return date
            }
            // Fall back to acquired date (numeric format, not ISO)
            let f = DateFormatter()
            f.dateStyle = .short
            return f.date(from: profile.myJungle[idx].dateAcquired) ?? Date()
        }()

        let multiplier = growthRateMultiplier(plantId: plantId, since: anchor)
        let adjustedMonths = max(6, min(36, Int((baseMonths * multiplier).rounded())))

        guard let next = Calendar.current.date(byAdding: .month, value: adjustedMonths, to: anchor) else { return }
        profile.myJungle[idx].nextRepotDate = DataLoader.isoFormatter.string(from: next)

        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }

    func setPotSize(plantId: String, inches: Int) {
        guard var profile = userProfile,
              let idx = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        profile.myJungle[idx].potSizeInches = inches
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
        recomputeRepotDate(for: plantId)
    }

    func markRepotted(plantId: String) {
        guard var profile = userProfile,
              let idx = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        profile.myJungle[idx].lastRepotted = DataLoader.isoFormatter.string(from: Date())
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
        recomputeRepotDate(for: plantId)
    }

    func daysUntilRepot(myPlant: MyPlant) -> Int? {
        guard let dateString = myPlant.nextRepotDate,
              let date = DataLoader.isoFormatter.date(from: dateString) else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }

    /// Photos-per-month since `anchor` → multiplier on the base repot interval.
    /// Fast-growing plants (≥2 photos/mo) get 0.7×, slow (<0.5/mo) get 1.3×, otherwise 1.0×.
    private func growthRateMultiplier(plantId: String, since anchor: Date) -> Double {
        let photos = PlantJournalStore.shared.photos(for: plantId).filter { $0.date >= anchor }
        let monthsElapsed = max(1.0, Date().timeIntervalSince(anchor) / (60 * 60 * 24 * 30))
        let perMonth = Double(photos.count) / monthsElapsed
        if perMonth >= 2 { return 0.7 }
        if perMonth < 0.5 { return 1.3 }
        return 1.0
    }

    /// Generate in-app notifications for plants due to be repotted within 14 days.
    /// Skips plants already notified about within the last 7 days to avoid spam.
    func scanRepotReminders() {
        guard let profile = userProfile else { return }
        let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        for myPlant in profile.myJungle {
            guard let days = daysUntilRepot(myPlant: myPlant), days <= 14, days >= -180 else { continue }
            guard let plant = plants.first(where: { $0.id == myPlant.plantId }) else { continue }
            let alreadyNotified = notifications.contains { n in
                n.type == .repotting && n.date >= cutoff && n.message.contains(plant.commonName)
            }
            if alreadyNotified { continue }
            let message: String
            if days <= 0 {
                message = "\(plant.commonName) is overdue for repotting (\(-days) day\(days == -1 ? "" : "s") past due)."
            } else {
                message = "\(plant.commonName) is due for repotting in \(days) day\(days == 1 ? "" : "s")."
            }
            addNotification(title: "Repotting Reminder", message: message, type: .repotting)
        }
    }

    // MARK: - Health (computed)

    func recomputeHealth(for plantId: String) {
        guard let profile = userProfile,
              let myPlant = profile.myJungle.first(where: { $0.plantId == plantId }),
              let plant = plants.first(where: { $0.id == plantId }) else { return }
        let journalCount = PlantJournalStore.shared.photos(for: plantId).count
        let recentJournal = PlantJournalStore.shared.photos(for: plantId).first?.date
        let assessment = HealthScoreEngine.compute(
            myPlant: myPlant,
            plant: plant,
            journalPhotoCount: journalCount,
            mostRecentJournalDate: recentJournal,
            now: Date()
        )
        updatePlantHealth(plantId: plantId, healthScore: assessment.score)
    }

    func healthAssessment(for myPlant: MyPlant) -> HealthAssessment? {
        guard let plant = plants.first(where: { $0.id == myPlant.plantId }) else { return nil }
        let journalCount = PlantJournalStore.shared.photos(for: myPlant.plantId).count
        let recentJournal = PlantJournalStore.shared.photos(for: myPlant.plantId).first?.date
        return HealthScoreEngine.compute(
            myPlant: myPlant,
            plant: plant,
            journalPhotoCount: journalCount,
            mostRecentJournalDate: recentJournal,
            now: Date()
        )
    }

    func getWateringFrequency(for plant: Plant) -> Int {
        // Parse water requirement and estimate frequency in days
        let waterReq = plant.careGuide.water.lowercased()
        
        if waterReq.contains("daily") || waterReq.contains("every day") {
            return 1
        } else if waterReq.contains("twice a week") {
            return 3
        } else if waterReq.contains("week") && !waterReq.contains("every 2") {
            return 7
        } else if waterReq.contains("every 2 weeks") || waterReq.contains("biweekly") {
            return 14
        } else if waterReq.contains("month") {
            return 30
        } else if waterReq.contains("dry") || waterReq.contains("drought") {
            return 14 // Conservative default for drought-tolerant
        } else {
            return 7 // Default to weekly
        }
    }
    
    // MARK: - Health Management
    
    func updatePlantHealth(plantId: String, healthScore: Int) {
        guard var profile = userProfile,
              let plantIndex = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        
        profile.myJungle[plantIndex].healthScore = min(100, max(0, healthScore))
        profile.myJungle[plantIndex].healthLastUpdated = DataLoader.isoFormatter.string(from: Date())
        
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }
    
    func updatePlantNotes(plantId: String, notes: String) {
        guard var profile = userProfile,
              let plantIndex = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        
        profile.myJungle[plantIndex].notes = notes.isEmpty ? nil : notes
        
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }
    
    func updatePlantLocation(plantId: String, location: String) {
        guard var profile = userProfile,
              let plantIndex = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        
        profile.myJungle[plantIndex].locationInHome = location.isEmpty ? nil : location
        
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }
    
    func updatePlantNickname(plantId: String, nickname: String) {
        guard var profile = userProfile,
              let plantIndex = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        
        profile.myJungle[plantIndex].nickname = nickname
        
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }
    
    func fertilizeAllPlants() {
        guard var profile = userProfile else { return }
        let now = DataLoader.isoFormatter.string(from: Date())
        for index in profile.myJungle.indices {
            profile.myJungle[index].lastFertilized = now
        }
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }

    func mistAllPlants() {
        guard var profile = userProfile else { return }
        let now = DataLoader.isoFormatter.string(from: Date())
        for index in profile.myJungle.indices {
            profile.myJungle[index].lastMisted = now
        }
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }

    // MARK: - Batch Operations

    func removePlants(plantIds: [String]) {
        guard var profile = userProfile else { return }
        
        profile.myJungle.removeAll { plantIds.contains($0.plantId) }
        
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
    }
    
    // MARK: - Data Persistence
    
    private func saveMyJungleData() {
        guard let profile = userProfile else { return }

        // Save extended MyPlant data to UserDefaults
        if let encoded = try? JSONEncoder().encode(profile.myJungle) {
            UserDefaults.standard.set(encoded, forKey: "myJungleExtendedData")
        }
        WatchConnectivityBridge.shared.pushJungleSnapshot()
    }
    
    func loadMyJungleExtendedData() {
        guard var profile = userProfile else { return }

        // Saved data in UserDefaults is the authoritative source for the user's jungle.
        // It contains all user-added plants plus any extended properties (watering history, etc.)
        if let savedData = UserDefaults.standard.data(forKey: "myJungleExtendedData"),
           let savedPlants = try? JSONDecoder().decode([MyPlant].self, from: savedData) {
            profile.myJungle = savedPlants
            self.userProfile = profile
            self.updateLookup()
        }
    }
    
    // MARK: - Notifications Management
    
    private func loadNotifications() {
        if let savedData = UserDefaults.standard.data(forKey: "appNotifications"),
           let savedNotifications = try? JSONDecoder().decode([AppNotification].self, from: savedData) {
            self.notifications = savedNotifications
        } else {
            // Initial mock notifications
            self.notifications = [
                AppNotification(id: UUID(), title: "Watering Reminder", message: "Your Monstera Deliciosa is feeling a bit thirsty!", date: Date().addingTimeInterval(-3600), isRead: false, type: .watering),
                AppNotification(id: UUID(), title: "Fertilizer Time", message: "It's time to feed your Pothos for healthy growth.", date: Date().addingTimeInterval(-86400), isRead: true, type: .fertilizer),
                AppNotification(id: UUID(), title: "Tip: Sunlight Guide", message: "Rotate your plants every week for even light distribution.", date: Date().addingTimeInterval(-172800), isRead: false, type: .tip),
                AppNotification(id: UUID(), title: "Sun seeker update", message: "We've added new light thresholds for better plant tracking", date: Date().addingTimeInterval(-259200), isRead: true, type: .info)
            ]
            saveNotifications()
        }
    }
    
    func addNotification(title: String, message: String, type: AppNotification.NotificationType) {
        let newNotification = AppNotification(id: UUID(), title: title, message: message, date: Date(), isRead: false, type: type)
        notifications.insert(newNotification, at: 0)
        saveNotifications()
    }
    
    func markAsRead(id: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            saveNotifications()
        }
    }
    
    func markAllAsRead() {
        for index in 0..<notifications.count {
            notifications[index].isRead = true
        }
        saveNotifications()
    }
    
    func clearNotifications() {
        notifications.removeAll()
        saveNotifications()
    }
    
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: "appNotifications")
        }
    }
}
