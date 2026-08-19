import AppKit
import SwiftUI

/// Custom NSHostingView that overrides safeAreaInsets, hitTest, and native AppKit Drag & Drop.
public final class IslandHostingView<Content: View>: NSHostingView<Content> {

    public required init(rootView: Content) {
        super.init(rootView: rootView)
        registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            .tiff,
            .png,
            .pdf,
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("public.item")
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var safeAreaInsets: NSEdgeInsets {
        return NSEdgeInsetsZero
    }

    public override var additionalSafeAreaInsets: NSEdgeInsets {
        get { return NSEdgeInsetsZero }
        set { }
    }

    /// Smart Hit-Testing: Only receives mouse clicks/hovers when inside the visible Island card.
    public override func hitTest(_ point: NSPoint) -> NSView? {
        let coordinator = IslandStateCoordinator.shared
        let visibleWidth = coordinator.currentVisibleWidth
        let visibleHeight = coordinator.currentVisibleHeight

        let cardX = (self.frame.width - visibleWidth) / 2.0
        let cardY = self.frame.height - visibleHeight
        let visibleCardRect = NSRect(
            x: cardX,
            y: cardY,
            width: visibleWidth,
            height: visibleHeight
        )

        // Margin around the card for smooth hover
        let expandedHitRect = visibleCardRect.insetBy(dx: -8, dy: -8)

        if expandedHitRect.contains(point) {
            return super.hitTest(point)
        }

        return nil
    }

    // MARK: - Native AppKit Drag & Drop Support
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        Task { @MainActor in
            WidgetManager.shared.switchToTab(.tray)
            IslandStateCoordinator.shared.expand()
        }
        let superOp = super.draggingEntered(sender)
        return superOp.isEmpty ? .copy : superOp
    }

    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let superOp = super.draggingUpdated(sender)
        return superOp.isEmpty ? .copy : superOp
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // Delegate drop completely to SwiftUI child views (Shelf target, AirDrop target, Compact Notch target)
        return super.performDragOperation(sender)
    }
}
