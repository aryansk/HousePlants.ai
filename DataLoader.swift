import Foundation
import Combine

class DataLoader: ObservableObject {
    @Published var appData: AppData?
    @Published var plants: [Plant] = []
    @Published var categories: [PlantCategory] = []
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    
    init() {
        loadData()
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
            
        } catch {
            self.errorMessage = "Error decoding JSON: \(error.localizedDescription)"
            print("Error decoding JSON: \(error)")
        }
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
                healthLastUpdated: ISO8601DateFormatter().string(from: Date()),
                notes: nil,
                locationInHome: nil,
                customWateringFrequencyDays: nil
            )
            profile.myJungle.append(newPlant)
        }
        
        self.userProfile = profile
        saveMyJungleData()
    }
    
    // MARK: - Watering Management
    
    func waterPlant(plantId: String) {
        guard var profile = userProfile,
              let plantIndex = profile.myJungle.firstIndex(where: { $0.plantId == plantId }),
              let plant = plants.first(where: { $0.id == plantId }) else { return }
        
        let now = Date()
        let dateString = ISO8601DateFormatter().string(from: now)
        
        // Update watering history
        var history = profile.myJungle[plantIndex].wateringHistory ?? []
        history.append(dateString)
        profile.myJungle[plantIndex].wateringHistory = history
        
        // Update last watered
        profile.myJungle[plantIndex].lastWatered = now.formatted(date: .numeric, time: .omitted)
        
        // Calculate next watering date
        let frequencyDays = profile.myJungle[plantIndex].customWateringFrequencyDays ?? getWateringFrequency(for: plant)
        let nextDate = Calendar.current.date(byAdding: .day, value: frequencyDays, to: now)!
        profile.myJungle[plantIndex].nextWateringDate = ISO8601DateFormatter().string(from: nextDate)
        
        self.userProfile = profile
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
              let nextWateringDate = ISO8601DateFormatter().date(from: nextWateringString) else {
            // If no next watering date set, consider it needs watering
            return true
        }
        
        // Needs watering if next watering date is today or in the past
        return nextWateringDate <= Date()
    }
    
    func daysUntilWatering(myPlant: MyPlant) -> Int? {
        guard let nextWateringString = myPlant.nextWateringDate,
              let nextWateringDate = ISO8601DateFormatter().date(from: nextWateringString) else {
            return nil
        }
        
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextWateringDate).day
        return days
    }
    
    private func getWateringFrequency(for plant: Plant) -> Int {
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
        profile.myJungle[plantIndex].healthLastUpdated = ISO8601DateFormatter().string(from: Date())
        
        self.userProfile = profile
        saveMyJungleData()
    }
    
    func updatePlantNotes(plantId: String, notes: String) {
        guard var profile = userProfile,
              let plantIndex = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        
        profile.myJungle[plantIndex].notes = notes.isEmpty ? nil : notes
        
        self.userProfile = profile
        saveMyJungleData()
    }
    
    func updatePlantLocation(plantId: String, location: String) {
        guard var profile = userProfile,
              let plantIndex = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        
        profile.myJungle[plantIndex].locationInHome = location.isEmpty ? nil : location
        
        self.userProfile = profile
        saveMyJungleData()
    }
    
    func updatePlantNickname(plantId: String, nickname: String) {
        guard var profile = userProfile,
              let plantIndex = profile.myJungle.firstIndex(where: { $0.plantId == plantId }) else { return }
        
        profile.myJungle[plantIndex].nickname = nickname
        
        self.userProfile = profile
        saveMyJungleData()
    }
    
    // MARK: - Batch Operations
    
    func removePlants(plantIds: [String]) {
        guard var profile = userProfile else { return }
        
        profile.myJungle.removeAll { plantIds.contains($0.plantId) }
        
        self.userProfile = profile
        saveMyJungleData()
    }
    
    // MARK: - Data Persistence
    
    private func saveMyJungleData() {
        guard let profile = userProfile else { return }
        
        // Save extended MyPlant data to UserDefaults
        if let encoded = try? JSONEncoder().encode(profile.myJungle) {
            UserDefaults.standard.set(encoded, forKey: "myJungleExtendedData")
        }
    }
    
    func loadMyJungleExtendedData() {
        guard var profile = userProfile else { return }
        
        // Load extended data from UserDefaults if available
        if let savedData = UserDefaults.standard.data(forKey: "myJungleExtendedData"),
           let savedPlants = try? JSONDecoder().decode([MyPlant].self, from: savedData) {
            
            // Merge with existing jungle data (in case jason.json was updated)
            var mergedJungle: [MyPlant] = []
            
            for plantInJson in profile.myJungle {
                if let savedPlant = savedPlants.first(where: { $0.plantId == plantInJson.plantId }) {
                    // Use saved data (has extended properties)
                    mergedJungle.append(savedPlant)
                } else {
                    // New plant from JSON, use as-is
                    mergedJungle.append(plantInJson)
                }
            }
            
            profile.myJungle = mergedJungle
            self.userProfile = profile
        }
    }
}
