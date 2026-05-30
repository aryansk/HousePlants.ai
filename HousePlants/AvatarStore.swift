import UIKit
import os

/// Persists the user's profile photo as a single JPEG file in the Documents directory.
///
/// Previously the avatar was base64-encoded into UserDefaults, which is loaded entirely into
/// memory at launch — a multi-hundred-KB string there wastes RAM every session. Storing it as a
/// file (the same pattern `PlantJournalStore` uses for plant photos) keeps UserDefaults small.
final class AvatarStore {
    static let shared = AvatarStore()

    /// Stable marker stored in the profile/UserDefaults so the model knows a custom avatar exists.
    static let fileName = "avatar.jpg"

    private let fm = FileManager.default

    private var fileURL: URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(AvatarStore.fileName)
    }

    var exists: Bool { fm.fileExists(atPath: fileURL.path) }

    /// Re-encodes the image as JPEG and writes it to disk. Returns true on success.
    @discardableResult
    func save(_ data: Data) -> Bool {
        let encoded = UIImage(data: data)?.jpegData(compressionQuality: 0.8) ?? data
        do {
            try encoded.write(to: fileURL, options: .atomic)
            return true
        } catch {
            Logger.persistence.error("Avatar write failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func load() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func delete() {
        try? fm.removeItem(at: fileURL)
    }
}
