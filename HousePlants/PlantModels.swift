import Foundation

// MARK: - App Config
nonisolated struct AppData: Codable {
    let appConfig: AppConfig
    let toolsConfig: ToolsConfig
    let userProfile: UserProfile
    let plantCategories: [PlantCategory]
    let plantCatalog: [Plant]
    
    enum CodingKeys: String, CodingKey {
        case appConfig = "app_config"
        case toolsConfig = "tools_config"
        case userProfile = "user_profile"
        case plantCategories = "plant_categories"
        case plantCatalog = "plant_catalog"
    }
}

struct AppConfig: Codable {
    let appName: String
    let version: String
    let features: Features
    
    enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case version
        case features
    }
}

struct Features: Codable {
    let mlScanner: Bool
    let skincareLab: Bool
    let arPlacement: Bool
    let sunSeekerAr: Bool
    
    enum CodingKeys: String, CodingKey {
        case mlScanner = "ml_scanner"
        case skincareLab = "skincare_lab"
        case arPlacement = "ar_placement"
        case sunSeekerAr = "sun_seeker_ar"
    }
}

// MARK: - Tools Config
struct ToolsConfig: Codable {
    let sunSeeker: SunSeekerConfig
    
    enum CodingKeys: String, CodingKey {
        case sunSeeker = "sun_seeker"
    }
}

struct SunSeekerConfig: Codable {
    let measurementUnit: String
    let arOverlayEnabled: Bool
    let seasonalPathDisplay: Bool
    let calibrationNeeded: Bool
    let lightThresholds: LightThresholds
    
    enum CodingKeys: String, CodingKey {
        case measurementUnit = "measurement_unit"
        case arOverlayEnabled = "ar_overlay_enabled"
        case seasonalPathDisplay = "seasonal_path_display"
        case calibrationNeeded = "calibration_needed"
        case lightThresholds = "light_thresholds"
    }
}

struct LightThresholds: Codable {
    let low: LightLevel
    let medium: LightLevel
    let high: LightLevel
}

struct LightLevel: Codable {
    let max: Int
    let label: String
    let suitableFor: [String]
    
    enum CodingKeys: String, CodingKey {
        case max, label
        case suitableFor = "suitable_for"
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    let userId: String
    var username: String
    var locationSettings: LocationSettings
    var preferences: Preferences
    var favorites: [String]
    var myJungle: [MyPlant]
    var profileImage: String?
    var currentStreak: Int?
    var lastStreakDate: String?
    var streakHistory: [String]?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case locationSettings = "location_settings"
        case preferences
        case favorites
        case myJungle = "my_jungle"
        case profileImage = "profile_image"
        case currentStreak = "current_streak"
        case lastStreakDate = "last_streak_date"
        case streakHistory = "streak_history"
    }
}

struct LocationSettings: Codable {
    var city: String
    var country: String
    let climateZoneDetected: String
    let coordinates: Coordinates
    
    enum CodingKeys: String, CodingKey {
        case city, country
        case climateZoneDetected = "climate_zone_detected"
        case coordinates
    }
}

struct Coordinates: Codable {
    let lat: Double
    let lng: Double
}

nonisolated struct Preferences: Codable {
    var difficultyLevel: String
    var petSafeOnly: Bool
    var notifyOnSundays: Bool

    enum CodingKeys: String, CodingKey {
        case difficultyLevel = "difficulty_level"
        case petSafeOnly = "pet_safe_only"
        case notifyOnSundays = "notify_on_sundays"
    }

    init(difficultyLevel: String, petSafeOnly: Bool, notifyOnSundays: Bool) {
        self.difficultyLevel = difficultyLevel
        self.petSafeOnly = petSafeOnly
        self.notifyOnSundays = notifyOnSundays
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.difficultyLevel = try c.decode(String.self, forKey: .difficultyLevel)
        self.petSafeOnly = try c.decode(Bool.self, forKey: .petSafeOnly)
        self.notifyOnSundays = try c.decodeIfPresent(Bool.self, forKey: .notifyOnSundays) ?? false
    }
}

struct MyPlant: Codable, Identifiable, Equatable {
    var id: String { plantId }
    let plantId: String
    var nickname: String
    var dateAcquired: String
    var lastWatered: String
    
    // Extended properties for enhanced functionality
    var wateringHistory: [String]? // Array of ISO date strings
    var nextWateringDate: String? // ISO date string
    var healthScore: Int? // 0-100
    var healthLastUpdated: String? // ISO date string
    var notes: String? // User notes
    var locationInHome: String? // e.g., "Living Room", "Kitchen"
    var customWateringFrequencyDays: Int? // Override default watering frequency
    var lastFertilized: String? // ISO date string
    var lastMisted: String? // ISO date string

    // Weather-aware watering
    var isOutdoor: Bool?
    var wateringAdjustmentNote: String?

    // Repotting
    var potSizeInches: Int?
    var lastRepotted: String?
    var nextRepotDate: String?

    enum CodingKeys: String, CodingKey {
        case plantId = "plant_id"
        case nickname
        case dateAcquired = "date_acquired"
        case lastWatered = "last_watered"
        case wateringHistory = "watering_history"
        case nextWateringDate = "next_watering_date"
        case healthScore = "health_score"
        case healthLastUpdated = "health_last_updated"
        case notes
        case locationInHome = "location_in_home"
        case customWateringFrequencyDays = "custom_watering_frequency_days"
        case lastFertilized = "last_fertilized"
        case lastMisted = "last_misted"
        case isOutdoor = "is_outdoor"
        case wateringAdjustmentNote = "watering_adjustment_note"
        case potSizeInches = "pot_size_inches"
        case lastRepotted = "last_repotted"
        case nextRepotDate = "next_repot_date"
    }
}

// MARK: - Plant Category
struct PlantCategory: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
}

// MARK: - Plant
struct Plant: Codable, Identifiable {
    let id: String
    let commonName: String
    let botanicalName: String
    let categoryId: String
    let origin: Origin
    let images: PlantImages
    let description: String
    let careGuide: CareGuide
    let toxicity: Toxicity
    let mlRecognitionConfidence: Double
    let skincarePotential: SkincarePotential?
    let propagation: Propagation?
    let botanistQuote: BotanistQuote?
    
    enum CodingKeys: String, CodingKey {
        case id
        case commonName = "common_name"
        case botanicalName = "botanical_name"
        case categoryId = "category_id"
        case origin, images, description
        case careGuide = "care_guide"
        case toxicity
        case mlRecognitionConfidence = "ml_recognition_confidence"
        case skincarePotential = "skincare_potential"
        case propagation
        case botanistQuote = "botanist_quote"
    }
}

struct BotanistQuote: Codable {
    let quote: String
    let botanist: String
}

struct Origin: Codable {
    let region: String
    let countries: [String]?
    let coordinates: Coordinates
}

struct PlantImages: Codable {
    let main: String
}

struct CareGuide: Codable {
    let difficulty: String
    let light: String
    let water: String
    let humidity: String
    let soil: String
    let temperatureRange: String

    // Optional structured values. When present in plants.json they take precedence over
    // parsing the prose strings above (see DataLoader.getWateringFrequency and the
    // HomeKit threshold builders).
    var wateringFrequencyDays: Int? = nil
    var humidityMinPct: Double? = nil
    var temperatureMaxC: Double? = nil

    enum CodingKeys: String, CodingKey {
        case difficulty, light, water, humidity, soil
        case temperatureRange = "temperature_range"
        case wateringFrequencyDays = "watering_frequency_days"
        case humidityMinPct = "humidity_min_pct"
        case temperatureMaxC = "temperature_max_c"
    }
}

struct Toxicity: Codable {
    let isPetSafe: Bool
    let warning: String
    
    enum CodingKeys: String, CodingKey {
        case isPetSafe = "is_pet_safe"
        case warning
    }
}

struct RecipeIngredient: Codable, Hashable {
    let name: String
    let amount: String
    let purpose: String? // What this ingredient does
}

struct SkincarePotential: Codable {
    let enabled: Bool
    let benefits: String
    let diyRecipe: String
    
    // Enhanced optional fields (backward compatible)
    let categories: [String]? // ["Moisturizing", "Anti-Aging"]
    let skinTypes: [String]? // ["Dry", "Sensitive"]
    let difficulty: String? // "Beginner", "Intermediate", "Advanced"
    let prepTime: String? // "5 mins"
    let shelfLife: String? // "1 week (refrigerated)"
    let ingredients: [RecipeIngredient]?
    let instructions: [String]?
    let tips: [String]?
    let warnings: String?
    
    enum CodingKeys: String, CodingKey {
        case enabled, benefits
        case diyRecipe = "diy_recipe"
        case categories
        case skinTypes = "skin_types"
        case difficulty
        case prepTime = "prep_time"
        case shelfLife = "shelf_life"
        case ingredients
        case instructions
        case tips
        case warnings
    }
}

struct Propagation: Codable {
    let methods: [String]
    let difficulty: String
    let instructions: [String]
}

extension Plant {
    var effectivePropagation: Propagation {
        if let propagation = self.propagation {
            return propagation
        }
        
        // Return fallback propagation based on category
        switch categoryId {
        case "cat_aroid":
            return Propagation(
                methods: ["Stem Cuttings", "Water Propagation"],
                difficulty: "Easy",
                instructions: [
                    "Identify a node (point where leaf meets stem) on a healthy vine.",
                    "Cut 1/4 inch below the node using clean, sharp shears.",
                    "Place the cutting in a glass of water, ensuring the node is submerged.",
                    "Wait for roots to reach 2 inches long (2-4 weeks) before potting in soil."
                ]
            )
        case "cat_succulent":
            return Propagation(
                methods: ["Leaf Cuttings", "Division", "Offsets"],
                difficulty: "Easy",
                instructions: [
                    "Gently twist a healthy leaf from the stem until it snaps off cleanly.",
                    "Lay the leaf on a dry paper towel for 2-3 days until the end calluses over.",
                    "Place on top of well-draining succulent soil and mist occasionally.",
                    "A tiny new plantlet will emerge from the leaf base in 4-6 weeks."
                ]
            )
        case "cat_fern":
            return Propagation(
                methods: ["Division"],
                difficulty: "Moderate",
                instructions: [
                    "Spring is the best time. Remove the fern from its pot carefully.",
                    "Use a clean knife or your fingers to separate the root ball into 2-3 sections.",
                    "Ensure each division has several healthy fronds and a good root system.",
                    "Repot into fresh, moisture-retentive fern mix and keep highly humid."
                ]
            )
        case "cat_tree":
            return Propagation(
                methods: ["Stem Cuttings", "Air Layering"],
                difficulty: "Hard",
                instructions: [
                    "Take a 6-inch cutting from a semi-hardwood branch in late spring.",
                    "Remove lower leaves and dip the cut end in rooting hormone powder.",
                    "Insert into a pot with sterile rooting medium (perlite and peat).",
                    "Cover with a plastic bag to maintain high humidity and wait 2-3 months."
                ]
            )
        case "cat_flower":
            return Propagation(
                methods: ["Stem Cuttings", "Seeds"],
                difficulty: "Moderate",
                instructions: [
                    "Select a healthy, non-flowering shoot about 4 inches long.",
                    "Make a clean cut just below a node and remove the lower leaves.",
                    "Place in moist seed-starting mix and provide bright, indirect light.",
                    "Maintain consistent moisture and warmth until new growth appears."
                ]
            )
        default:
            return Propagation(
                methods: ["Consult Species-Specific Guide"],
                difficulty: "Variable",
                instructions: [
                    "Specific propagation steps for this species are under research.",
                    "Suggested: Search for \(botanicalName) propagation methods.",
                    "Generally, stem cuttings or division work for most houseplants.",
                    "Ensure you use sterile tools to prevent disease transmission."
                ]
            )
        }
    }
}
