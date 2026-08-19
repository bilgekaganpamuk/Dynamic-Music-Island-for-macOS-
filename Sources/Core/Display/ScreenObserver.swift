import Foundation
import AppKit
import Observation

/// Observes macOS multi-monitor configuration changes, display hotplug events, and resolution shifts.
@Observable
@MainActor
public final class ScreenObserver {
    public static let shared = ScreenObserver()

    public var currentGeometry: DisplayGeometry = .fallback

    public init() {
        updateCurrentScreen()
        setupNotification()
    }

    private func setupNotification() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateCurrentScreen()
            }
        }
    }

    public func updateCurrentScreen() {
        if let mainScreen = NSScreen.main {
            self.currentGeometry = DisplayGeometry(screen: mainScreen)
        }
    }
}
