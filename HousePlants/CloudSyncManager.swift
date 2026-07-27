import Foundation

/// Mirrors a curated set of UserDefaults keys to NSUbiquitousKeyValueStore so a user's plant
/// state follows them across devices on the same iCloud account.
///
/// Scope: encoded MyPlant array, favorites, streak, and care experience. ~1MB hard cap on KVS — journal photos
/// stay on-device.
///
/// TODO: CloudKit — this entire class is a *transitional* sync layer. Once JungleStore is
/// switched to `ModelConfiguration(cloudKitDatabase: .private(...))`, SwiftData handles
/// cross-device sync natively and CloudSyncManager can be deleted. Until then, this layer
/// ensures parity for users on the current build. See JungleStore.swift for the Phase 2 plan.
final class CloudSyncManager {
    static let shared = CloudSyncManager()

    // Simulator builds are not signed with a real iCloud container identifier. Constructing
    // the default KVS store there produces a client-fatal entitlement diagnostic and delays
    // first launch, so cloud mirroring remains device-only while all local persistence works.
    private lazy var kvs: NSUbiquitousKeyValueStore? = {
        #if targetEnvironment(simulator)
        return nil
        #else
        return NSUbiquitousKeyValueStore.default
        #endif
    }()
    private let keys = [
        "myJungleExtendedData",
        "user_favorites",
        "current_streak",
        "last_streak_date",
        "streak_history",
        "userPreferences",
        "care_experience_v1"
    ]

    private var observer: NSObjectProtocol?
    private var isApplyingRemote = false

    func start() {
        guard let kvs else { return }
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
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    /// Uploads the synced keys to iCloud. Called explicitly by DataLoader after each save —
    /// observing UserDefaults.didChangeNotification re-uploaded everything on every defaults
    /// write app-wide (weather cache, HomeKit bindings, …), which this replaces.
    func push() {
        guard kvs != nil else { return }
        applyLocalToRemote()
    }

    /// Removes personal values from the iCloud mirror so a destructive local reset is not
    /// silently undone by the next cross-device pull.
    func clearMirroredData() {
        guard let kvs else { return }
        for key in keys {
            kvs.removeObject(forKey: key)
        }
        kvs.synchronize()
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
        guard let kvs else { return }
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
        guard !isApplyingRemote, let kvs else { return }
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
