import Foundation

/// Mirrors a curated set of UserDefaults keys to NSUbiquitousKeyValueStore so a user's plant
/// state follows them across devices on the same iCloud account.
///
/// Scope: encoded MyPlant array, favorites, streak. ~1MB hard cap on KVS — journal photos
/// stay on-device.
///
/// TODO: CloudKit — this entire class is a *transitional* sync layer. Once JungleStore is
/// switched to `ModelConfiguration(cloudKitDatabase: .private(...))`, SwiftData handles
/// cross-device sync natively and CloudSyncManager can be deleted. Until then, this layer
/// ensures parity for users on the current build. See JungleStore.swift for the Phase 2 plan.
final class CloudSyncManager {
    static let shared = CloudSyncManager()

    private let kvs = NSUbiquitousKeyValueStore.default
    private let keys = [
        "myJungleExtendedData",
        "user_favorites",
        "current_streak",
        "last_streak_date",
        "streak_history",
        "userPreferences"
    ]

    private var observer: NSObjectProtocol?
    private var localObserver: NSObjectProtocol?
    private var isApplyingRemote = false

    func start() {
        // Pull latest from cloud on launch
        kvs.synchronize()
        applyRemoteToLocal(reason: "launch")

        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvs,
            queue: .main
        ) { [weak self] note in
            self?.handleRemoteChange(note)
        }

        localObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak self] _ in
            self?.applyLocalToRemote()
        }
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        if let localObserver { NotificationCenter.default.removeObserver(localObserver) }
    }

    private func handleRemoteChange(_ note: Notification) {
        // Only adopt remote when reason indicates a real change from another device.
        let reasonRaw = note.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int ?? -1
        let reasons: Set<Int> = [
            NSUbiquitousKeyValueStoreServerChange,
            NSUbiquitousKeyValueStoreInitialSyncChange,
            NSUbiquitousKeyValueStoreAccountChange
        ]
        guard reasons.contains(reasonRaw) else { return }
        applyRemoteToLocal(reason: "remote \(reasonRaw)")
        NotificationCenter.default.post(name: .cloudSyncDidPullRemote, object: nil)
    }

    private func applyRemoteToLocal(reason: String) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        let ud = UserDefaults.standard
        for key in keys {
            if let value = kvs.object(forKey: key) {
                ud.set(value, forKey: key)
            }
        }
    }

    private func applyLocalToRemote() {
        guard !isApplyingRemote else { return }
        let ud = UserDefaults.standard
        for key in keys {
            if let value = ud.object(forKey: key) {
                kvs.set(value, forKey: key)
            }
        }
        kvs.synchronize()
    }
}

extension Notification.Name {
    static let cloudSyncDidPullRemote = Notification.Name("CloudSyncDidPullRemote")
}
