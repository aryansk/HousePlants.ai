import Foundation
import UIKit
import ImageIO
import MobileCoreServices
import UniformTypeIdentifiers
import os

struct JournalEntry: Identifiable, Equatable {
    let id: String   // filename (ISO date)
    let url: URL
    let date: Date
}

final class PlantJournalStore {
    static let shared = PlantJournalStore()

    private let fm = FileManager.default
    private let filenameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH-mm-ss'Z'"
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var rootURL: URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("PlantJournal", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func plantDir(for plantId: String) -> URL {
        let safe = plantId.replacingOccurrences(of: "/", with: "_")
        let dir = rootURL.appendingPathComponent(safe, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // MARK: - Public API

    @discardableResult
    func addPhoto(_ image: UIImage, for plantId: String, date: Date = Date()) -> JournalEntry? {
        let resized = resize(image, maxDimension: 1600)
        guard let data = resized.jpegData(compressionQuality: 0.7) else { return nil }

        let filename = sanitizedFilename(for: date) + ".jpg"
        let url = plantDir(for: plantId).appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return JournalEntry(id: filename, url: url, date: date)
        } catch {
            Logger.persistence.error("Journal write failed: \(error)")
            return nil
        }
    }

    func photos(for plantId: String) -> [JournalEntry] {
        let dir = plantDir(for: plantId)
        guard let urls = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return []
        }
        return urls
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .compactMap { url -> JournalEntry? in
                let stem = url.deletingPathExtension().lastPathComponent
                let date = parseFilenameDate(stem) ??
                    ((try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date())
                return JournalEntry(id: url.lastPathComponent, url: url, date: date)
            }
            .sorted { $0.date > $1.date }
    }

    func deletePhoto(_ entry: JournalEntry) {
        try? fm.removeItem(at: entry.url)
    }

    func generateGIF(for plantId: String, frameDelay: Double = 0.5) async -> URL? {
        let entries = photos(for: plantId).sorted { $0.date < $1.date }
        guard entries.count >= 2 else { return nil }

        let tmp = fm.temporaryDirectory.appendingPathComponent("growth-\(plantId)-\(Int(Date().timeIntervalSince1970)).gif")

        guard let dest = CGImageDestinationCreateWithURL(tmp as CFURL, UTType.gif.identifier as CFString, entries.count, nil) else {
            return nil
        }

        let fileProps: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        CGImageDestinationSetProperties(dest, fileProps as CFDictionary)

        let frameProps: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: frameDelay
            ]
        ]

        for entry in entries {
            guard let src = CGImageSourceCreateWithURL(entry.url as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(src, 0, nil) else { continue }
            CGImageDestinationAddImage(dest, cgImage, frameProps as CFDictionary)
        }

        guard CGImageDestinationFinalize(dest) else { return nil }
        return tmp
    }

    // MARK: - Helpers

    private func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let w = image.size.width
        let h = image.size.height
        let longest = max(w, h)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let target = CGSize(width: w * scale, height: h * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private func sanitizedFilename(for date: Date) -> String {
        filenameFormatter.string(from: date)
    }

    private func parseFilenameDate(_ stem: String) -> Date? {
        filenameFormatter.date(from: stem)
    }
}
