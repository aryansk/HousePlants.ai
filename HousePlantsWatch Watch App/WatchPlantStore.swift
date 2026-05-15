import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

struct WatchPlant: Identifiable, Equatable {
    let id: String
    let nickname: String
    let daysUntilWatering: Int
    let healthScore: Int
}

@MainActor
final class WatchPlantStore: NSObject, ObservableObject {
    @Published var plants: [WatchPlant] = []
    @Published var streak: Int = 0
    @Published var lastUpdated: Date?

    #if canImport(WatchConnectivity)
    private var session: WCSession { WCSession.default }
    #endif

    override init() {
        super.init()
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            apply(context: session.receivedApplicationContext)
        }
        #endif
    }

    func water(_ plantId: String) {
        #if canImport(WatchConnectivity)
        guard session.isReachable else {
            // Fallback: enqueue via userInfo (queued until reachable)
            session.transferUserInfo(["action": "water", "plantId": plantId])
            return
        }
        session.sendMessage(["action": "water", "plantId": plantId], replyHandler: nil) { error in
            print("water msg error: \(error)")
        }
        #endif
    }

    func mistAll() {
        #if canImport(WatchConnectivity)
        if session.isReachable {
            session.sendMessage(["action": "mistAll"], replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(["action": "mistAll"])
        }
        #endif
    }

    private func apply(context: [String: Any]) {
        guard let jungle = context["jungle"] as? [[String: Any]] else { return }
        let mapped: [WatchPlant] = jungle.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let nickname = dict["nickname"] as? String else { return nil }
            let days = dict["daysUntilWatering"] as? Int ?? Int.max
            let score = dict["healthScore"] as? Int ?? 80
            return WatchPlant(id: id, nickname: nickname, daysUntilWatering: days, healthScore: score)
        }
        self.plants = mapped.sorted { $0.daysUntilWatering < $1.daysUntilWatering }
        self.streak = context["streak"] as? Int ?? 0
        if let ts = context["updatedAt"] as? TimeInterval {
            self.lastUpdated = Date(timeIntervalSince1970: ts)
        }
    }
}

#if canImport(WatchConnectivity)
extension WatchPlantStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            self.apply(context: applicationContext)
        }
    }
}
#endif
