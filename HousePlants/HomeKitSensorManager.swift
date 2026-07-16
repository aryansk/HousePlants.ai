import Foundation
import Combine
import UserNotifications
import os
#if canImport(HomeKit)
import HomeKit
#endif

/// Discovers HomeKit accessories that expose temperature or humidity (proxy for soil moisture
/// for most consumer plant sensors) and surfaces the latest reading per accessory.
///
/// Per-plant binding lives in UserDefaults under "homekit.binding.{plantId}" → accessory UUID.
/// Pro feature: startThresholdMonitoring() fires local notifications when readings are out of range.
@MainActor
final class HomeKitSensorManager: NSObject, ObservableObject {
    static let shared = HomeKitSensorManager()

    struct SensorAccessory: Identifiable, Equatable {
        let id: UUID
        let name: String
        var temperatureC: Double?
        var humidityPct: Double?
    }

    /// Threshold data passed in from the DataLoader for each bound plant.
    struct PlantThreshold {
        let plantId: String
        let plantName: String
        /// Fire a notification if humidity drops at or below this value.
        let minHumidityPct: Double
        /// Fire a notification if temperature rises at or above this value (°C).
        let maxTempC: Double
    }

    @Published private(set) var accessories: [SensorAccessory] = []
    @Published private(set) var isAuthorized = false

    #if canImport(HomeKit)
    private var homeManager: HMHomeManager?
    #endif

    private var monitoringCancellable: AnyCancellable?
    private var thresholds: [PlantThreshold] = []

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

    // MARK: - Pro: Threshold monitoring

    /// Starts a Combine timer that reads all bound sensors every 15 minutes and fires a local
    /// notification when a reading breaches a plant's threshold. Silently ignored if not Pro.
    func startThresholdMonitoring(thresholds: [PlantThreshold]) {
        guard ProManager.shared.isPro else { return }
        self.thresholds = thresholds
        monitoringCancellable?.cancel()

        // Creating HMHomeManager triggers the system HomeKit permission prompt, so don't
        // touch HomeKit until the user has actually bound a sensor to a plant (done in
        // PlantInsightsView, which calls start() itself).
        guard thresholds.contains(where: { binding(for: $0.plantId) != nil }) else { return }
        start()

        // Fire once immediately, then every 15 minutes.
        checkThresholds()
        monitoringCancellable = Timer.publish(every: 900, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.checkThresholds() }
    }

    func stopThresholdMonitoring() {
        monitoringCancellable?.cancel()
        monitoringCancellable = nil
    }

    private func checkThresholds() {
        guard ProManager.shared.isPro else { return }
        #if canImport(HomeKit)
        refreshAccessories()
        #endif
        let center = UNUserNotificationCenter.current()

        for threshold in thresholds {
            guard let sensor = reading(for: threshold.plantId) else { continue }

            if let humidity = sensor.humidityPct, humidity <= threshold.minHumidityPct {
                fireAlert(
                    id: "homekit-humidity-\(threshold.plantId)",
                    title: "\(threshold.plantName) needs humidity",
                    body: String(format: "Humidity is %.0f%% — below the %.0f%% minimum. Consider misting or a pebble tray.",
                                 humidity, threshold.minHumidityPct),
                    center: center
                )
            }

            if let temp = sensor.temperatureC, temp >= threshold.maxTempC {
                fireAlert(
                    id: "homekit-temp-\(threshold.plantId)",
                    title: "\(threshold.plantName) is too warm",
                    body: String(format: "Temperature is %.1f°C — above the %.1f°C limit. Move it away from heat sources.",
                                 temp, threshold.maxTempC),
                    center: center
                )
            }
        }
    }

    private func fireAlert(id: String, title: String, body: String, center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        // Immediate trigger (nil = deliver right away once)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        center.add(request) { error in
            if let error {
                Logger.notifications.error("HomeKit alert failed [\(id, privacy: .public)]: \(error.localizedDescription, privacy: .public)")
            }
        }
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
