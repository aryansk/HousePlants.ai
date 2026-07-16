import Foundation
import UserNotifications
import os

/// Schedules real system notifications for plant care reminders so the in-app notification
/// list is backed by notifications that actually fire. Respects the user's notification settings.
///
/// Free tier: watering reminders only.
/// Pro tier: also fertilizer, misting, repotting, and bloom countdown reminders.
final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()
    private let hourOfDay = 9

    // MARK: - Identifier prefixes (one prefix per reminder type)

    private let waterPrefix    = "water-"
    private let fertilizerPrefix = "fertilizer-"
    private let mistPrefix     = "mist-"
    private let repotPrefix    = "repot-"
    private let bloomPrefix    = "bloom-"

    // MARK: - Public data types

    struct Reminder {
        let plantId: String
        let plantName: String
        let dueDate: Date
    }

    struct FertilizerReminder {
        let plantId: String
        let plantName: String
        /// Defaults to 30 days from lastFertilized, or 30 days from now if never fertilized.
        let dueDate: Date
    }

    struct MistingReminder {
        let plantId: String
        let plantName: String
        /// Defaults to 3 days from lastMisted, or tomorrow if never misted.
        let dueDate: Date
    }

    struct RepottingReminder {
        let plantId: String
        let plantName: String
        let dueDate: Date
    }

    struct BloomReminder {
        let plantId: String
        let plantName: String
        /// Date of the first day of the next bloom window.
        let bloomStartDate: Date
        let bloomNotes: String
    }

    // MARK: - Authorization

    func requestAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self?.center.requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
                if let error {
                    Logger.notifications.error("Authorization failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    // MARK: - Watering (free tier)

    /// Replaces all pending watering reminders with the supplied set (other notifications untouched).
    func sync(reminders: [Reminder], enabled: Bool, sundaysOnly: Bool, now: Date = Date()) {
        // The first time something is actually worth notifying about is when we ask permission.
        if enabled && !reminders.isEmpty {
            requestAuthorization()
        }
        replace(prefix: waterPrefix, enabled: enabled) { [weak self] in
            guard let self else { return }
            for reminder in reminders {
                guard let fireDate = Self.fireDate(for: reminder.dueDate, sundaysOnly: sundaysOnly,
                                                   hour: self.hourOfDay, now: now) else { continue }
                self.schedule(
                    id: self.waterPrefix + reminder.plantId,
                    title: "Time to water \(reminder.plantName)",
                    body: "\(reminder.plantName) is due for watering.",
                    at: fireDate
                )
            }
        }
    }

    // MARK: - Fertilizer (Pro)

    func syncFertilizerReminders(_ reminders: [FertilizerReminder], enabled: Bool, now: Date = Date()) {
        guard ProManager.shared.isPro else { return }
        replace(prefix: fertilizerPrefix, enabled: enabled) { [weak self] in
            guard let self else { return }
            for reminder in reminders {
                guard let fireDate = Self.fireDate(for: reminder.dueDate, sundaysOnly: false,
                                                   hour: self.hourOfDay, now: now) else { continue }
                self.schedule(
                    id: self.fertilizerPrefix + reminder.plantId,
                    title: "Fertilize \(reminder.plantName)",
                    body: "\(reminder.plantName) is due for fertilizing — feed it today.",
                    at: fireDate
                )
            }
        }
    }

    // MARK: - Misting (Pro)

    func syncMistingReminders(_ reminders: [MistingReminder], enabled: Bool, now: Date = Date()) {
        guard ProManager.shared.isPro else { return }
        replace(prefix: mistPrefix, enabled: enabled) { [weak self] in
            guard let self else { return }
            for reminder in reminders {
                guard let fireDate = Self.fireDate(for: reminder.dueDate, sundaysOnly: false,
                                                   hour: self.hourOfDay, now: now) else { continue }
                self.schedule(
                    id: self.mistPrefix + reminder.plantId,
                    title: "Mist \(reminder.plantName)",
                    body: "\(reminder.plantName) would love a gentle misting today.",
                    at: fireDate
                )
            }
        }
    }

    // MARK: - Repotting (Pro)

    func syncRepottingReminders(_ reminders: [RepottingReminder], enabled: Bool, now: Date = Date()) {
        guard ProManager.shared.isPro else { return }
        replace(prefix: repotPrefix, enabled: enabled) { [weak self] in
            guard let self else { return }
            for reminder in reminders {
                guard let fireDate = Self.fireDate(for: reminder.dueDate, sundaysOnly: false,
                                                   hour: self.hourOfDay, now: now) else { continue }
                self.schedule(
                    id: self.repotPrefix + reminder.plantId,
                    title: "Repot \(reminder.plantName)",
                    body: "Roots are getting cozy — time to move \(reminder.plantName) to a bigger pot.",
                    at: fireDate
                )
            }
        }
    }

    // MARK: - Bloom countdown (Pro)

    func syncBloomReminders(_ reminders: [BloomReminder], enabled: Bool, now: Date = Date()) {
        guard ProManager.shared.isPro else { return }
        replace(prefix: bloomPrefix, enabled: enabled) { [weak self] in
            guard let self else { return }
            for reminder in reminders {
                // Fire 14 days before bloom start so the user can prepare.
                guard let advanceDate = Calendar.current.date(byAdding: .day, value: -14, to: reminder.bloomStartDate),
                      let fireDate = Self.fireDate(for: advanceDate, sundaysOnly: false,
                                                   hour: self.hourOfDay, now: now) else { continue }
                self.schedule(
                    id: self.bloomPrefix + reminder.plantId,
                    title: "\(reminder.plantName) blooms in 2 weeks!",
                    body: reminder.bloomNotes,
                    at: fireDate
                )
            }
        }
    }

    // MARK: - Cancel all

    func cancelAll() {
        let allPrefixes = [waterPrefix, fertilizerPrefix, mistPrefix, repotPrefix, bloomPrefix]
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let ids = pending.map(\.identifier).filter { id in
                allPrefixes.contains(where: { id.hasPrefix($0) })
            }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Helpers

    private func replace(prefix: String, enabled: Bool, schedule block: @escaping () -> Void) {
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let stale = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
            self.center.removePendingNotificationRequests(withIdentifiers: stale)
            guard enabled else { return }
            block()
        }
    }

    private func schedule(id: String, title: String, body: String, at fireDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                Logger.notifications.error("Schedule failed [\(id, privacy: .public)]: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Computes when a reminder should fire: `hour` on the due day, or — when `sundaysOnly` is set —
    /// `hour` on the next Sunday on/after the due day. Returns nil if that moment is already in the past.
    /// Exposed (static, pure) for unit testing.
    static func fireDate(for due: Date, sundaysOnly: Bool, hour: Int,
                         now: Date = Date(), calendar: Calendar = .current) -> Date? {
        var day = calendar.startOfDay(for: due)
        if sundaysOnly {
            // weekday 1 == Sunday in the Gregorian calendar.
            while calendar.component(.weekday, from: day) != 1 {
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
        }
        guard let fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
              fire > now else { return nil }
        return fire
    }
}
