import Foundation
import AppKit
import SwiftUI

/// Media provider for Apple Music leveraging system DistributedNotificationCenter and AppleScript automation.
public final class AppleMusicProvider: Sendable {
    public static let shared = AppleMusicProvider()

    private let notificationName = NSNotification.Name(Constants.Notifications.appleMusicPlayerInfo)

    public init() {}

    /// Starts observing Apple Music distributed notifications
    public func startObserving(onTrackUpdate: @escaping @MainActor @Sendable (MediaTrack) -> Void) {
        DistributedNotificationCenter.default().addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let userInfo = notification.userInfo else { return }
            let name = userInfo["Name"] as? String ?? ""
            let artist = userInfo["Artist"] as? String ?? ""
            let album = userInfo["Album"] as? String ?? ""
            let totalTimeMs = userInfo["Total Time"] as? Double ?? 0.0
            let duration = totalTimeMs > 0 ? totalTimeMs / 1000.0 : 0.0
            let position = userInfo["Player Position"] as? Double ?? 0.0
            let playerState = userInfo["Player State"] as? String ?? ""
            let isPlaying = playerState.caseInsensitiveCompare("Playing") == .orderedSame

            Task { @MainActor in
                let artwork = await self.fetchCurrentArtwork()
                let colors = ColorExtractor.shared.extractColors(from: artwork)
                let track = MediaTrack(
                    title: name.isEmpty ? "Unknown Track" : name,
                    artist: artist.isEmpty ? "Apple Music" : artist,
                    album: album,
                    duration: duration,
                    elapsedTime: position,
                    isPlaying: isPlaying,
                    playerType: .appleMusic,
                    artwork: artwork,
                    accentColor: colors.accent,
                    secondaryColor: colors.secondary
                )
                onTrackUpdate(track)
            }
        }
    }

    /// Stops observing notifications
    public func stopObserving() {
        DistributedNotificationCenter.default().removeObserver(self, name: notificationName, object: nil)
    }

    /// Parses notification userInfo into MediaTrack (Utility for testing)
    public func parseTrack(from userInfo: [AnyHashable: Any]) async -> MediaTrack {
        let playerState = userInfo["Player State"] as? String ?? ""
        let isPlaying = playerState.caseInsensitiveCompare("Playing") == .orderedSame
        let name = userInfo["Name"] as? String ?? ""
        let artist = userInfo["Artist"] as? String ?? ""
        let album = userInfo["Album"] as? String ?? ""
        let totalTimeMs = userInfo["Total Time"] as? Double ?? 0.0
        let duration = totalTimeMs > 0 ? totalTimeMs / 1000.0 : 0.0
        let position = userInfo["Player Position"] as? Double ?? 0.0
        let artwork = await fetchCurrentArtwork()
        let colors = ColorExtractor.shared.extractColors(from: artwork)

        return MediaTrack(
            title: name.isEmpty ? "Unknown Track" : name,
            artist: artist.isEmpty ? "Apple Music" : artist,
            album: album,
            duration: duration,
            elapsedTime: position,
            isPlaying: isPlaying,
            playerType: .appleMusic,
            artwork: artwork,
            accentColor: colors.accent,
            secondaryColor: colors.secondary
        )
    }

    // MARK: - Artwork Fetching via AppleScript
    public func fetchCurrentArtwork() async -> NSImage? {
        return await Task.detached(priority: .userInitiated) {
            let scriptSource = """
            tell application "Music"
                if it is running then
                    try
                        tell current track
                            if exists (artwork 1) then
                                return raw data of artwork 1
                            end if
                        end tell
                    end try
                end if
            end tell
            """
            
            var error: NSDictionary?
            if let script = NSAppleScript(source: scriptSource) {
                let output = script.executeAndReturnError(&error)
                if error == nil {
                    let data = output.data
                    if !data.isEmpty {
                        return NSImage(data: data)
                    }
                }
            }
            return nil
        }.value
    }

    /// Checks whether Apple Music is currently running
    public var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: Constants.Players.appleMusicBundleId).isEmpty
    }

    /// Actively queries current Apple Music track metadata
    public func fetchCurrentTrack() async -> MediaTrack? {
        guard isRunning else { return nil }

        let result: String? = await Task.detached(priority: .userInitiated) {
            let scriptSource = """
            tell application "Music"
                if it is running then
                    try
                        set trName to name of current track
                        set trArtist to artist of current track
                        set trAlbum to album of current track
                        set trDur to duration of current track
                        set trPos to player position
                        set trState to player state as string
                        return trName & "|||" & trArtist & "|||" & trAlbum & "|||" & (trDur as string) & "|||" & (trPos as string) & "|||" & trState
                    end try
                end if
            end tell
            """
            var error: NSDictionary?
            if let script = NSAppleScript(source: scriptSource) {
                let output = script.executeAndReturnError(&error)
                if error == nil {
                    return output.stringValue
                }
            }
            return nil
        }.value

        guard let result = result, !result.isEmpty else { return nil }
        let parts = result.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }

        let name = parts[0]
        let artist = parts[1]
        let album = parts[2]
        let duration = Double(parts[3]) ?? 0.0
        let position = Double(parts[4]) ?? 0.0
        let playerState = parts[5]
        let isPlaying = playerState.caseInsensitiveCompare("playing") == .orderedSame

        let artwork = await fetchCurrentArtwork()
        let colors = ColorExtractor.shared.extractColors(from: artwork)

        return MediaTrack(
            title: name.isEmpty ? "Unknown Track" : name,
            artist: artist.isEmpty ? "Apple Music" : artist,
            album: album,
            duration: duration,
            elapsedTime: position,
            isPlaying: isPlaying,
            playerType: .appleMusic,
            artwork: artwork,
            accentColor: colors.accent,
            secondaryColor: colors.secondary
        )
    }

    // MARK: - Playback Control Commands
    public func playPause() {
        executeScript("tell application \"Music\" to playpause")
    }

    public func nextTrack() {
        executeScript("tell application \"Music\" to next track")
    }

    public func previousTrack() {
        executeScript("tell application \"Music\" to previous track")
    }

    public func seek(to position: TimeInterval) {
        executeScript("tell application \"Music\" to set player position to \(position)")
    }

    public func setVolume(_ volume: Int) {
        let clamped = max(0, min(100, volume))
        executeScript("tell application \"Music\" to set sound volume to \(clamped)")
    }

    private func executeScript(_ source: String) {
        Task.detached(priority: .userInitiated) {
            var error: NSDictionary?
            if let script = NSAppleScript(source: source) {
                script.executeAndReturnError(&error)
            }
        }
    }
}
