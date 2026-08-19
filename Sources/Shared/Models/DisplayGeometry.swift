import Foundation
import AppKit

/// Encapsulates screen geometry, notch detection, and dimension offsets.
public struct DisplayGeometry: Equatable, Sendable {
    public let screenFrame: NSRect
    public let visibleFrame: NSRect
    public let hasHardwareNotch: Bool
    public let notchWidth: CGFloat
    public let notchHeight: CGFloat
    public let topInset: CGFloat

    public init(screen: NSScreen) {
        self.screenFrame = screen.frame
        self.visibleFrame = screen.visibleFrame

        if #available(macOS 12.0, *) {
            let safeArea = screen.safeAreaInsets
            self.topInset = safeArea.top
            
            // Check for hardware notch via auxiliary area or safe area top inset
            if let topLeft = screen.auxiliaryTopLeftArea,
               let topRight = screen.auxiliaryTopRightArea,
               topLeft.width > 0 && topRight.width > 0 {
                self.hasHardwareNotch = true
                let calculatedWidth = topRight.minX > topLeft.maxX ? (topRight.minX - topLeft.maxX) : (screen.frame.width - (topLeft.width + topRight.width))
                self.notchWidth = max(160.0, min(240.0, calculatedWidth))
                self.notchHeight = safeArea.top > 0 ? safeArea.top : 34.0
            } else if safeArea.top > 24.0 {
                // MacBook Pro 14" / 16" and MacBook Air M2/M3 notch detection
                self.hasHardwareNotch = true
                // 14" MBP / Air is ~180pt, 16" MBP is ~210pt
                self.notchWidth = screen.frame.width > 1600 ? 210.0 : 185.0
                self.notchHeight = safeArea.top
            } else {
                self.hasHardwareNotch = false
                self.notchWidth = 0.0
                self.notchHeight = 0.0
            }
        } else {
            self.topInset = 0.0
            self.hasHardwareNotch = false
            self.notchWidth = 0.0
            self.notchHeight = 0.0
        }
    }

    /// Default fallback geometry for notchless displays or previews
    public static let fallback = DisplayGeometry(
        screenFrame: NSRect(x: 0, y: 0, width: 1728, height: 1117),
        visibleFrame: NSRect(x: 0, y: 0, width: 1728, height: 1080),
        hasHardwareNotch: true,
        notchWidth: 210.0,
        notchHeight: 32.0,
        topInset: 32.0
    )

    public init(
        screenFrame: NSRect,
        visibleFrame: NSRect,
        hasHardwareNotch: Bool,
        notchWidth: CGFloat,
        notchHeight: CGFloat,
        topInset: CGFloat
    ) {
        self.screenFrame = screenFrame
        self.visibleFrame = visibleFrame
        self.hasHardwareNotch = hasHardwareNotch
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        self.topInset = topInset
    }
}
