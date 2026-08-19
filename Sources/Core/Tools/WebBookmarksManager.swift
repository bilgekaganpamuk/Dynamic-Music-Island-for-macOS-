import Foundation
import SwiftUI
import Observation

/// Model representing a customizable web bookmark in the notch
public struct WebBookmarkItem: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var url: String
    public var iconName: String

    public init(name: String, url: String, iconName: String = "globe") {
        self.id = UUID().uuidString
        self.name = name
        self.url = url
        self.iconName = iconName
    }
}

public enum BrowserSizeMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case compact = "S"
    case standard = "M"
    case large2X = "2X ⤢"

    public var id: String { rawValue }

    public var width: CGFloat {
        switch self {
        case .compact: return Constants.Layout.browserWidthCompact
        case .standard: return Constants.Layout.browserWidthStandard
        case .large2X: return Constants.Layout.browserWidthLarge2X
        }
    }

    public var height: CGFloat {
        switch self {
        case .compact: return Constants.Layout.browserHeightCompact
        case .standard: return Constants.Layout.browserHeightStandard
        case .large2X: return Constants.Layout.browserHeightLarge2X
        }
    }

    public var webViewHeight: CGFloat {
        switch self {
        case .compact: return 180.0
        case .standard: return 280.0
        case .large2X: return 400.0
        }
    }
}

/// Central manager for user-customizable web bookmarks and browser sizing in the notch
@Observable
@MainActor
public final class WebBookmarksManager {
    public static let shared = WebBookmarksManager()

    private static let storageKey = "DynamicIsland_CustomWebBookmarks_v3"
    private static let sizeKey = "DynamicIsland_BrowserSizeMode"

    public var bookmarks: [WebBookmarkItem] = []
    public var isEditing: Bool = false
    public var sizeMode: BrowserSizeMode = .standard {
        didSet {
            UserDefaults.standard.set(sizeMode.rawValue, forKey: Self.sizeKey)
        }
    }

    public init() {
        loadSettings()
        loadBookmarks()
    }

    private func loadSettings() {
        if let raw = UserDefaults.standard.string(forKey: Self.sizeKey),
           let mode = BrowserSizeMode(rawValue: raw) {
            self.sizeMode = mode
        }
    }

    public func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([WebBookmarkItem].self, from: data),
           !decoded.isEmpty {
            self.bookmarks = decoded
        } else {
            self.bookmarks = [
                WebBookmarkItem(name: "Google", url: "https://google.com", iconName: "magnifyingglass"),
                WebBookmarkItem(name: "Wikipedia", url: "https://wikipedia.org", iconName: "book"),
                WebBookmarkItem(name: "Apple", url: "https://apple.com", iconName: "applelogo"),
                WebBookmarkItem(name: "Google", url: "https://google.com", iconName: "magnifyingglass"),
                WebBookmarkItem(name: "YouTube", url: "https://youtube.com", iconName: "play.rectangle.fill"),
                WebBookmarkItem(name: "GitHub", url: "https://github.com", iconName: "chevron.left.forwardslash.chevron.right"),
                WebBookmarkItem(name: "Notion", url: "https://notion.so", iconName: "doc.text")
            ]
            saveBookmarks()
        }
    }

    public func saveBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    public func addBookmark(name: String, url: String, iconName: String = "globe") {
        var validURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if !validURL.hasPrefix("http://") && !validURL.hasPrefix("https://") {
            validURL = "https://" + validURL
        }
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (URL(string: validURL)?.host ?? "Site") : name

        bookmarks.append(WebBookmarkItem(name: cleanName, url: validURL, iconName: iconName))
        saveBookmarks()
    }

    public func removeBookmark(id: String) {
        bookmarks.removeAll(where: { $0.id == id })
        saveBookmarks()
    }

    public func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        loadBookmarks()
    }
}
