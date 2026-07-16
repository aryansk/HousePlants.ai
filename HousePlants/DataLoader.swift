import Foundation
import Observation
import os

@Observable
class DataLoader {
    static let shared = DataLoader()

    var appData: AppData?
    var plants: [Plant] = []
    /// O(1) id → Plant lookup, rebuilt whenever `plants` is loaded. Avoids repeated
    /// `plants.first(where:)` linear scans throughout the app.
    private(set) var plantsById: [String: Plant] = [:]
    var categories: [PlantCategory] = []
    var userProfile: UserProfile?
    var errorMessage: String?
    var myJungleLookup: [String: MyPlant] = [:]
    var notifications: [AppNotification] = []
    
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
        // Notification authorization is requested when the first reminder is scheduled, and
        // HomeKit is only touched once the user binds a sensor — never blanket-prompt at launch.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cloudPulledRemote),
                                               name: .cloudSyncDidPullRemote,
                                               object: nil)

        // Non-critical launch work — repot scan (generates in-app notifications), iCloud KVS
        // sync, and the watch bridge — is deferred off the first-frame path. None of it is
        // needed to render the initial UI.
        Task { @MainActor [weak self] in
            self?.scanRepotReminders()
            CloudSyncManager.shared.start()
            WatchConnectivityBridge.shared.start()
        }
    }

    @objc private func cloudPulledRemote() {
        loadUserPreferences()
        loadMyJungleExtendedData()
    }
    
    func loadUserPreferences() {
        // Build the whole profile locally, then publish once. Previously each key assigned
        // `self.userProfile` separately, firing up to seven `objectWillChange` events per load.
        guard var profile = userProfile else { return }
        let defaults = UserDefaults.standard

        if let username = defaults.string(forKey: "username"),
           let city = defaults.string(forKey: "city"),
           let country = defaults.string(forKey: "country") {
            profile.username = username
            profile.locationSettings.city = city
            profile.locationSettings.country = country
        }

        if let profileImage = defaults.string(forKey: "profile_image") {
            if profileImage.count > 512, let data = Data(base64Encoded: profileImage) {
                // Legacy builds kept the whole JPEG base64-encoded in UserDefaults — move it
                // to a file and leave just a token behind.
                ProfileImageStore.shared.save(data)
                let token = DataLoader.isoFormatter.string(from: Date())
                defaults.set(token, forKey: "profile_image")
                profile.profileImage = token
            } else {
                profile.profileImage = profileImage
            }
        }

        if let savedFavData = defaults.data(forKey: "user_favorites"),
           let favorites = try? JSONDecoder().decode([String].self, from: savedFavData) {
            profile.favorites = favorites
        }

        if let currentStreak = defaults.object(forKey: "current_streak") as? Int {
            profile.currentStreak = currentStreak
        }

        if let lastStreakDate = defaults.string(forKey: "last_streak_date") {
            profile.lastStreakDate = lastStreakDate
        }

        if let historyData = defaults.data(forKey: "streak_history"),
           let history = try? JSONDecoder().decode([String].self, from: historyData) {
            profile.streakHistory = history
        }

        if let savedPrefs = defaults.data(forKey: "userPreferences"),
           let prefs = try? JSONDecoder().decode(Preferences.self, from: savedPrefs) {
            profile.preferences = prefs
        }

        self.userProfile = profile
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
        ProfileImageStore.shared.save(imageData)
        // Only a cache-busting token lives in the profile; the JPEG stays on disk.
        profile.profileImage = DataLoader.isoFormatter.string(from: Date())
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

        CloudSyncManager.shared.push()
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
            self.plantsById = Dictionary(uniqueKeysWithValues: appData.plantCatalog.map { ($0.id, $0) })
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
        var changed = false

        if let lastDateString = profile.lastStreakDate,
           let lastDate = DataLoader.isoFormatter.date(from: lastDateString) {
            let startOfLast = calendar.startOfDay(for: lastDate)

            if let days = calendar.dateComponents([.day], from: startOfLast, to: today).day {
                if days == 1 {
                    streak += 1
                    profile.lastStreakDate = DataLoader.isoFormatter.string(from: now)
                    if !history.contains(todayString) { history.append(todayString) }
                    changed = true
                } else if days > 1 {
                    streak = 1
                    profile.lastStreakDate = DataLoader.isoFormatter.string(from: now)
                    if !history.contains(todayString) { history.append(todayString) }
                    changed = true
                } else if days == 0 {
                    // Same day — nothing to bump. Only touch history if today is somehow missing.
                    if !history.contains(todayString) {
                        history.append(todayString)
                        changed = true
                    }
                }
            }
        } else {
            streak = 1
            profile.lastStreakDate = DataLoader.isoFormatter.string(from: now)
            history.append(todayString)
            changed = true
        }

        // The common case — opening the app again the same day — is a no-op, so we skip the
        // profile write and the iCloud push it would trigger.
        guard changed else { return }

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

    /// O(1) catalog lookup. Prefer this over `plants.first(where:)`.
    func plant(for id: String) -> Plant? {
        plantsById[id]
    }
    
    // MARK: - Watering Management
    
    func waterPlant(plantId: String) {
        guard var profile = userProfile,
              let plantIndex = profile.myJungle.firstIndex(where: { $0.plantId == plantId }),
              let plant = plant(for: plantId) else { return }
        
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
    
    /// Waters every plant that needs it in a single pass, then persists once. Previously this
    /// called `waterPlant` per plant, and each call ran a full SwiftData rewrite + iCloud push +
    /// notification reschedule — O(N) saves. Now it's one save for the whole batch.
    func waterAllPlants() {
        guard var profile = userProfile else { return }

        let now = Date()
        let dateString = DataLoader.isoFormatter.string(from: now)
        let lastWateredDisplay = now.formatted(date: .numeric, time: .omitted)
        var changed = false

        for index in profile.myJungle.indices {
            guard needsWatering(myPlant: profile.myJungle[index]),
                  let plant = plant(for: profile.myJungle[index].plantId) else { continue }

            var history = profile.myJungle[index].wateringHistory ?? []
            history.append(dateString)
            profile.myJungle[index].wateringHistory = history
            profile.myJungle[index].lastWatered = lastWateredDisplay

            let frequencyDays = profile.myJungle[index].customWateringFrequencyDays ?? getWateringFrequency(for: plant)
            if let nextDate = Calendar.current.date(byAdding: .day, value: frequencyDays, to: now) {
                profile.myJungle[index].nextWateringDate = DataLoader.isoFormatter.string(from: nextDate)
            }
            changed = true
        }

        guard changed else { return }
        self.userProfile = profile
        self.updateLookup()
        saveMyJungleData()
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
              let plant = plant(for: plantId) else { return }

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
              let plant = plant(for: plantId) else { return }
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
        guard let plant = plant(for: myPlant.plantId) else { return nil }
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
        // Prefer the structured field when the catalog provides it.
        if let days = plant.careGuide.wateringFrequencyDays, days > 0 {
            return days
        }
        // Fall back to parsing the prose care text.
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

        // SwiftData is the durable store; the UserDefaults blob is kept in step because it is
        // also the iCloud KVS sync medium (see CloudSyncManager).
        JungleStore.shared.replaceAll(with: profile.myJungle)
        if let encoded = try? JSONEncoder().encode(profile.myJungle) {
            UserDefaults.standard.set(encoded, forKey: "myJungleExtendedData")
        }
        CloudSyncManager.shared.push()
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
            let name = myPlant.nickname
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
            let name = myPlant.nickname
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
            let name = myPlant.nickname
            return NotificationScheduler.MistingReminder(plantId: myPlant.plantId, plantName: name, dueDate: due)
        }
        NotificationScheduler.shared.syncMistingReminders(mistReminders, enabled: enabled, now: now)

        // --- Repotting (Pro) — from nextRepotDate ---
        let repotReminders: [NotificationScheduler.RepottingReminder] = profile.myJungle.compactMap { myPlant in
            guard let s = myPlant.nextRepotDate,
                  let date = DataLoader.isoFormatter.date(from: s) else { return nil }
            let name = myPlant.nickname
            return NotificationScheduler.RepottingReminder(plantId: myPlant.plantId, plantName: name, dueDate: date)
        }
        NotificationScheduler.shared.syncRepottingReminders(repotReminders, enabled: enabled, now: now)

        // --- Bloom countdown (Pro) — via BloomPredictor ---
        let hemisphere = BloomPredictor.hemisphere(forCountry: profile.locationSettings.country)
        let bloomReminders: [NotificationScheduler.BloomReminder] = profile.myJungle.compactMap { myPlant in
            guard let plant = plant(for: myPlant.plantId),
                  let window = BloomPredictor.predict(for: plant, hemisphere: hemisphere),
                  let daysAway = window.daysUntilNextBloom(from: now),
                  daysAway > 0 else { return nil }
            guard let bloomStart = Calendar.current.date(byAdding: .day, value: daysAway, to: now) else { return nil }
            let name = myPlant.nickname
            return NotificationScheduler.BloomReminder(
                plantId: myPlant.plantId, plantName: name,
                bloomStartDate: bloomStart, bloomNotes: window.notes
            )
        }
        NotificationScheduler.shared.syncBloomReminders(bloomReminders, enabled: enabled, now: now)

        // --- HomeKit threshold monitoring (Pro) ---
        if ProManager.shared.isPro {
            let thresholds: [HomeKitSensorManager.PlantThreshold] = profile.myJungle.compactMap { myPlant in
                guard let plant = plant(for: myPlant.plantId) else { return nil }
                let minHumidity = plant.careGuide.humidityMinPct ?? parseMinHumidity(from: plant.careGuide.humidity)
                let maxTemp = plant.careGuide.temperatureMaxC ?? parseMaxTempC(from: plant.careGuide.temperatureRange)
                let name = myPlant.nickname
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

        if let savedData = UserDefaults.standard.data(forKey: "myJungleExtendedData"),
           let savedPlants = try? JSONDecoder().decode([MyPlant].self, from: savedData) {
            // The blob doubles as the iCloud KVS sync medium, so when present (including
            // after a cloud pull) it wins; SwiftData is brought in step with it.
            JungleStore.shared.performMigrationIfNeeded(legacy: savedPlants)
            JungleStore.shared.replaceAll(with: savedPlants)
            profile.myJungle = savedPlants
            self.userProfile = profile
            self.updateLookup()
        } else {
            // No blob (fresh install or cleared defaults): fall back to whatever SwiftData
            // holds, keeping the bundled starter jungle if the store is empty too.
            JungleStore.shared.performMigrationIfNeeded(legacy: [])
            let stored = JungleStore.shared.fetchAll()
            if !stored.isEmpty {
                profile.myJungle = stored
                self.userProfile = profile
                self.updateLookup()
            }
        }
    }
}
