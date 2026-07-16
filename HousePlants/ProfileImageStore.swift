import Foundation
import UIKit
import os

/// Stores the user's profile photo as a JPEG in Application Support instead of a base64
/// string inside UserDefaults (which loads the whole blob into the defaults plist on every
/// launch). `UserProfile.profileImage` now only holds a cache-busting timestamp token.
final class ProfileImageStore {
    static let shared = ProfileImageStore()

    private let fm = FileManager.default

    private var fileURL: URL {
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("profile-photo.jpg")
    }

    func save(_ data: Data) {
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            Logger.persistence.error("Profile photo write failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func loadImage() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func delete() {
        try? fm.removeItem(at: fileURL)
    }
}
