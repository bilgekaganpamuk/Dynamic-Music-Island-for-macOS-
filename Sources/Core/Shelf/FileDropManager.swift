import Foundation
import AppKit
import SwiftUI
import Observation
import UniformTypeIdentifiers

/// Model representing a file or folder placed into the Notch Tray.
public struct DroppedFileItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let icon: NSImage
    public let fileSizeString: String
    public let dateAdded: Date

    public init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
        self.dateAdded = Date()

        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            self.fileSizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        } else {
            self.fileSizeString = "Item"
        }
    }

    public static func == (lhs: DroppedFileItem, rhs: DroppedFileItem) -> Bool {
        lhs.id == rhs.id && lhs.url == rhs.url
    }
}

@MainActor
public final class AirDropPickerDelegate: NSObject, NSSharingServicePickerDelegate {
    public func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        IslandStateCoordinator.shared.isModalOpen = false
        NSApp.setActivationPolicy(.accessory)
    }
}

/// Central manager for the Notch Drag & Drop Tray / Temporary File Shelf & AirDrop station.
@Observable
@MainActor
public final class FileDropManager {
    public static let shared = FileDropManager()

    public var items: [DroppedFileItem] = []
    public var isTargetedForDrop: Bool = false
    public var isAirDropTargeted: Bool = false
    public var showAirDropFeedback: Bool = false

    private var activePickerDelegate: AirDropPickerDelegate?

    public init() {}

    /// Instant synchronous extraction from drag pasteboard
    public static func getDroppedURLs(from providers: [NSItemProvider]) -> [URL] {
        let pb = NSPasteboard(name: .drag)
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            return urls
        }
        return []
    }

    /// Extracts file URLs from drag item providers across all possible macOS pasteboard UTI formats.
    public static func extractURLs(from providers: [NSItemProvider]) async -> [URL] {
        let syncURLs = getDroppedURLs(from: providers)
        if !syncURLs.isEmpty { return syncURLs }

        var resultURLs: [URL] = []
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                if let url = await withCheckedContinuation({ (continuation: CheckedContinuation<URL?, Never>) in
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        continuation.resume(returning: url)
                    }
                }) {
                    resultURLs.append(url)
                    continue
                }
            }
            // Fallback for file types
            let candidateTypeIDs = [UTType.fileURL.identifier, "public.file-url", "public.item"]
            for typeId in candidateTypeIDs {
                if provider.hasItemConformingToTypeIdentifier(typeId) {
                    if let url = await withCheckedContinuation({ (continuation: CheckedContinuation<URL?, Never>) in
                        provider.loadItem(forTypeIdentifier: typeId, options: nil) { item, _ in
                            if let url = item as? URL { continuation.resume(returning: url) }
                            else if let nsUrl = item as? NSURL { continuation.resume(returning: nsUrl as URL) }
                            else { continuation.resume(returning: nil) }
                        }
                    }) {
                        resultURLs.append(url)
                        break
                    }
                }
            }
        }
        return resultURLs
    }

    public func addFiles(from urls: [URL]) {
        for url in urls {
            if !items.contains(where: { $0.url.path == url.path }) {
                items.append(DroppedFileItem(url: url))
            }
        }
    }

    public func removeItem(id: UUID) {
        items.removeAll(where: { $0.id == id })
    }

    public func clearAll() {
        items.removeAll()
    }

    public func pickFiles() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        IslandStateCoordinator.shared.isModalOpen = true

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.prompt = L10n.add
        panel.level = .modalPanel
        panel.orderFrontRegardless()

        panel.begin { [weak self] response in
            Task { @MainActor [weak self] in
                IslandStateCoordinator.shared.isModalOpen = false
                NSApp.setActivationPolicy(.accessory)
                if response == .OK {
                    self?.addFiles(from: panel.urls)
                }
            }
        }
    }

    public func pickFilesAndAirDrop() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        IslandStateCoordinator.shared.isModalOpen = true

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.prompt = L10n.sendViaAirDrop
        panel.level = .modalPanel
        panel.orderFrontRegardless()

        panel.begin { [weak self] response in
            Task { @MainActor [weak self] in
                IslandStateCoordinator.shared.isModalOpen = false
                NSApp.setActivationPolicy(.accessory)
                if response == .OK, !panel.urls.isEmpty {
                    self?.triggerAirDrop(for: panel.urls)
                }
            }
        }
    }

    public func triggerAirDrop(for urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        // 1. Elevate app to regular so sharing picker works perfectly
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        IslandStateCoordinator.shared.isModalOpen = true

        withAnimation { self.showAirDropFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { self.showAirDropFeedback = false }
        }

        // 2. Prepare sharing sheet
        guard let targetWindow = NSApp.windows.first(where: { $0.isVisible }),
              let contentView = targetWindow.contentView else { return }

        let itemsToShare = urls.map { $0 as NSURL }
        let picker = NSSharingServicePicker(items: itemsToShare)
        
        let delegate = AirDropPickerDelegate()
        picker.delegate = delegate
        self.activePickerDelegate = delegate
        
        // 3. Anchor perfectly to the AirDrop button area (top right)
        let anchorRect = NSRect(
            x: contentView.bounds.maxX - 60,
            y: contentView.bounds.maxY - 130,
            width: 1,
            height: 1
        )
        
        picker.show(relativeTo: anchorRect, of: contentView, preferredEdge: .minY)
    }

    public func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
