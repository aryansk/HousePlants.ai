import Foundation
import Combine
import os

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
        NotificationScheduler.shared.requestAuthorization()
        HomeKitSensorManager.shared.start()
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
        guard let url = Bundle.main.url(forResource: "plants", withExtension: "json") else {
            self.errorMessage = "Critical Error: plants.json not found in App Bundle.\n\nPlease add plants.json to your Xcode project target."
            Logger.data.error("plants.json not found in bundle")
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
            Logger.data.error("Error decoding JSON: \(error)")
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
    
    func updateLookup() {

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
    
    func saveMyJungleData() {
        guard let profile = userProfile else { return }

        if let encoded = try? JSONEncoder().encode(profile.myJungle) {
            UserDefaults.standard.set(encoded, forKey: "myJungleExtendedData")
        }
        WatchConnectivityBridge.shared.pushJungleSnapshot()
        syncAllNotifications()
    }

    /// Rebuilds all system notification schedules from the current jungle state.
    func syncAllNotifications() {
        guard let profile = userProfile else { return }
        let enabled = true
        let sundaysOnly = profile.preferences.notifyOnSundays
        let now = Date()

        // --- Watering (free tier) ---
        let waterReminders: [NotificationScheduler.Reminder] = profile.myJungle.compactMap { myPlant in
            guard let dateString = myPlant.nextWateringDate,
                  let date = DataLoader.isoFormatter.date(from: dateString) else { return nil }
            let name = myJungleLookup[myPlant.plantId]?.nickname ?? myPlant.nickname
            return NotificationScheduler.Reminder(plantId: myPlant.plantId, plantName: name, dueDate: date)
        }
        NotificationScheduler.shared.sync(reminders: waterReminders, enabled: enabled,
                                          sundaysOnly: sundaysOnly, now: now)

        guard ProManager.shared.isPro else { return }

        // --- Fertilizer (Pro) — every 30 days from lastFertilized ---
        let fertReminders: [NotificationScheduler.FertilizerReminder] = profile.myJungle.map { myPlant in
            let base: Date
            if let s = myPlant.lastFertilized, let d = DataLoader.isoFormatter.date(from: s) {
                base = d
            } else {
                base = now
            }
            let due = Calendar.current.date(byAdding: .day, value: 30, to: base) ?? now
            let name = myJungleLookup[myPlant.plantId]?.nickname ?? myPlant.nickname
            return NotificationScheduler.FertilizerReminder(plantId: myPlant.plantId, plantName: name, dueDate: due)
        }
        NotificationScheduler.shared.syncFertilizerReminders(fertReminders, enabled: enabled, now: now)

        // --- Misting (Pro) — every 3 days from lastMisted ---
        let mistReminders: [NotificationScheduler.MistingReminder] = profile.myJungle.map { myPlant in
            let base: Date
            if let s = myPlant.lastMisted, let d = DataLoader.isoFormatter.date(from: s) {
                base = d
            } else {
                base = now
            }
            let due = Calendar.current.date(byAdding: .day, value: 3, to: base) ?? now
            let name = myJungleLookup[myPlant.plantId]?.nickname ?? myPlant.nickname
            return NotificationScheduler.MistingReminder(plantId: myPlant.plantId, plantName: name, dueDate: due)
        }
        NotificationScheduler.shared.syncMistingReminders(mistReminders, enabled: enabled, now: now)

        // --- Repotting (Pro) — from nextRepotDate ---
        let repotReminders: [NotificationScheduler.RepottingReminder] = profile.myJungle.compactMap { myPlant in
            guard let s = myPlant.nextRepotDate,
                  let date = DataLoader.isoFormatter.date(from: s) else { return nil }
            let name = myJungleLookup[myPlant.plantId]?.nickname ?? myPlant.nickname
            return NotificationScheduler.RepottingReminder(plantId: myPlant.plantId, plantName: name, dueDate: date)
        }
        NotificationScheduler.shared.syncRepottingReminders(repotReminders, enabled: enabled, now: now)

        // --- Bloom countdown (Pro) — via BloomPredictor ---
        let hemisphere = BloomPredictor.hemisphere(forCountry: profile.locationSettings.country)
        let bloomReminders: [NotificationScheduler.BloomReminder] = profile.myJungle.compactMap { myPlant in
            guard let plant = plants.first(where: { $0.id == myPlant.plantId }),
                  let window = BloomPredictor.predict(for: plant, hemisphere: hemisphere),
                  let daysAway = window.daysUntilNextBloom(from: now),
                  daysAway > 0 else { return nil }
            guard let bloomStart = Calendar.current.date(byAdding: .day, value: daysAway, to: now) else { return nil }
            let name = myJungleLookup[myPlant.plantId]?.nickname ?? myPlant.nickname
            return NotificationScheduler.BloomReminder(
                plantId: myPlant.plantId, plantName: name,
                bloomStartDate: bloomStart, bloomNotes: window.notes
            )
        }
        NotificationScheduler.shared.syncBloomReminders(bloomReminders, enabled: enabled, now: now)

        // --- HomeKit threshold monitoring (Pro) ---
        if ProManager.shared.isPro {
            let thresholds: [HomeKitSensorManager.PlantThreshold] = profile.myJungle.compactMap { myPlant in
                guard let plant = plants.first(where: { $0.id == myPlant.plantId }) else { return nil }
                let minHumidity = parseMinHumidity(from: plant.careGuide.humidity)
                let maxTemp = parseMaxTempC(from: plant.careGuide.temperatureRange)
                let name = myJungleLookup[myPlant.plantId]?.nickname ?? myPlant.nickname
                return HomeKitSensorManager.PlantThreshold(
                    plantId: myPlant.plantId, plantName: name,
                    minHumidityPct: minHumidity, maxTempC: maxTemp
                )
            }
            HomeKitSensorManager.shared.startThresholdMonitoring(thresholds: thresholds)
        } else {
            HomeKitSensorManager.shared.stopThresholdMonitoring()
        }
    }

    // MARK: - Parsing helpers for sensor thresholds

    /// Extracts the lower bound from a humidity string like "High, 60-80%" → 60.0
    private func parseMinHumidity(from text: String) -> Double {
        let pattern = #"(\d+)\s*[-–]\s*\d+\s*%"#
        if let range = text.range(of: pattern, options: .regularExpression),
           let match = text[range].firstMatch(of: /(\d+)/) {
            return Double(match.output.1) ?? 40.0
        }
        if text.lowercased().contains("high")   { return 60.0 }
        if text.lowercased().contains("medium") { return 40.0 }
        return 30.0
    }

    /// Extracts the upper °C bound from a range like "65-85°F" (converts from °F) or "18-29°C".
    private func parseMaxTempC(from text: String) -> Double {
        let t = text.lowercased()
        // Try to find a Celsius range first
        if t.contains("°c") || t.contains("c)") {
            if let m = text.firstMatch(of: /\d+\s*[-–]\s*(\d+)/) {
                return Double(m.output.1) ?? 35.0
            }
        }
        // Fall back to Fahrenheit (upper bound of range) → convert
        if let m = text.firstMatch(of: /\d+\s*[-–]\s*(\d+)/) {
            let fahr = Double(m.output.1) ?? 95.0
            return (fahr - 32) * 5 / 9
        }
        return 32.0 // default ~90°F
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
}
