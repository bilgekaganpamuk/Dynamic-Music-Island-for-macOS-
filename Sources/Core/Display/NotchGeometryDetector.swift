import Foundation
import AppKit

/// Detects hardware notch presence, auxiliary top areas, and calculates exact pixel offsets for MacBook notch wings.
public final class NotchGeometryDetector: Sendable {
    public static let shared = NotchGeometryDetector()

    public init() {}

    /// Returns the current geometry for the primary screen or active screen.
    public func currentGeometry(for screen: NSScreen? = NSScreen.main) -> DisplayGeometry {
        guard let screen = screen ?? NSScreen.main else {
            return DisplayGeometry.fallback
        }
        return DisplayGeometry(screen: screen)
    }

    /// Calculates the origin and size for the compact notch wings (left wing for artwork, right wing for waveform)
    public func compactNotchFrame(geometry: DisplayGeometry) -> NSRect {
        let screen = geometry.screenFrame
        let notchW = geometry.hasHardwareNotch ? geometry.notchWidth : Constants.Layout.floatingPillWidth
        let totalW = notchW + (Constants.Layout.compactWingWidth * 2) + 16.0
        let h = geometry.hasHardwareNotch ? max(geometry.notchHeight, Constants.Layout.compactHeight) : Constants.Layout.floatingPillHeight

        let x = (screen.width - totalW) / 2.0
        let y = screen.height - h

        return NSRect(x: x, y: y, width: totalW, height: h)
    }

    /// Calculates the origin and size for the hover preview card
    public func hoverPreviewFrame(geometry: DisplayGeometry) -> NSRect {
        let screen = geometry.screenFrame
        let cardW = max(geometry.notchWidth + 140.0, Constants.Layout.hoverWidth)
        let cardH = geometry.hasHardwareNotch ? (geometry.notchHeight + 42.0) : Constants.Layout.hoverHeight

        let x = (screen.width - cardW) / 2.0
        let y = screen.height - cardH

        return NSRect(x: x, y: y, width: cardW, height: cardH)
    }

    /// Calculates the origin and size for the expanded island card
    public func expandedCardFrame(geometry: DisplayGeometry) -> NSRect {
        let screen = geometry.screenFrame
        let cardW = Constants.Layout.expandedWidth
        let cardH = geometry.hasHardwareNotch ? (geometry.notchHeight + 195.0) : Constants.Layout.expandedHeight

        let x = (screen.width - cardW) / 2.0
        let y = screen.height - cardH

        return NSRect(x: x, y: y, width: cardW, height: cardH)
    }

    /// Calculates the origin and size for the floating pill mode
    public func floatingPillFrame(geometry: DisplayGeometry) -> NSRect {
        let screen = geometry.screenFrame
        let pillW = Constants.Layout.floatingPillWidth
        let pillH = Constants.Layout.floatingPillHeight

        let x = (screen.width - pillW) / 2.0
        let y = screen.height - pillH - 10.0 // 10pt offset below top screen edge

        return NSRect(x: x, y: y, width: pillW, height: pillH)
    }
}
