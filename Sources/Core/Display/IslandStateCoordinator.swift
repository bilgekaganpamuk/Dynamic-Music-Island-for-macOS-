import Foundation
import AppKit
import SwiftUI
import Observation

/// Coordinates Dynamic Island presentation state, dimensions, and non-blocking window hit-testing.
@Observable
@MainActor
public final class IslandStateCoordinator {
    public static let shared = IslandStateCoordinator()

    public var currentState: IslandState = .compact
    public var isHovering: Bool = false
    public var isModalOpen: Bool = false

    public var activePresentationState: IslandState {
        if currentState == .expanded {
            return .expanded
        }
        if isHovering {
            return .hover
        }
        return currentState
    }

    /// Returns the exact pixel width of the currently visible UI card
    public var currentVisibleWidth: CGFloat {
        switch activePresentationState {
        case .compact:
            let geom = NotchGeometryDetector.shared.currentGeometry()
            return geom.hasHardwareNotch ? (geom.notchWidth + Constants.Layout.compactWingWidth * 2 + 8) : Constants.Layout.floatingPillWidth
        case .hover:
            return Constants.Layout.hoverWidth
        case .expanded:
            if WidgetManager.shared.activeTab == .home && WidgetManager.shared.activeWidget == .browser {
                return WebBookmarksManager.shared.sizeMode.width
            }
            return Constants.Layout.expandedWidth
        case .floatingPill:
            return Constants.Layout.floatingPillWidth
        case .hidden:
            return 0
        }
    }

    /// Returns the exact pixel height of the currently visible UI card
    public var currentVisibleHeight: CGFloat {
        switch activePresentationState {
        case .compact:
            let geom = NotchGeometryDetector.shared.currentGeometry()
            return geom.hasHardwareNotch ? geom.notchHeight : Constants.Layout.floatingPillHeight
        case .hover:
            let geom = NotchGeometryDetector.shared.currentGeometry()
            return geom.hasHardwareNotch ? (geom.notchHeight + Constants.Layout.hoverHeight) : Constants.Layout.hoverHeight
        case .expanded:
            let geom = NotchGeometryDetector.shared.currentGeometry()
            let isBrowser = WidgetManager.shared.activeTab == .home && WidgetManager.shared.activeWidget == .browser
            let baseHeight = isBrowser ? WebBookmarksManager.shared.sizeMode.height : Constants.Layout.expandedHeight
            return geom.hasHardwareNotch ? (geom.notchHeight + baseHeight + 30) : baseHeight
        case .floatingPill:
            return Constants.Layout.floatingPillHeight
        case .hidden:
            return 0
        }
    }

    public func expand() {
        withAnimation(Constants.Animation.liquidSpring) {
            currentState = .expanded
        }
        NetworkSpeedMonitor.shared.resumeMonitoring()
        ClipboardManager.shared.checkForChanges()
    }

    public func collapse() {
        guard !isModalOpen else { return }
        withAnimation(Constants.Animation.liquidSpring) {
            currentState = .compact
            isHovering = false
        }
        NetworkSpeedMonitor.shared.pauseMonitoring()
    }

    public func setHovering(_ hovering: Bool) {
        guard !isModalOpen else { return }
        if currentState != .expanded {
            withAnimation(Constants.Animation.liquidSpring) {
                isHovering = hovering
            }
            if hovering {
                NetworkSpeedMonitor.shared.resumeMonitoring()
                ClipboardManager.shared.checkForChanges()
            } else {
                NetworkSpeedMonitor.shared.pauseMonitoring()
            }
        }
    }
}
