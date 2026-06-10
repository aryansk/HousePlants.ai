import Foundation

// MARK: - Notifications Management
extension DataLoader {

    func loadNotifications() {
        if let savedData = UserDefaults.standard.data(forKey: "appNotifications"),
           let savedNotifications = try? JSONDecoder().decode([AppNotification].self, from: savedData) {
            self.notifications = savedNotifications
        } else {
            // Initial mock notifications
            self.notifications = [
                AppNotification(id: UUID(), title: "Watering Reminder", message: "Your Monstera Deliciosa is feeling a bit thirsty!", date: Date().addingTimeInterval(-3600), isRead: false, type: .watering),
                AppNotification(id: UUID(), title: "Fertilizer Time", message: "It's time to feed your Pothos for healthy growth.", date: Date().addingTimeInterval(-86400), isRead: true, type: .fertilizer),
                AppNotification(id: UUID(), title: "Tip: Sunlight Guide", message: "Rotate your plants every week for even light distribution.", date: Date().addingTimeInterval(-172800), isRead: false, type: .tip),
                AppNotification(id: UUID(), title: "Sun seeker update", message: "We've added new light thresholds for better plant tracking", date: Date().addingTimeInterval(-259200), isRead: true, type: .info)
            ]
            saveNotifications()
        }
    }

    func addNotification(title: String, message: String, type: AppNotification.NotificationType) {
        let newNotification = AppNotification(id: UUID(), title: title, message: message, date: Date(), isRead: false, type: type)
        notifications.insert(newNotification, at: 0)
        saveNotifications()
    }

    func markAsRead(id: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            saveNotifications()
        }
    }

    func markAllAsRead() {
        for index in 0..<notifications.count {
            notifications[index].isRead = true
        }
        saveNotifications()
    }

    func clearNotifications() {
        notifications.removeAll()
        saveNotifications()
    }

    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: "appNotifications")
        }
    }
}
