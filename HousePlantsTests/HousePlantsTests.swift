//
//  HousePlantsTests.swift
//  HousePlantsTests
//

import Foundation
import Testing
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
