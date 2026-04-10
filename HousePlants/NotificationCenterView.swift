import SwiftUI

struct NotificationCenterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataLoader: DataLoader
    
    var body: some View {
        NavigationView {
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
                    GeometryReader { geometry in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(dataLoader.notifications) { notification in
                                    NotificationRow(notification: notification) {
                                        dataLoader.markAsRead(id: notification.id)
                                    }
                                }
                            }
                            .frame(width: geometry.size.width)
                            .padding(20)
                        }
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
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !dataLoader.notifications.isEmpty {
                        Button("Clear All") {
                            withAnimation {
                                dataLoader.clearNotifications()
                            }
                        }
                        .foregroundStyle(.red)
                        .font(.subheadline)
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    let onMarkRead: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.isRead ? Color.claudeSecondaryText.opacity(0.1) : Color.claudeAccent.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: notification.type.rawValue)
                    .foregroundStyle(notification.isRead ? Color.claudeSecondaryText : Color.claudeAccent)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.claudeSerif(size: 18, weight: .bold))
                        .foregroundStyle(notification.isRead ? Color.claudeSecondaryText : Color.claudePrimaryText)
                    
                    Spacer()
                    
                    Text(formatDate(notification.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color.claudeSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(notification.isRead ? Color.clear : Color.claudeAccent.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            onMarkRead()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationCenterView()
        .environmentObject(DataLoader())
}
