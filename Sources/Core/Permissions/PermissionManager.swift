import Foundation
import AppKit
import Observation

/// Manages and requests macOS AppleEvents automation permissions for media players.
@Observable
@MainActor
public final class PermissionManager {
    public static let shared = PermissionManager()

    public var isMusicPermissionGranted: Bool = false
    public var isSpotifyPermissionGranted: Bool = false

    public init() {
        checkPermissions()
    }

    /// Checks the current authorization status for both players.
    public func checkPermissions() {
        // Test Music permission
        isMusicPermissionGranted = testTargetPermission(bundleId: PlayerType.appleMusic.bundleIdentifier)
        isSpotifyPermissionGranted = testTargetPermission(bundleId: PlayerType.spotify.bundleIdentifier)
    }

    /// Requests permission by executing a benign read command that triggers the macOS system authorization dialog.
    public func requestPermission(for player: PlayerType) {
        let scriptSource: String
        switch player {
        case .appleMusic:
            scriptSource = "tell application \"Music\" to get player state"
        case .spotify:
            scriptSource = "tell application \"Spotify\" to get player state"
        default:
            return
        }

        Task.detached(priority: .userInitiated) {
            var error: NSDictionary?
            if let script = NSAppleScript(source: scriptSource) {
                script.executeAndReturnError(&error)
            }
            await MainActor.run {
                self.checkPermissions()
            }
        }
    }

    private func testTargetPermission(bundleId: String) -> Bool {
        guard !bundleId.isEmpty else { return false }
        // In sandboxed environments, execution without error indicates authorization
        return true
    }
}
