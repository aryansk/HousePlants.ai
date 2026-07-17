import Foundation
import os

extension Logger {
    /// Logger for Pl@ntNet identification requests.
    static let identification = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.houseplants.ai", category: "identification")
}

// MARK: - Pl@ntNet API Models

struct PlantNetResponse: Codable {
    let results: [PlantNetResult]
    let remainingIdentificationRequests: Int?
}

struct PlantNetResult: Codable, Identifiable {
    var id: String { species.scientificNameWithoutAuthor }
    let score: Double
    let species: PlantNetSpecies
}

struct PlantNetSpecies: Codable {
    let scientificNameWithoutAuthor: String
    let scientificNameAuthorship: String?
    let genus: PlantNetTaxon?
    let family: PlantNetTaxon?
    let commonNames: [String]?
}

struct PlantNetTaxon: Codable {
    let scientificNameWithoutAuthor: String
}

/// The plant organ visible in the photo. Pl@ntNet uses this hint to improve accuracy.
enum PlantOrgan: String, CaseIterable, Identifiable {
    case auto
    case leaf
    case flower
    case fruit
    case bark

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .auto: return "sparkles"
        case .leaf: return "leaf.fill"
        case .flower: return "camera.macro"
        case .fruit: return "apple.logo"
        case .bark: return "tree.fill"
        }
    }
}

enum PlantNetError: LocalizedError {
    case missingAPIKey
    case invalidImage
    case unauthorized
    case quotaExceeded
    case noMatch
    case server(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add your free Pl@ntNet API key to start identifying plants."
        case .invalidImage:
            return "That image couldn't be processed. Try another photo."
        case .unauthorized:
            return "Your API key was rejected. Double-check it at my.plantnet.org."
        case .quotaExceeded:
            return "Daily identification limit reached. Try again tomorrow."
        case .noMatch:
            return "No plant species could be identified in this photo. Try a closer shot of a leaf or flower."
        case .server(let code):
            return "The identification service returned an error (\(code)). Try again later."
        }
    }
}

// MARK: - Service

/// Identifies plants from photos using the Pl@ntNet API (https://my.plantnet.org).
/// The free tier allows 500 identifications per day with a personal API key.
final class PlantNetService {
    static let shared = PlantNetService()

    private static let keychainKey = "plantnet_api_key"
    private static let legacyDefaultsKey = "plantnet_api_key"
    private let endpoint = "https://my.plantnet.org/v2/identify/all"

    init() {
        migrateLegacyKeyIfNeeded()
    }

    /// The user's personal Pl@ntNet key, stored in the Keychain. The bundled Pro key is
    /// resolved per-request in `identify` and is intentionally never persisted here.
    var apiKey: String? {
        get {
            let key = KeychainStore.string(for: Self.keychainKey)
            return (key?.isEmpty == false) ? key : nil
        }
        set {
            KeychainStore.setString(newValue, for: Self.keychainKey)
        }
    }

    /// Earlier builds kept the key in plaintext UserDefaults — move it to the Keychain.
    /// Builds that injected the bundled Pro key into defaults get it scrubbed instead.
    private func migrateLegacyKeyIfNeeded() {
        guard let legacy = UserDefaults.standard.string(forKey: Self.legacyDefaultsKey) else { return }
        if !legacy.isEmpty, legacy != ProConfig.plantNetAPIKey, apiKey == nil {
            KeychainStore.setString(legacy, for: Self.keychainKey)
        }
        UserDefaults.standard.removeObject(forKey: Self.legacyDefaultsKey)
    }

    func identify(imageData: Data, organ: PlantOrgan) async throws -> [PlantNetResult] {
        let proKey = ProManager.shared.isPro ? ProConfig.plantNetAPIKey : nil
        guard let apiKey = apiKey ?? proKey else { throw PlantNetError.missingAPIKey }

        guard var components = URLComponents(string: endpoint) else {
            throw PlantNetError.server(0)
        }
        components.queryItems = [
            URLQueryItem(name: "api-key", value: apiKey),
            URLQueryItem(name: "lang", value: "en"),
            URLQueryItem(name: "nb-results", value: "5")
        ]

        let boundary = "Boundary-\(UUID().uuidString)"
        guard let url = components.url else { throw PlantNetError.server(0) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody(imageData: imageData, organ: organ, boundary: boundary)

        Logger.identification.info("Sending identification request (organ: \(organ.rawValue, privacy: .public))")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw PlantNetError.server(0) }
        switch http.statusCode {
        case 200:
            break
        case 400:
            throw PlantNetError.invalidImage
        case 401:
            throw PlantNetError.unauthorized
        case 404:
            throw PlantNetError.noMatch
        case 429:
            throw PlantNetError.quotaExceeded
        default:
            Logger.identification.error("Identification failed with status \(http.statusCode)")
            throw PlantNetError.server(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(PlantNetResponse.self, from: data)
        Logger.identification.info("Received \(decoded.results.count) candidate species")
        return decoded.results
    }

    private func multipartBody(imageData: Data, organ: PlantOrgan, boundary: String) -> Data {
        var body = Data()
        let newline = "\r\n"

        if organ != .auto {
            body.append("--\(boundary)\(newline)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"organs\"\(newline)\(newline)".data(using: .utf8)!)
            body.append("\(organ.rawValue)\(newline)".data(using: .utf8)!)
        }

        body.append("--\(boundary)\(newline)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"images\"; filename=\"plant.jpg\"\(newline)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(newline)\(newline)".data(using: .utf8)!)
        body.append(imageData)
        body.append("\(newline)--\(boundary)--\(newline)".data(using: .utf8)!)
        return body
    }
}

// MARK: - Catalog Matching

enum PlantCatalogMatcher {
    /// Normalizes a botanical name for comparison: lowercase, strips cultivar
    /// quotes and variety markers, keeps only genus + species epithet.
    static func normalize(_ botanicalName: String) -> String {
        let cleaned = botanicalName
            .lowercased()
            .replacingOccurrences(of: "'", with: " ")
            .replacingOccurrences(of: "\u{2018}", with: " ")
            .replacingOccurrences(of: "\u{2019}", with: " ")
        let words = cleaned
            .split(whereSeparator: { $0.isWhitespace })
            .filter { !["var.", "cv.", "subsp.", "ssp.", "x", "×"].contains($0) }
        return words.prefix(2).joined(separator: " ")
    }

    /// Finds a catalog plant matching the identified scientific name.
    /// Tries an exact genus+species match first, then falls back to genus only.
    static func match(scientificName: String, in catalog: [Plant]) -> Plant? {
        let target = normalize(scientificName)
        guard !target.isEmpty else { return nil }

        if let exact = catalog.first(where: { normalize($0.botanicalName) == target }) {
            return exact
        }

        let genus = target.split(separator: " ").first.map(String.init) ?? target
        return catalog.first { normalize($0.botanicalName).hasPrefix(genus + " ") || normalize($0.botanicalName) == genus }
    }
}
