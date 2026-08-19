import AppKit
import SwiftUI

/// Custom NSPanel subclass for overlay display.
public final class IslandPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .statusBar
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return false
    }
}

/// Window controller managing the fixed canvas overlay panel.
@MainActor
public final class IslandWindowController: Sendable {
    public static let shared = IslandWindowController()

    public private(set) var panel: IslandPanel?
    private var hostingView: IslandHostingView<IslandRootView>?

    public static let canvasWidth: CGFloat = 560.0
    public static let canvasHeight: CGFloat = 620.0

    public init() {}

    /// Calculates the top-center canvas frame for the primary screen
    private func canvasFrame(for screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let x = screenFrame.minX + (screenFrame.width - Self.canvasWidth) / 2.0
        let y = screenFrame.maxY - Self.canvasHeight
        return NSRect(x: x, y: y, width: Self.canvasWidth, height: Self.canvasHeight)
    }

    /// Creates and positions the Island canvas overlay on the primary screen.
    public func showIsland() {
        guard panel == nil else {
            panel?.orderFrontRegardless()
            return
        }

        guard let screen = NSScreen.main else { return }
        let initialFrame = canvasFrame(for: screen)

        let newPanel = IslandPanel(contentRect: initialFrame)
        let rootView = IslandRootView()
        let hosting = IslandHostingView(rootView: rootView)
        hosting.frame = NSRect(origin: .zero, size: initialFrame.size)
        hosting.autoresizingMask = [.width, .height]

        newPanel.contentView = hosting
        newPanel.orderFrontRegardless()

        self.panel = newPanel
        self.hostingView = hosting
    }

    /// Re-centers the canvas if screen metrics or resolution changes.
    public func updatePosition() {
        guard let panel = panel, let screen = NSScreen.main else { return }
        let targetFrame = canvasFrame(for: screen)
        panel.setFrame(targetFrame, display: true, animate: false)
    }

    public func hideIsland() {
        panel?.orderOut(nil)
    }
}
