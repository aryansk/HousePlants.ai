import Foundation
import SwiftData
import os

// MARK: - SwiftData record

/// SwiftData-backed counterpart of the `MyPlant` struct. One-to-one field mapping so the
/// existing `MyPlant` value type (still used everywhere in the app) can be hydrated trivially.
@Model
final class MyPlantRecord {
    @Attribute(.unique) var plantId: String
    var nickname: String
    var dateAcquired: String
    var lastWatered: String

    var wateringHistory: [String]?
    var nextWateringDate: String?
    var healthScore: Int?
    var healthLastUpdated: String?
    var notes: String?
    var locationInHome: String?
    var customWateringFrequencyDays: Int?
    var lastFertilized: String?
    var lastMisted: String?
    var isOutdoor: Bool?
    var wateringAdjustmentNote: String?
    var potSizeInches: Int?
    var lastRepotted: String?
    var nextRepotDate: String?

    init(plantId: String, nickname: String, dateAcquired: String, lastWatered: String) {
        self.plantId = plantId
        self.nickname = nickname
        self.dateAcquired = dateAcquired
        self.lastWatered = lastWatered
    }
}

// MARK: - MyPlant ↔ MyPlantRecord bridge

private extension MyPlantRecord {
    convenience init(_ mp: MyPlant) {
        self.init(plantId: mp.plantId, nickname: mp.nickname,
                  dateAcquired: mp.dateAcquired, lastWatered: mp.lastWatered)
        apply(mp)
    }

    func apply(_ mp: MyPlant) {
        nickname = mp.nickname
        dateAcquired = mp.dateAcquired
        lastWatered = mp.lastWatered
        wateringHistory = mp.wateringHistory
        nextWateringDate = mp.nextWateringDate
        healthScore = mp.healthScore
        healthLastUpdated = mp.healthLastUpdated
        notes = mp.notes
        locationInHome = mp.locationInHome
        customWateringFrequencyDays = mp.customWateringFrequencyDays
        lastFertilized = mp.lastFertilized
        lastMisted = mp.lastMisted
        isOutdoor = mp.isOutdoor
        wateringAdjustmentNote = mp.wateringAdjustmentNote
        potSizeInches = mp.potSizeInches
        lastRepotted = mp.lastRepotted
        nextRepotDate = mp.nextRepotDate
    }

    func asMyPlant() -> MyPlant {
        var mp = MyPlant(plantId: plantId, nickname: nickname,
                         dateAcquired: dateAcquired, lastWatered: lastWatered)
        mp.wateringHistory = wateringHistory
        mp.nextWateringDate = nextWateringDate
        mp.healthScore = healthScore
        mp.healthLastUpdated = healthLastUpdated
        mp.notes = notes
        mp.locationInHome = locationInHome
        mp.customWateringFrequencyDays = customWateringFrequencyDays
        mp.lastFertilized = lastFertilized
        mp.lastMisted = lastMisted
        mp.isOutdoor = isOutdoor
        mp.wateringAdjustmentNote = wateringAdjustmentNote
        mp.potSizeInches = potSizeInches
        mp.lastRepotted = lastRepotted
        mp.nextRepotDate = nextRepotDate
        return mp
    }
}

// MARK: - Store

/// Owns the SwiftData `ModelContainer` for the user's jungle. The rest of the app continues to
/// use `[MyPlant]` value types; this class is the single bridge between them and SwiftData.
///
/// Phase 1: local-only SwiftData. Phase 2 will add CloudKit by switching the ModelConfiguration.
final class JungleStore {
    static let shared = JungleStore()

    /// Key set when the one-time UserDefaults→SwiftData migration succeeds. Once set, the legacy
    /// `myJungleExtendedData` blob is frozen — it stays on disk for one release as a fallback.
    static let migrationFlagKey = "didMigrateJungleToSwiftData"

    private let container: ModelContainer
    private let defaults: UserDefaults

    private var context: ModelContext { container.mainContext }

    init(inMemory: Bool = false, defaults: UserDefaults = .standard) {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            self.container = try ModelContainer(for: MyPlantRecord.self, configurations: config)
        } catch {
            // A truly catastrophic failure here means SwiftData can't open at all — log and crash
            // so the issue surfaces in TestFlight rather than silently losing data.
            Logger.persistence.critical("JungleStore ModelContainer init failed: \(error.localizedDescription, privacy: .public)")
            fatalError("JungleStore ModelContainer failed to initialize: \(error)")
        }
        self.defaults = defaults
    }

    /// Returns all plants in the store as value-type `MyPlant`s.
    func fetchAll() -> [MyPlant] {
        do {
            return try context.fetch(FetchDescriptor<MyPlantRecord>()).map { $0.asMyPlant() }
        } catch {
            Logger.persistence.error("JungleStore fetch failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// Upserts the supplied jungle, deleting any records no longer in the set. This mirrors the
    /// "replace the whole blob" semantics of the previous UserDefaults-backed storage so callers
    /// don't have to track diffs.
    func replaceAll(with plants: [MyPlant]) {
        do {
            let existing = try context.fetch(FetchDescriptor<MyPlantRecord>())
            let newIds = Set(plants.map(\.plantId))

            for record in existing where !newIds.contains(record.plantId) {
                context.delete(record)
            }

            let byId = Dictionary(uniqueKeysWithValues: existing.map { ($0.plantId, $0) })
            for plant in plants {
                if let existingRecord = byId[plant.plantId] {
                    existingRecord.apply(plant)
                } else {
                    context.insert(MyPlantRecord(plant))
                }
            }

            try context.save()
        } catch {
            Logger.persistence.error("JungleStore save failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Imports the legacy UserDefaults blob into SwiftData the first time it runs. Idempotent:
    /// the migration flag in UserDefaults guards re-runs, and `replaceAll` is itself an upsert,
    /// so even a forced re-run wouldn't duplicate rows.
    @discardableResult
    func performMigrationIfNeeded(legacy: [MyPlant]) -> Bool {
        guard !defaults.bool(forKey: Self.migrationFlagKey) else { return false }
        if !legacy.isEmpty {
            replaceAll(with: legacy)
            Logger.persistence.notice("Migrated \(legacy.count, privacy: .public) plants from UserDefaults to SwiftData")
        }
        defaults.set(true, forKey: Self.migrationFlagKey)
        return true
    }
}
