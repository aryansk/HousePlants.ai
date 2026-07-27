import Foundation
import Observation

/// The small, local progress system behind the daily-care experience.
///
/// Care progress is intentionally separate from plant health. A missed day never removes
/// progress, and only a due watering can advance Sprig. The store is Codable so it can be
/// mirrored by the existing iCloud key-value bridge without introducing a backend.
enum CareEventKind: String, Codable {
    case watering
}

struct CareEvent: Codable, Equatable, Identifiable {
    let id: String
    let plantID: String
    let occurredAt: String
    let kind: CareEventKind
}

enum SprigStage: String, Codable, CaseIterable {
    case seedling
    case sprout
    case leafy
    case blooming

    var title: String {
        switch self {
        case .seedling: return "Seedling"
        case .sprout: return "Sprout"
        case .leafy: return "Leafy"
        case .blooming: return "Blooming"
        }
    }

    var nextThreshold: Int? {
        switch self {
        case .seedling: return 5
        case .sprout: return 15
        case .leafy: return 40
        case .blooming: return nil
        }
    }

    static func from(actionCount: Int) -> SprigStage {
        switch actionCount {
        case 40...: return .blooming
        case 15..<40: return .leafy
        case 5..<15: return .sprout
        default: return .seedling
        }
    }
}

struct CareRhythmSummary: Equatable {
    let activeDays: Int
    let currentRun: Int
    let windowDays: Int
}

struct JungleRecap: Identifiable, Equatable {
    let id: String
    let weekLabel: String
    let activeDays: Int
    let actionCount: Int
    let plantsCaredFor: Int
    let mostCaredPlantID: String?
    let stage: SprigStage
}

@Observable
final class CareExperienceStore {
    static let shared = CareExperienceStore()

    private struct PersistedState: Codable {
        var version: Int = 1
        var events: [CareEvent] = []
        var legacyActiveDates: [String] = []
        var lastSeenRecapWeek: String?
    }

    private(set) var events: [CareEvent] = []
    private(set) var stage: SprigStage = .seedling
    private(set) var lifetimeActionCount = 0
    private(set) var lastSeenRecapWeek: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let nowProvider: () -> Date
    @ObservationIgnored private var legacyActiveDates: Set<String> = []
    @ObservationIgnored private var didBootstrap = false

    private let storageKey = "care_experience_v1"

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.nowProvider = nowProvider
        load()
    }

    var hasCareHistory: Bool { !events.isEmpty || !legacyActiveDates.isEmpty }

    var recapAvailable: Bool {
        guard hasCareHistory else { return false }
        return lastSeenRecapWeek != weekKey(for: nowProvider())
    }

    func bootstrap(using loader: DataLoader) {
        let wateringHistory = Dictionary(uniqueKeysWithValues: (loader.userProfile?.myJungle ?? []).map {
            ($0.plantId, $0.wateringHistory ?? [])
        })
        bootstrap(plantWateringHistory: wateringHistory, legacyStreakDates: loader.userProfile?.streakHistory ?? [])
    }

    /// Migration seam kept internal so it can be verified without constructing the full app loader.
    func bootstrap(plantWateringHistory: [String: [String]], legacyStreakDates: [String]) {
        guard !didBootstrap else { return }
        didBootstrap = true

        // A state created by an older release has no care-experience blob. Reconstruct enough
        // history from the existing per-plant watering logs and legacy streak dates to avoid
        // making established users start from zero.
        guard events.isEmpty, legacyActiveDates.isEmpty else { return }
        var migrated: [CareEvent] = []
        for (plantID, history) in plantWateringHistory {
            for timestamp in history {
                let id = "migration-\(plantID)-\(timestamp)"
                migrated.append(CareEvent(id: id, plantID: plantID, occurredAt: timestamp, kind: .watering))
            }
        }
        events = deduplicated(migrated)
        legacyActiveDates = Set(legacyStreakDates.compactMap { dateKey(from: $0) })
        refreshDerivedState()
        persist()
    }

    @discardableResult
    func recordEligibleWatering(plantID: String, occurredAt: String, transactionID: String) -> CareEvent? {
        guard !events.contains(where: { $0.id == transactionID }) else { return nil }
        guard let day = dateKey(from: occurredAt) else { return nil }
        // One eligible action per plant/day prevents repeated taps from becoming a progress
        // exploit while preserving every watering in the plant's own history.
        guard !events.contains(where: { $0.plantID == plantID && dateKey(from: $0.occurredAt) == day }) else {
            return nil
        }

        let event = CareEvent(id: transactionID, plantID: plantID, occurredAt: occurredAt, kind: .watering)
        events.append(event)
        refreshDerivedState()
        persist()
        return event
    }

    func undo(eventID: String) {
        guard events.contains(where: { $0.id == eventID }) else { return }
        events.removeAll { $0.id == eventID }
        refreshDerivedState()
        persist()
    }

    func markRecapSeen() {
        lastSeenRecapWeek = weekKey(for: nowProvider())
        persist()
    }

    func rhythm(windowDays: Int = 7, now: Date? = nil) -> CareRhythmSummary {
        let end = now ?? nowProvider()
        let active = Set(events.compactMap { date(from: $0.occurredAt) }.map(dayKey))
            .union(legacyActiveDates)
        let today = calendar.startOfDay(for: end)
        let window = (0..<windowDays).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        let activeInWindow = window.filter { active.contains(dayKey($0)) }

        var currentRun = 0
        for day in window {
            if active.contains(dayKey(day)) { currentRun += 1 } else { break }
        }
        return CareRhythmSummary(activeDays: activeInWindow.count, currentRun: currentRun, windowDays: windowDays)
    }

    func recap(now: Date? = nil) -> JungleRecap? {
        guard hasCareHistory else { return nil }
        let end = now ?? nowProvider()
        guard let start = calendar.dateInterval(of: .weekOfYear, for: end)?.start else { return nil }
        let weekEvents = events.filter { event in
            guard let date = date(from: event.occurredAt) else { return false }
            return date >= start && date <= end
        }
        let weekDayKeys = Set((0...7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }.map(dayKey))
        let activeDays = Set(weekEvents.compactMap { date(from: $0.occurredAt) }.map(dayKey))
            .union(legacyActiveDates.intersection(weekDayKeys))
            .count
        let counts = Dictionary(grouping: weekEvents, by: \.plantID)
        let mostCaredPlantID = counts.max { lhs, rhs in lhs.value.count < rhs.value.count }?.key
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return JungleRecap(
            id: weekKey(for: end),
            weekLabel: "Week of \(formatter.string(from: start))",
            activeDays: activeDays,
            actionCount: weekEvents.count,
            plantsCaredFor: counts.count,
            mostCaredPlantID: mostCaredPlantID,
            stage: stage
        )
    }

    func reset() {
        events = []
        legacyActiveDates = []
        lastSeenRecapWeek = nil
        refreshDerivedState()
        defaults.removeObject(forKey: storageKey)
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(PersistedState.self, from: data) else { return }
        events = deduplicated(state.events)
        legacyActiveDates = Set(state.legacyActiveDates)
        lastSeenRecapWeek = state.lastSeenRecapWeek
        refreshDerivedState()
    }

    private func persist() {
        let state = PersistedState(
            events: events,
            legacyActiveDates: Array(legacyActiveDates).sorted(),
            lastSeenRecapWeek: lastSeenRecapWeek
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
        CloudSyncManager.shared.push()
    }

    private func refreshDerivedState() {
        lifetimeActionCount = events.count
        stage = .from(actionCount: lifetimeActionCount)
    }

    private func deduplicated(_ input: [CareEvent]) -> [CareEvent] {
        var seen = Set<String>()
        return input.filter { event in
            guard seen.insert(event.id).inserted else { return false }
            return true
        }.sorted { $0.occurredAt < $1.occurredAt }
    }

    private func date(from timestamp: String) -> Date? {
        DataLoader.isoFormatter.date(from: timestamp)
    }

    private func dateKey(from timestamp: String) -> String? {
        guard let date = date(from: timestamp) else { return nil }
        return dayKey(date)
    }

    private func dayKey(_ date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private func weekKey(for date: Date) -> String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(components.yearForWeekOfYear ?? 0)-W\(components.weekOfYear ?? 0)"
    }
}
