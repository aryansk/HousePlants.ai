//
//  HousePlantsTests.swift
//  HousePlantsTests
//

import Foundation
import Testing
import UIKit
@testable import HousePlants

// MARK: - Fixtures

private func makePlant(
    botanicalName: String = "Phalaenopsis amabilis",
    humidity: String = "Medium",
    categoryId: String = "cat_flower"
) -> Plant {
    Plant(
        id: "p1",
        commonName: "Test Plant",
        botanicalName: botanicalName,
        categoryId: categoryId,
        origin: Origin(region: "Asia", countries: nil, coordinates: Coordinates(lat: 0, lng: 0)),
        images: PlantImages(main: "img"),
        description: "desc",
        careGuide: CareGuide(
            difficulty: "Easy", light: "Bright", water: "Weekly",
            humidity: humidity, soil: "Loose", temperatureRange: "18-24C"
        ),
        toxicity: Toxicity(isPetSafe: true, warning: ""),
        mlRecognitionConfidence: 0.9,
        skincarePotential: nil,
        propagation: nil,
        botanistQuote: nil
    )
}

private func makeMyPlant(
    nextWateringDate: String? = nil,
    lastFertilized: String? = nil,
    lastMisted: String? = nil,
    nextRepotDate: String? = nil
) -> MyPlant {
    MyPlant(
        plantId: "p1", nickname: "Testy",
        dateAcquired: "2025-01-01T00:00:00Z", lastWatered: "2025-01-01T00:00:00Z",
        wateringHistory: nil, nextWateringDate: nextWateringDate,
        healthScore: nil, healthLastUpdated: nil, notes: nil, locationInHome: nil,
        customWateringFrequencyDays: nil, lastFertilized: lastFertilized,
        lastMisted: lastMisted, isOutdoor: nil, wateringAdjustmentNote: nil,
        potSizeInches: nil, lastRepotted: nil, nextRepotDate: nextRepotDate
    )
}

private func iso(daysFromNow days: Int, from now: Date) -> String {
    DataLoader.isoFormatter.string(from: Calendar.current.date(byAdding: .day, value: days, to: now)!)
}

// MARK: - Preferences decoding

struct PreferencesDecodingTests {
    @Test func decodesAllFields() throws {
        let json = #"{"difficulty_level":"beginner","pet_safe_only":true,"notify_on_sundays":true}"#
        let prefs = try JSONDecoder().decode(Preferences.self, from: Data(json.utf8))
        #expect(prefs.difficultyLevel == "beginner")
        #expect(prefs.petSafeOnly == true)
        #expect(prefs.notifyOnSundays == true)
    }

    @Test func missingNotifyOnSundaysDefaultsToFalse() throws {
        let json = #"{"difficulty_level":"expert","pet_safe_only":false}"#
        let prefs = try JSONDecoder().decode(Preferences.self, from: Data(json.utf8))
        #expect(prefs.notifyOnSundays == false)
    }
}

// MARK: - Bundled catalog

struct PlantCatalogTests {
    @Test func bundledCatalogDecodes() throws {
        let url = try #require(Bundle.main.url(forResource: "plants", withExtension: "json"),
                               "plants.json missing from app bundle")
        let data = try Data(contentsOf: url)
        let appData = try JSONDecoder().decode(AppData.self, from: data)
        #expect(!appData.plantCatalog.isEmpty)
        #expect(!appData.plantCategories.isEmpty)

        let ids = appData.plantCatalog.map(\.id)
        #expect(Set(ids).count == ids.count, "plant ids must be unique")

        let categoryIds = Set(appData.plantCategories.map(\.id))
        for plant in appData.plantCatalog {
            #expect(categoryIds.contains(plant.categoryId),
                    "plant \(plant.id) references unknown category \(plant.categoryId)")
        }
    }

    @Test func bundledFixtureDoesNotSeedPersonalState() throws {
        let url = try #require(Bundle.main.url(forResource: "plants", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let appData = try JSONDecoder().decode(AppData.self, from: data)
        let profile = DataLoader.emptyProfile(from: appData.userProfile)

        #expect(profile.username.isEmpty)
        #expect(profile.locationSettings.city.isEmpty)
        #expect(profile.favorites.isEmpty)
        #expect(profile.myJungle.isEmpty)
        #expect(profile.currentStreak == nil)
    }

    @Test @MainActor func bundledCatalogImagesResolve() throws {
        let url = try #require(Bundle.main.url(forResource: "plants", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let appData = try JSONDecoder().decode(AppData.self, from: data)

        for plant in appData.plantCatalog where !plant.images.main.hasPrefix("http") {
            #expect(
                UIImage(named: plant.assetImageName) != nil,
                "missing bundled image \(plant.assetImageName) for \(plant.id)"
            )
        }
    }
}

// MARK: - HealthScoreEngine

struct HealthScoreEngineTests {
    let now = Date()

    @Test func healthyPlantScoresHigh() {
        let assessment = HealthScoreEngine.compute(
            myPlant: makeMyPlant(nextWateringDate: iso(daysFromNow: 3, from: now),
                                 lastFertilized: iso(daysFromNow: -10, from: now)),
            plant: makePlant(),
            journalPhotoCount: 0, mostRecentJournalDate: nil, now: now
        )
        #expect(assessment.score == 100)
    }

    @Test func overdueWateringIsPenalizedFivePerDayCappedAtThirty() {
        let twoDays = HealthScoreEngine.compute(
            myPlant: makeMyPlant(nextWateringDate: iso(daysFromNow: -2, from: now),
                                 lastFertilized: iso(daysFromNow: -10, from: now)),
            plant: makePlant(),
            journalPhotoCount: 0, mostRecentJournalDate: nil, now: now
        )
        #expect(twoDays.score == 90)

        let veryLate = HealthScoreEngine.compute(
            myPlant: makeMyPlant(nextWateringDate: iso(daysFromNow: -30, from: now),
                                 lastFertilized: iso(daysFromNow: -10, from: now)),
            plant: makePlant(),
            journalPhotoCount: 0, mostRecentJournalDate: nil, now: now
        )
        #expect(veryLate.score == 70, "watering penalty caps at 30")
    }

    @Test func neverFertilizedLosesFivePoints() {
        let assessment = HealthScoreEngine.compute(
            myPlant: makeMyPlant(nextWateringDate: iso(daysFromNow: 3, from: now)),
            plant: makePlant(),
            journalPhotoCount: 0, mostRecentJournalDate: nil, now: now
        )
        #expect(assessment.score == 95)
        #expect(assessment.factors.contains { $0.label == "Never fertilized" })
    }

    @Test func humidityLovingPlantNeedsMisting() {
        let assessment = HealthScoreEngine.compute(
            myPlant: makeMyPlant(nextWateringDate: iso(daysFromNow: 3, from: now),
                                 lastFertilized: iso(daysFromNow: -10, from: now)),
            plant: makePlant(humidity: "High humidity"),
            journalPhotoCount: 0, mostRecentJournalDate: nil, now: now
        )
        #expect(assessment.score == 95)
        #expect(assessment.factors.contains { $0.label == "Needs misting" })
    }

    @Test func recentJournalingAddsBonusButScoreCapsAtHundred() {
        let assessment = HealthScoreEngine.compute(
            myPlant: makeMyPlant(nextWateringDate: iso(daysFromNow: 3, from: now),
                                 lastFertilized: iso(daysFromNow: -10, from: now)),
            plant: makePlant(),
            journalPhotoCount: 4,
            mostRecentJournalDate: Calendar.current.date(byAdding: .day, value: -5, to: now),
            now: now
        )
        #expect(assessment.score == 100)
        #expect(assessment.factors.contains { $0.label == "Active journaling" })
    }

    @Test func overdueRepottingLosesTenPoints() {
        let assessment = HealthScoreEngine.compute(
            myPlant: makeMyPlant(nextWateringDate: iso(daysFromNow: 3, from: now),
                                 lastFertilized: iso(daysFromNow: -10, from: now),
                                 nextRepotDate: iso(daysFromNow: -1, from: now)),
            plant: makePlant(),
            journalPhotoCount: 0, mostRecentJournalDate: nil, now: now
        )
        #expect(assessment.score == 90)
    }
}

// MARK: - BloomPredictor

struct BloomPredictorTests {
    @Test func predictsFromGenus() throws {
        let window = try #require(BloomPredictor.predict(for: makePlant(botanicalName: "Phalaenopsis amabilis")))
        #expect(window.months == [2, 3, 4])
    }

    @Test func unknownGenusReturnsNil() {
        #expect(BloomPredictor.predict(for: makePlant(botanicalName: "Madeupus fakeus")) == nil)
    }

    @Test func southernHemisphereFlipsMonthsBySix() throws {
        let window = try #require(BloomPredictor.predict(for: makePlant(botanicalName: "Phalaenopsis amabilis"),
                                                         hemisphere: .southern))
        #expect(window.months.sorted() == [8, 9, 10])
    }

    @Test func hemisphereLookup() {
        #expect(BloomPredictor.hemisphere(forCountry: "Australia") == .southern)
        #expect(BloomPredictor.hemisphere(forCountry: "Japan") == .northern)
        #expect(BloomPredictor.hemisphere(forCountry: nil) == .northern)
    }

    @Test func daysUntilNextBloomWrapsToNextYear() throws {
        let calendar = Calendar.current
        // Fixed reference: June 15, 2026. Window is Feb-Apr, so next bloom is Feb 1, 2027.
        let june15 = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        let window = BloomWindow(months: [2, 3, 4], notes: "")
        let days = try #require(window.daysUntilNextBloom(from: june15, calendar: calendar))
        let feb1 = try #require(calendar.date(from: DateComponents(year: 2027, month: 2, day: 1)))
        let expected = calendar.dateComponents([.day], from: june15, to: feb1).day
        #expect(days == expected)
    }

    @Test func daysUntilNextBloomInCurrentMonthIsNonPositive() throws {
        let calendar = Calendar.current
        let march10 = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 10)))
        let window = BloomWindow(months: [3], notes: "")
        let days = try #require(window.daysUntilNextBloom(from: march10, calendar: calendar))
        #expect(days <= 0, "bloom month already underway")
    }
}

struct PlantCatalogMatcherTests {
    @Test func normalizeKeepsGenusAndSpecies() {
        #expect(PlantCatalogMatcher.normalize("Monstera deliciosa Liebm.") == "monstera deliciosa")
        #expect(PlantCatalogMatcher.normalize("Ficus lyrata") == "ficus lyrata")
    }

    @Test func normalizeStripsCultivarQuotes() {
        #expect(PlantCatalogMatcher.normalize("Epipremnum aureum 'Marble Queen'") == "epipremnum aureum")
    }

    @Test func normalizeStripsVarietyMarkers() {
        #expect(PlantCatalogMatcher.normalize("Sansevieria trifasciata var. laurentii") == "sansevieria trifasciata")
    }

    @Test func matchesExactSpecies() {
        let catalog = [
            makePlant(botanicalName: "Monstera deliciosa"),
            makePlant(botanicalName: "Ficus lyrata")
        ]
        let match = PlantCatalogMatcher.match(scientificName: "Monstera deliciosa", in: catalog)
        #expect(match?.botanicalName == "Monstera deliciosa")
    }

    @Test func fallsBackToGenusWhenSpeciesDiffers() {
        let catalog = [makePlant(botanicalName: "Monstera deliciosa")]
        let match = PlantCatalogMatcher.match(scientificName: "Monstera adansonii", in: catalog)
        #expect(match?.botanicalName == "Monstera deliciosa")
    }

    @Test func returnsNilForUnknownGenus() {
        let catalog = [makePlant(botanicalName: "Monstera deliciosa")]
        #expect(PlantCatalogMatcher.match(scientificName: "Quercus robur", in: catalog) == nil)
    }
}

// MARK: - Care experience

struct CareExperienceStoreTests {
    private func timestamp(_ date: Date) -> String {
        DataLoader.isoFormatter.string(from: date)
    }

    @Test func sprigStagesUseGentleMonotonicThresholds() {
        #expect(SprigStage.from(actionCount: 0) == .seedling)
        #expect(SprigStage.from(actionCount: 5) == .sprout)
        #expect(SprigStage.from(actionCount: 15) == .leafy)
        #expect(SprigStage.from(actionCount: 40) == .blooming)
        #expect(SprigStage.from(actionCount: 100) == .blooming)
    }

    @Test func migrationDerivesWateringEventsAndLegacyDates() throws {
        let suite = try #require(UserDefaults(suiteName: "CareExperienceStoreTests.migration"))
        suite.removePersistentDomain(forName: "CareExperienceStoreTests.migration")
        let day = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 26)))
        let store = CareExperienceStore(defaults: suite, nowProvider: { day })
        let watering = timestamp(day.addingTimeInterval(-86_400))

        store.bootstrap(
            plantWateringHistory: ["p1": [watering, watering], "p2": [timestamp(day)]],
            legacyStreakDates: [timestamp(day.addingTimeInterval(-2 * 86_400))]
        )

        #expect(store.lifetimeActionCount == 2)
        #expect(store.events.map(\.plantID).sorted() == ["p1", "p2"])
        #expect(store.rhythm(now: day).activeDays == 3)
    }

    @Test func duplicatePlantDayDoesNotAdvanceProgress() throws {
        let suite = try #require(UserDefaults(suiteName: "CareExperienceStoreTests.duplicates"))
        suite.removePersistentDomain(forName: "CareExperienceStoreTests.duplicates")
        let day = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 26)))
        let store = CareExperienceStore(defaults: suite, nowProvider: { day })

        #expect(store.recordEligibleWatering(plantID: "p1", occurredAt: timestamp(day), transactionID: "one") != nil)
        #expect(store.recordEligibleWatering(plantID: "p1", occurredAt: timestamp(day.addingTimeInterval(60)), transactionID: "two") == nil)
        #expect(store.lifetimeActionCount == 1)
    }

    @Test func undoRemovesActionAndRecomputesStage() throws {
        let suite = try #require(UserDefaults(suiteName: "CareExperienceStoreTests.undo"))
        suite.removePersistentDomain(forName: "CareExperienceStoreTests.undo")
        let day = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 26)))
        let store = CareExperienceStore(defaults: suite, nowProvider: { day })

        for index in 0..<5 {
            let eventDay = day.addingTimeInterval(Double(index) * 86_400)
            _ = store.recordEligibleWatering(plantID: "p\(index)", occurredAt: timestamp(eventDay), transactionID: "event-\(index)")
        }
        #expect(store.stage == .sprout)
        store.undo(eventID: "event-4")
        #expect(store.stage == .seedling)
        #expect(store.lifetimeActionCount == 4)
    }

    @Test func rhythmCountsActiveDaysInTheLastWeek() throws {
        let suite = try #require(UserDefaults(suiteName: "CareExperienceStoreTests.rhythm"))
        suite.removePersistentDomain(forName: "CareExperienceStoreTests.rhythm")
        let calendar = Calendar.current
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 26)))
        let store = CareExperienceStore(defaults: suite, calendar: calendar, nowProvider: { today })

        _ = store.recordEligibleWatering(plantID: "p1", occurredAt: timestamp(today), transactionID: "today")
        _ = store.recordEligibleWatering(plantID: "p2", occurredAt: timestamp(today.addingTimeInterval(-86_400)), transactionID: "yesterday")
        _ = store.recordEligibleWatering(plantID: "p3", occurredAt: timestamp(today.addingTimeInterval(-3 * 86_400)), transactionID: "three-days-ago")

        let rhythm = store.rhythm(now: today)
        #expect(rhythm.activeDays == 3)
        #expect(rhythm.currentRun == 2)
    }

    @Test func recapUsesCalendarWeekBoundaryAndMostCaredPlant() throws {
        let suite = try #require(UserDefaults(suiteName: "CareExperienceStoreTests.recap"))
        suite.removePersistentDomain(forName: "CareExperienceStoreTests.recap")
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let wednesday = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 29)))
        let store = CareExperienceStore(defaults: suite, calendar: calendar, nowProvider: { wednesday })

        _ = store.recordEligibleWatering(plantID: "p1", occurredAt: timestamp(wednesday), transactionID: "recap-1")
        _ = store.recordEligibleWatering(plantID: "p2", occurredAt: timestamp(wednesday.addingTimeInterval(-86_400)), transactionID: "recap-2")
        _ = store.recordEligibleWatering(plantID: "p2", occurredAt: timestamp(wednesday.addingTimeInterval(-2 * 86_400)), transactionID: "recap-3")

        let recap = try #require(store.recap(now: wednesday))
        #expect(recap.activeDays == 3)
        #expect(recap.actionCount == 3)
        #expect(recap.plantsCaredFor == 2)
        #expect(recap.mostCaredPlantID == "p2")
    }
}

// MARK: - DataLoader Transactions & JungleStore

struct DataLoaderTransactionTests {
    @Test @MainActor func testWaterPlantTransactionAndUndo() {
        let loader = DataLoader.shared
        let plant = makePlant()
        loader.plants = [plant]
        loader.plantsById = [plant.id: plant]

        let initialMyPlant = makeMyPlant(nextWateringDate: iso(daysFromNow: -1, from: Date()))
        loader.userProfile = UserProfile(
            userId: "test", username: "Tester",
            locationSettings: LocationSettings(city: "SF", country: "US", climateZoneDetected: "", coordinates: Coordinates(lat: 0, lng: 0)),
            preferences: Preferences(difficultyLevel: "Beginner", petSafeOnly: false, notifyOnSundays: false),
            favorites: [], myJungle: [initialMyPlant]
        )
        loader.updateLookup()

        let tx = loader.waterPlantTransaction(plantId: plant.id)
        #expect(tx != nil)
        #expect(loader.userProfile?.myJungle.first?.wateringHistory?.isEmpty == false)

        if let tx {
            let undoSuccess = loader.undoWatering(tx)
            #expect(undoSuccess == true)
            #expect(loader.userProfile?.myJungle.first?.lastWatered == initialMyPlant.lastWatered)
        }
    }

    @Test @MainActor func testToggleJungleAddAndRemove() {
        let loader = DataLoader.shared
        let plant = makePlant()
        loader.plants = [plant]
        loader.plantsById = [plant.id: plant]
        loader.userProfile = UserProfile(
            userId: "test", username: "Tester",
            locationSettings: LocationSettings(city: "SF", country: "US", climateZoneDetected: "", coordinates: Coordinates(lat: 0, lng: 0)),
            preferences: Preferences(difficultyLevel: "Beginner", petSafeOnly: false, notifyOnSundays: false),
            favorites: [], myJungle: []
        )
        loader.updateLookup()

        loader.toggleJungle(plant: plant)
        #expect(loader.userProfile?.myJungle.count == 1)
        #expect(loader.userProfile?.myJungle.first?.plantId == plant.id)

        loader.toggleJungle(plant: plant)
        #expect(loader.userProfile?.myJungle.isEmpty == true)
    }

    @Test @MainActor func testReorderJungle() {
        let loader = DataLoader.shared
        let plant1 = makeMyPlant(nextWateringDate: nil)
        var plant2 = makeMyPlant(nextWateringDate: nil)
        plant2.plantId = "p2"
        var plant3 = makeMyPlant(nextWateringDate: nil)
        plant3.plantId = "p3"

        loader.userProfile = UserProfile(
            userId: "test", username: "Tester",
            locationSettings: LocationSettings(city: "SF", country: "US", climateZoneDetected: "", coordinates: Coordinates(lat: 0, lng: 0)),
            preferences: Preferences(difficultyLevel: "Beginner", petSafeOnly: false, notifyOnSundays: false),
            favorites: [], myJungle: [plant1, plant2, plant3]
        )
        loader.updateLookup()

        loader.reorderJungle(to: ["p3", "p1"])
        let ids = loader.userProfile?.myJungle.map(\.plantId)
        #expect(ids == ["p3", "p1", "p2"]) // p2 remains at the end
    }

    @Test @MainActor func testUpdateProfileInfo() {
        let loader = DataLoader.shared
        loader.userProfile = UserProfile(
            userId: "test", username: "OldName",
            locationSettings: LocationSettings(city: "OldCity", country: "OldCountry", climateZoneDetected: "", coordinates: Coordinates(lat: 0, lng: 0)),
            preferences: Preferences(difficultyLevel: "Beginner", petSafeOnly: false, notifyOnSundays: false),
            favorites: [], myJungle: []
        )

        loader.updateProfile(username: "NewName", city: "NewCity", country: "NewCountry")
        #expect(loader.userProfile?.username == "NewName")
        #expect(loader.userProfile?.locationSettings.city == "NewCity")
        #expect(loader.userProfile?.locationSettings.country == "NewCountry")
    }
}

struct JungleStoreTests {
    @Test func testJungleStoreMigrationAndReplace() {
        let store = JungleStore(inMemory: true, defaults: UserDefaults(suiteName: "JungleStoreTests")!)
        let p1 = makeMyPlant(nextWateringDate: nil)

        let didMigrate = store.performMigrationIfNeeded(legacy: [p1])
        #expect(didMigrate == true)

        let fetched = store.fetchAll()
        #expect(fetched.count == 1)
        #expect(fetched.first?.plantId == "p1")
    }
}
