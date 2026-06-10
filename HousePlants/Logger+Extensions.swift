import Foundation
import os

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.houseplants.ai"
    
    /// Logger for SwiftData and other persistence/storage related operations.
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    
    /// Logger for local/system notification scheduling and status.
    static let notifications = Logger(subsystem: subsystem, category: "notifications")

    /// Logger for loading and decoding the bundled plant catalog.
    static let data = Logger(subsystem: subsystem, category: "data")

    /// Logger for Watch connectivity sessions.
    static let connectivity = Logger(subsystem: subsystem, category: "connectivity")

    /// Logger for WeatherKit requests.
    static let weather = Logger(subsystem: subsystem, category: "weather")

    /// Logger for CoreLocation and location search.
    static let location = Logger(subsystem: subsystem, category: "location")

    /// Logger for PDF/image rendering.
    static let rendering = Logger(subsystem: subsystem, category: "rendering")
}
