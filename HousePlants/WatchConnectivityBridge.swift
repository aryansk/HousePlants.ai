import Foundation
import os
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// iPhone-side WatchConnectivity bridge. Pushes the current jungle (a thinned summary, not
/// the full MyPlant records — Watch UI only needs name + watering status) to the paired Watch
/// via `updateApplicationContext`, and receives `waterPlant` / `mistAllPlants` requests back.
final class WatchConnectivityBridge: NSObject {
    static let shared = WatchConnectivityBridge()

    #if canImport(WatchConnectivity)
    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }
    #endif

    func start() {
        #if canImport(WatchConnectivity)
        guard let session, session.delegate == nil else { return }
        session.delegate = self
        session.activate()
        #endif
    }

    func pushJungleSnapshot() {
        #if canImport(WatchConnectivity)
        guard let session = session, session.activationState == .activated else { return }

        let loader = DataLoader.shared
        guard let profile = loader.userProfile else { return }

        let summaries: [[String: Any]] = profile.myJungle.map { mp in
            let days = loader.daysUntilWatering(myPlant: mp) ?? Int.max
            return [
                "id": mp.plantId,
                "nickname": mp.nickname,
                "daysUntilWatering": days,
                "lastWatered": mp.lastWatered,
                "healthScore": mp.healthScore ?? 80
            ]
        }

        let payload: [String: Any] = [
            "jungle": summaries,
            "streak": profile.currentStreak ?? 0,
            "updatedAt": Date().timeIntervalSince1970
        ]

        do {
            try session.updateApplicationContext(payload)
        } catch {
            Logger.connectivity.error("WCSession context error: \(error)")
        }
        #endif
    }
}

#if canImport(WatchConnectivity)
extension WatchConnectivityBridge: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        pushJungleSnapshot()
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            let loader = DataLoader.shared
            if let action = message["action"] as? String {
                switch action {
                case "water":
                    if let id = message["plantId"] as? String {
                        loader.waterPlant(plantId: id)
                        self.pushJungleSnapshot()
                        replyHandler(["ok": true])
                        return
                    }
                case "mistAll":
                    loader.mistAllPlants()
                    self.pushJungleSnapshot()
                    replyHandler(["ok": true])
                    return
                default: break
                }
            }
            replyHandler(["ok": false])
        }
    }
}
#endif
