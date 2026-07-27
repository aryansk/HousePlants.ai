import SwiftUI

struct NotificationCenterView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(DataLoader.self) var dataLoader

    private var unreadCount: Int {
        dataLoader.notifications.count(where: { !$0.isRead })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.claudeBackground
                    .ignoresSafeArea()
                
                if dataLoader.notifications.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary.opacity(0.3))
                        
                        Text("No notifications yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(unreadCount == 0 ? "You're all caught up" : "(unreadCount) unread")
                                        .font(.claudeSerif(size: 24, weight: .bold))
                                        .foregroundStyle(Color.claudePrimaryText)
                                    Text("Plant care updates and helpful tips")
                                        .font(.claudeSans(size: 14))
                                        .foregroundStyle(Color.claudeSecondaryText)
                                }
                                Spacer()
                                if unreadCount > 0 {
                                    Button("Read all") { dataLoader.markAllAsRead() }
                                        .font(.claudeSans(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.claudeAccent)
                                        .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 10)

                            ForEach(dataLoader.notifications) { notification in
                                NotificationRow(notification: notification) {
                                    dataLoader.markAsRead(id: notification.id)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.claudeAccent)
                    .accessibilityLabel("Close notifications")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !dataLoader.notifications.isEmpty {
                        Button("Clear All") {
                            withMotion(Motion.snappy) {
                                dataLoader.clearNotifications()
                            }
                        }
                        .foregroundStyle(.red)
                        .font(.subheadline)
                        .accessibilityHint("Permanently removes all notifications")
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    let onMarkRead: () -> Void

    private var iconColor: Color {
        switch notification.type {
        case .watering: .blue
        case .fertilizer, .repotting: .green
        case .alert: .red
        case .tip: .orange
        case .info: .claudeSecondaryText
        }
    }
    
    var body: some View {
        Button(action: onMarkRead) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(notification.isRead ? 0.10 : 0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: notification.type.rawValue)
                        .foregroundStyle(notification.isRead ? Color.claudeSecondaryText : iconColor)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(notification.title)
                            .font(.claudeSerif(size: 17, weight: .bold))
                            .foregroundStyle(notification.isRead ? Color.claudeSecondaryText : Color.claudePrimaryText)
                            .lineLimit(2)
                            .layoutPriority(1)
                        Spacer()
                        if !notification.isRead {
                            Circle()
                                .fill(Color.claudeAccent)
                                .frame(width: 7, height: 7)
                                .accessibilityHidden(true)
                        }
                    }
                    Text(notification.message)
                        .font(.claudeSans(size: 14))
                        .foregroundStyle(Color.claudeSecondaryText)
                        .lineLimit(2)
                    Text(formatDate(notification.date))
                        .font(.caption)
                        .foregroundStyle(Color.claudeSecondaryText.opacity(0.85))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(14)
        .background(notification.isRead ? Color.claudeSecondaryBackground.opacity(0.58) : Color.claudeSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(notification.isRead ? Color.clear : iconColor.opacity(0.22), lineWidth: 1)
        )
        .accessibilityLabel(notification.title)
        .accessibilityValue(notification.isRead ? "Read" : "Unread")
        .accessibilityHint("Marks this notification as read")
    }
    
    private func formatDate(_ date: Date) -> String {
        Self.relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}

#Preview {
    NotificationCenterView()
        .environment(DataLoader())
}
