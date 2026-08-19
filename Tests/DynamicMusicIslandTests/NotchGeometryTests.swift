import XCTest
@testable import DynamicMusicIsland

final class NotchGeometryTests: XCTestCase {
    func testFallbackGeometryMetrics() {
        let fallback = DisplayGeometry.fallback
        XCTAssertTrue(fallback.hasHardwareNotch)
        XCTAssertEqual(fallback.notchWidth, 210.0)
        XCTAssertEqual(fallback.notchHeight, 32.0)
    }

    func testNotchlessDisplayGeometry() {
        let notchless = DisplayGeometry(
            screenFrame: NSRect(x: 0, y: 0, width: 3840, height: 2160),
            visibleFrame: NSRect(x: 0, y: 0, width: 3840, height: 2130),
            hasHardwareNotch: false,
            notchWidth: 0.0,
            notchHeight: 0.0,
            topInset: 0.0
        )

        XCTAssertFalse(notchless.hasHardwareNotch)
        XCTAssertEqual(notchless.notchWidth, 0.0)

        let compactFrame = NotchGeometryDetector.shared.compactNotchFrame(geometry: notchless)
        XCTAssertGreaterThan(compactFrame.width, 0)
        XCTAssertEqual(compactFrame.height, Constants.Layout.floatingPillHeight)
    }

    func testExpandedCardDimensions() {
        let geometry = DisplayGeometry.fallback
        let cardFrame = NotchGeometryDetector.shared.expandedCardFrame(geometry: geometry)

        XCTAssertEqual(cardFrame.width, Constants.Layout.expandedWidth)
        XCTAssertGreaterThanOrEqual(cardFrame.height, 220.0)
    }
}
