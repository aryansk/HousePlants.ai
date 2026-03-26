import Foundation

// MARK: - App Config
struct AppData: Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case locationSettings = "location_settings"
        case preferences
        case favorites
        case myJungle = "my_jungle"
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

struct Preferences: Codable {
    let difficultyLevel: String
    let petSafeOnly: Bool
    
    enum CodingKeys: String, CodingKey {
        case difficultyLevel = "difficulty_level"
        case petSafeOnly = "pet_safe_only"
    }
}

struct MyPlant: Codable, Identifiable {
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
    }
}

struct Origin: Codable {
    let region: String
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
    
    enum CodingKeys: String, CodingKey {
        case difficulty, light, water, humidity, soil
        case temperatureRange = "temperature_range"
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

struct RecipeIngredient: Codable {
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
