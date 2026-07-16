import Foundation

/// Build-time constants that are unlocked for Pro subscribers.
/// Keep this file out of public repositories — it will eventually hold real keys.
///
/// SECURITY: anything compiled into the binary can be extracted from a decrypted IPA with
/// `strings`, and a single shared key means one abuser can exhaust the quota for every user.
/// Before shipping a real key, move identification behind a small server-side proxy that
/// holds the key and validates the App Store receipt; treat this constant as a stopgap.
/// The key is resolved per-request in PlantNetService and is never written to disk.
enum ProConfig {
    /// Bundled Pl@ntNet API key for Pro subscribers. No user setup needed.
    static let plantNetAPIKey = "YOUR_PLANTNET_PRO_API_KEY"
}
