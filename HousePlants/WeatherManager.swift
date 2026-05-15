import Foundation
import Combine
import CoreLocation
#if canImport(WeatherKit)
import WeatherKit
#endif

struct WateringAdjustment: Equatable {
    let daysDelta: Int
    let reason: String
    /// True when the adjustment should apply even to indoor plants (e.g. heatwave warms the home too).
    let appliesIndoors: Bool

    static let none = WateringAdjustment(daysDelta: 0, reason: "", appliesIndoors: false)
}

@MainActor
final class WeatherManager: ObservableObject {
    static let shared = WeatherManager()

    @Published private(set) var lastAdjustment: WateringAdjustment?

    private let cacheKey = "weatherAdjustmentCache"
    private let ttl: TimeInterval = 6 * 60 * 60

    private struct CachedAdjustment: Codable {
        let lat: Double
        let lng: Double
        let daysDelta: Int
        let reason: String
        let appliesIndoors: Bool
        let timestamp: Date
    }

    func adjustment(for coordinate: CLLocationCoordinate2D) async -> WateringAdjustment {
        if let cached = readCache(for: coordinate) {
            self.lastAdjustment = cached
            return cached
        }
        let fresh = await fetch(for: coordinate)
        writeCache(fresh, for: coordinate)
        self.lastAdjustment = fresh
        return fresh
    }

    private func fetch(for coord: CLLocationCoordinate2D) async -> WateringAdjustment {
        #if canImport(WeatherKit)
        do {
            let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let weather = try await WeatherService.shared.weather(for: location)

            // Rain in next 24h?
            let next24 = weather.hourlyForecast.forecast.prefix(24)
            let totalPrecipMM = next24.reduce(0.0) { $0 + $1.precipitationAmount.converted(to: .millimeters).value }
            if totalPrecipMM >= 5.0 {
                return WateringAdjustment(daysDelta: 2, reason: "Rain expected — skipping ahead", appliesIndoors: false)
            }

            // Heatwave in next 7 days? (max daily high)
            let next7 = weather.dailyForecast.forecast.prefix(7)
            let maxHighC = next7.map { $0.highTemperature.converted(to: .celsius).value }.max() ?? 0
            if maxHighC >= 32 {
                return WateringAdjustment(daysDelta: -1, reason: "Heatwave — watering sooner", appliesIndoors: true)
            }
        } catch {
            print("WeatherKit error: \(error.localizedDescription)")
        }
        #endif
        return .none
    }

    private func readCache(for coord: CLLocationCoordinate2D) -> WateringAdjustment? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedAdjustment.self, from: data) else { return nil }
        guard Date().timeIntervalSince(cached.timestamp) < ttl else { return nil }
        let rounded = round(coord)
        guard cached.lat == rounded.lat, cached.lng == rounded.lng else { return nil }
        return WateringAdjustment(daysDelta: cached.daysDelta, reason: cached.reason, appliesIndoors: cached.appliesIndoors)
    }

    private func writeCache(_ adj: WateringAdjustment, for coord: CLLocationCoordinate2D) {
        let r = round(coord)
        let cached = CachedAdjustment(lat: r.lat, lng: r.lng, daysDelta: adj.daysDelta, reason: adj.reason, appliesIndoors: adj.appliesIndoors, timestamp: Date())
        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func round(_ coord: CLLocationCoordinate2D) -> (lat: Double, lng: Double) {
        (lat: (coord.latitude * 10).rounded() / 10, lng: (coord.longitude * 10).rounded() / 10)
    }
}
