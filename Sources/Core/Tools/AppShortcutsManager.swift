import Foundation
import AppKit
import SwiftUI
import Observation

/// Model representing an editable app shortcut dockable in the notch.
public struct AppShortcutItem: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var bundleId: String
    public var appPath: String
    public var iconSystemName: String
    public var colorHex: String

    public init(name: String, bundleId: String, appPath: String = "", iconSystemName: String = "app.fill", colorHex: String = "#0A84FF") {
        self.id = bundleId.isEmpty ? UUID().uuidString : bundleId
        self.name = name
        self.bundleId = bundleId
        self.appPath = appPath
        self.iconSystemName = iconSystemName
        self.colorHex = colorHex
    }

    public var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    public var customIcon: NSImage? {
        if !appPath.isEmpty && FileManager.default.fileExists(atPath: appPath) {
            return NSWorkspace.shared.icon(forFile: appPath)
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }
}

extension Color {
    public init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

/// Central manager for user-customizable app shortcuts in the notch
@Observable
@MainActor
public final class AppShortcutsManager {
    public static let shared = AppShortcutsManager()

    private static let storageKey = "DynamicIsland_CustomAppShortcuts_v2"

    public var shortcuts: [AppShortcutItem] = []
    public var isEditing: Bool = false

    public init() {
        loadShortcuts()
    }

    public func loadShortcuts() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([AppShortcutItem].self, from: data),
           !decoded.isEmpty {
            self.shortcuts = decoded
        } else {
            // Default pre-loaded apps with high-contrast, polished icons
            self.shortcuts = [
                AppShortcutItem(name: "Finder", bundleId: "com.apple.finder", iconSystemName: "folder.fill", colorHex: "#007AFF"),
                AppShortcutItem(name: "Safari", bundleId: "com.apple.Safari", iconSystemName: "safari.fill", colorHex: "#00C7BE"),
                AppShortcutItem(name: "Terminal", bundleId: "com.apple.Terminal", iconSystemName: "terminal.fill", colorHex: "#30D158"),
                AppShortcutItem(name: "Notes", bundleId: "com.apple.Notes", iconSystemName: "note.text", colorHex: "#FFD60A"),
                AppShortcutItem(name: "Music", bundleId: "com.apple.Music", iconSystemName: "music.note", colorHex: "#FF2D55"),
                AppShortcutItem(name: "Messages", bundleId: "com.apple.MobileSMS", iconSystemName: "message.fill", colorHex: "#34C759")
            ]
            saveShortcuts()
        }
    }

    public func saveShortcuts() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    public func addApp(from url: URL) {
        let appName = url.deletingPathExtension().lastPathComponent
        let bundle = Bundle(url: url)
        let bundleId = bundle?.bundleIdentifier ?? ""

        // Avoid exact duplicates
        if !shortcuts.contains(where: { $0.appPath == url.path || (!bundleId.isEmpty && $0.bundleId == bundleId) }) {
            let newItem = AppShortcutItem(
                name: appName,
                bundleId: bundleId,
                appPath: url.path,
                iconSystemName: "app.fill",
                colorHex: "#5E5CE6"
            )
            shortcuts.append(newItem)
            saveShortcuts()
        }
    }

    public func removeApp(id: String) {
        shortcuts.removeAll(where: { $0.id == id })
        saveShortcuts()
    }

    public func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        loadShortcuts()
    }

    public func pickApp() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        IslandStateCoordinator.shared.isModalOpen = true

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.prompt = L10n.addToNotch
        panel.level = .modalPanel
        panel.orderFrontRegardless()

        panel.begin { [weak self] response in
            Task { @MainActor [weak self] in
                IslandStateCoordinator.shared.isModalOpen = false
                NSApp.setActivationPolicy(.accessory)
                if response == .OK, let url = panel.url {
                    self?.addApp(from: url)
                }
            }
        }
    }

    /// Discovers common installed applications in /Applications for quick 1-click addition
    public func discoveredApplications() -> [AppShortcutItem] {
        let appDir = URL(fileURLWithPath: "/Applications")
        guard let files = try? FileManager.default.contentsOfDirectory(at: appDir, includingPropertiesForKeys: nil) else {
            return []
        }

        var results: [AppShortcutItem] = []
        for file in files where file.pathExtension == "app" {
            let appName = file.deletingPathExtension().lastPathComponent
            let bundle = Bundle(url: file)
            let bundleId = bundle?.bundleIdentifier ?? ""

            // Skip if already in shortcuts
            if !shortcuts.contains(where: { $0.appPath == file.path || (!bundleId.isEmpty && $0.bundleId == bundleId) }) {
                results.append(AppShortcutItem(
                    name: appName,
                    bundleId: bundleId,
                    appPath: file.path,
                    iconSystemName: "app.fill",
                    colorHex: "#0A84FF"
                ))
            }
        }
        return results.sorted(by: { $0.name < $1.name })
    }

    public func launch(app: AppShortcutItem) {
        if !app.appPath.isEmpty && FileManager.default.fileExists(atPath: app.appPath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: app.appPath))
            return
        }
        if !app.bundleId.isEmpty, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }
}
