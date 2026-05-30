import Foundation
import UserNotifications
import os

/// Schedules real system notifications for plant watering reminders, so the in-app notification
/// list is backed by notifications that actually fire. Respects the user's notification settings.
final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()
    private let identifierPrefix = "water-"
    private let hourOfDay = 9

    struct Reminder {
        let plantId: String
        let plantName: String
        let dueDate: Date
    }

    /// Requests authorization the first time only; a no-op once the user has decided.
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

    /// Replaces all pending watering reminders with the supplied set (other notifications untouched).
    func sync(reminders: [Reminder], enabled: Bool, sundaysOnly: Bool, now: Date = Date()) {
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let stale = pending.map(\.identifier).filter { $0.hasPrefix(self.identifierPrefix) }
            self.center.removePendingNotificationRequests(withIdentifiers: stale)

            guard enabled else { return }
            for reminder in reminders {
                guard let fireDate = Self.fireDate(for: reminder.dueDate, sundaysOnly: sundaysOnly,
                                                   hour: self.hourOfDay, now: now) else { continue }
                self.schedule(reminder, at: fireDate)
            }
        }
    }

    func cancelAll() {
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let ids = pending.map(\.identifier).filter { $0.hasPrefix(self.identifierPrefix) }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private func schedule(_ reminder: Reminder, at fireDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to water \(reminder.plantName)"
        content.body = "\(reminder.plantName) is due for watering."
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifierPrefix + reminder.plantId,
                                            content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                Logger.notifications.error("Schedule failed: \(error.localizedDescription, privacy: .public)")
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
