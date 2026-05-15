import Foundation

struct AppNotification: Identifiable, Codable {
    let id: UUID
    let title: String
    let message: String
    let date: Date
    var isRead: Bool
    let type: NotificationType
    
    enum NotificationType: String, Codable {
        case watering = "drop.fill"
        case fertilizer = "leaf.fill"
        case alert = "exclamationmark.triangle.fill"
        case tip = "lightbulb.fill"
        case info = "info.circle.fill"
        case repotting = "arrow.up.left.and.arrow.down.right.circle.fill"
    }
}
