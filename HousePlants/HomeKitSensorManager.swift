import Foundation
import Combine
#if canImport(HomeKit)
import HomeKit
#endif

/// Discovers HomeKit accessories that expose temperature or humidity (proxy for soil moisture
/// for most consumer plant sensors) and surfaces the latest reading per accessory.
///
/// Per-plant binding lives in UserDefaults under "homekit.binding.{plantId}" → accessory UUID.
@MainActor
final class HomeKitSensorManager: NSObject, ObservableObject {
    static let shared = HomeKitSensorManager()

    struct SensorAccessory: Identifiable, Equatable {
        let id: UUID
        let name: String
        var temperatureC: Double?
        var humidityPct: Double?
    }

    @Published private(set) var accessories: [SensorAccessory] = []
    @Published private(set) var isAuthorized = false

    #if canImport(HomeKit)
    private var homeManager: HMHomeManager?
    #endif

    func start() {
        #if canImport(HomeKit)
        guard homeManager == nil else { return }
        let mgr = HMHomeManager()
        mgr.delegate = self
        self.homeManager = mgr
        #endif
    }

    func binding(for plantId: String) -> UUID? {
        guard let s = UserDefaults.standard.string(forKey: "homekit.binding.\(plantId)") else { return nil }
        return UUID(uuidString: s)
    }

    func bind(plantId: String, accessoryId: UUID?) {
        let key = "homekit.binding.\(plantId)"
        if let accessoryId {
            UserDefaults.standard.set(accessoryId.uuidString, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func reading(for plantId: String) -> SensorAccessory? {
        guard let id = binding(for: plantId) else { return nil }
        return accessories.first(where: { $0.id == id })
    }

    #if canImport(HomeKit)
    private func refreshAccessories() {
        guard let mgr = homeManager else { return }
        var collected: [SensorAccessory] = []

        for home in mgr.homes {
            for accessory in home.accessories {
                let temp = accessory.services
                    .flatMap { $0.characteristics }
                    .first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature })
                let humidity = accessory.services
                    .flatMap { $0.characteristics }
                    .first(where: { $0.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity })

                guard temp != nil || humidity != nil else { continue }

                var entry = SensorAccessory(id: accessory.uniqueIdentifier, name: accessory.name)

                let group = DispatchGroup()
                if let t = temp {
                    group.enter()
                    t.readValue { _ in
                        if let v = t.value as? Double { entry.temperatureC = v }
                        group.leave()
                    }
                }
                if let h = humidity {
                    group.enter()
                    h.readValue { _ in
                        if let v = h.value as? Double { entry.humidityPct = v }
                        group.leave()
                    }
                }
                _ = group.wait(timeout: .now() + 2)
                collected.append(entry)
            }
        }

        self.accessories = collected
    }
    #endif
}

#if canImport(HomeKit)
extension HomeKitSensorManager: HMHomeManagerDelegate {
    nonisolated func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        Task { @MainActor in
            self.isAuthorized = !manager.homes.isEmpty
            self.refreshAccessories()
        }
    }
}
#endif
