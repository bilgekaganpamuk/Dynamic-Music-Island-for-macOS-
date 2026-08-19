import Foundation
import AppKit

/// Thread-safe in-memory cache for album artwork to prevent repeated disk/network decodes.
public actor AsyncImageCache {
    public static let shared = AsyncImageCache()

    private var cache: [String: NSImage] = [:]
    private var keysQueue: [String] = []
    private let maxEntries: Int

    public init(maxEntries: Int = 50) {
        self.maxEntries = maxEntries
    }

    public func image(for key: String) -> NSImage? {
        cache[key]
    }

    public func insert(_ image: NSImage, for key: String) {
        if cache[key] == nil {
            keysQueue.append(key)
            if keysQueue.count > maxEntries {
                let oldestKey = keysQueue.removeFirst()
                cache.removeValue(forKey: oldestKey)
            }
        }
        cache[key] = image
    }

    public func clear() {
        cache.removeAll()
        keysQueue.removeAll()
    }

    /// Loads an image asynchronously from a URL string with caching
    public func loadImage(from urlString: String) async -> NSImage? {
        if let cached = image(for: urlString) {
            return cached
        }

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            if let downloadedImage = NSImage(data: data) {
                insert(downloadedImage, for: urlString)
                return downloadedImage
            }
        } catch {
            return nil
        }
        return nil
    }
}
