import Foundation
import AppKit
import SwiftUI
import Observation

/// Model representing a copied snippet or URL in the clipboard history
public struct ClipboardItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let timestamp: Date
    public let isURL: Bool

    public var preview: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 60 {
            return String(trimmed.prefix(60)) + "..."
        }
        return trimmed
    }

    public var typeIcon: String {
        if isURL {
            return "link"
        } else if text.contains("\n") || text.contains("{") || text.contains("func") || text.contains("import") {
            return "chevron.left.forwardslash.chevron.right"
        } else {
            return "doc.text.fill"
        }
    }

    public init(text: String) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.isURL = URL(string: text)?.scheme != nil && (text.starts(with: "http://") || text.starts(with: "https://"))
    }
}

/// Central manager that tracks clipboard changes with 0-overhead changeCount detection.
@Observable
@MainActor
public final class ClipboardManager {
    public static let shared = ClipboardManager()

    public var history: [ClipboardItem] = []
    public var searchText: String = ""

    private var lastChangeCount: Int = 0
    private var timer: Timer?

    public init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        // Pre-populate with current pasteboard content if string
        if let currentString = NSPasteboard.general.string(forType: .string), !currentString.isEmpty {
            history.append(ClipboardItem(text: currentString))
        }
        startMonitoring()
    }

    public var filteredHistory: [ClipboardItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return history
        }
        return history.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    /// Starts lightweight timer to observe clipboard changeCount
    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkForChanges()
            }
        }
    }

    public func checkForChanges() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let newString = NSPasteboard.general.string(forType: .string),
              !newString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Avoid exact duplicate at the top
        if let first = history.first, first.text == newString {
            return
        }

        // Remove previous instance if present and insert at top
        history.removeAll(where: { $0.text == newString })
        history.insert(ClipboardItem(text: newString), at: 0)

        // Limit to 30 items
        if history.count > 30 {
            history = Array(history.prefix(30))
        }
    }

    /// Copies a snippet back to system pasteboard
    public func copyToClipboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
        self.lastChangeCount = pasteboard.changeCount

        // Move to top
        history.removeAll(where: { $0.id == item.id })
        history.insert(item, at: 0)
    }

    /// Deletes an item from history
    public func deleteItem(id: UUID) {
        history.removeAll(where: { $0.id == id })
    }

    /// Clears all clipboard history
    public func clearAll() {
        history.removeAll()
    }
}
