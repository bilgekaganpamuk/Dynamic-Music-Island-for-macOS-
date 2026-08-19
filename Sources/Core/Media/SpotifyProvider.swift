import Foundation
import AppKit
import SwiftUI

/// Media provider for Spotify desktop client on macOS.
public final class SpotifyProvider: Sendable {
    public static let shared = SpotifyProvider()

    private let notificationName = NSNotification.Name(Constants.Notifications.spotifyPlaybackStateChanged)

    public init() {}

    /// Starts listening to Spotify playback state notifications
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
            let playerState = userInfo["Player State"] as? String ?? ""
            let isPlaying = playerState.caseInsensitiveCompare("Playing") == .orderedSame

            var duration: TimeInterval = 0.0
            if let durVal = userInfo["Duration"] as? Double {
                duration = durVal > 1000 ? durVal / 1000.0 : durVal
            } else if let durInt = userInfo["Duration"] as? Int {
                duration = durInt > 1000 ? Double(durInt) / 1000.0 : Double(durInt)
            }
            let position = userInfo["Playback Position"] as? Double ?? 0.0

            Task { @MainActor in
                let artwork = await self.fetchCurrentArtwork()
                let colors = ColorExtractor.shared.extractColors(from: artwork)
                let track = MediaTrack(
                    title: name.isEmpty ? "Unknown Spotify Track" : name,
                    artist: artist.isEmpty ? "Spotify" : artist,
                    album: album,
                    duration: duration,
                    elapsedTime: position,
                    isPlaying: isPlaying,
                    playerType: .spotify,
                    artwork: artwork,
                    accentColor: colors.accent,
                    secondaryColor: colors.secondary
                )
                onTrackUpdate(track)
            }
        }
    }

    /// Stops listening
    public func stopObserving() {
        DistributedNotificationCenter.default().removeObserver(self, name: notificationName, object: nil)
    }

    /// Parses Spotify notification userInfo
    public func parseTrack(from userInfo: [AnyHashable: Any]) async -> MediaTrack {
        let playerState = userInfo["Player State"] as? String ?? ""
        let isPlaying = playerState.caseInsensitiveCompare("Playing") == .orderedSame

        let name = userInfo["Name"] as? String ?? ""
        let artist = userInfo["Artist"] as? String ?? ""
        let album = userInfo["Album"] as? String ?? ""

        // Duration is typically in milliseconds or seconds depending on Spotify version
        var duration: TimeInterval = 0.0
        if let durVal = userInfo["Duration"] as? Double {
            duration = durVal > 1000 ? durVal / 1000.0 : durVal
        } else if let durInt = userInfo["Duration"] as? Int {
            duration = durInt > 1000 ? Double(durInt) / 1000.0 : Double(durInt)
        }

        let position = userInfo["Playback Position"] as? Double ?? 0.0

        // Fetch artwork URL from Spotify
        let artwork = await fetchCurrentArtwork()
        let colors = ColorExtractor.shared.extractColors(from: artwork)

        return MediaTrack(
            title: name.isEmpty ? "Unknown Spotify Track" : name,
            artist: artist.isEmpty ? "Spotify" : artist,
            album: album,
            duration: duration,
            elapsedTime: position,
            isPlaying: isPlaying,
            playerType: .spotify,
            artwork: artwork,
            accentColor: colors.accent,
            secondaryColor: colors.secondary
        )
    }

    public func fetchCurrentArtwork() async -> NSImage? {
        // Step 1: Query artwork URL
        let urlString: String? = await Task.detached(priority: .userInitiated) {
            let scriptSource = """
            tell application "Spotify"
                if it is running then
                    try
                        return artwork url of current track
                    end try
                end if
            end tell
            """
            var error: NSDictionary?
            if let script = NSAppleScript(source: scriptSource) {
                let output = script.executeAndReturnError(&error)
                if error == nil, let urlStr = output.stringValue, !urlStr.isEmpty {
                    return urlStr
                }
            }
            return nil
        }.value

        guard let urlString = urlString else { return nil }

        // Step 2: Asynchronously load via AsyncImageCache
        return await AsyncImageCache.shared.loadImage(from: urlString)
    }

    /// Checks whether Spotify is currently running
    public var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: Constants.Players.spotifyBundleId).isEmpty
    }

    /// Actively queries current Spotify track metadata (useful on app launch or when Spotify is already open)
    public func fetchCurrentTrack() async -> MediaTrack? {
        guard isRunning else { return nil }

        let result: String? = await Task.detached(priority: .userInitiated) {
            let scriptSource = """
            tell application "Spotify"
                if it is running then
                    try
                        set trName to name of current track
                        set trArtist to artist of current track
                        set trAlbum to album of current track
                        set trDur to (duration of current track) / 1000
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
            title: name.isEmpty ? "Unknown Spotify Track" : name,
            artist: artist.isEmpty ? "Spotify" : artist,
            album: album,
            duration: duration,
            elapsedTime: position,
            isPlaying: isPlaying,
            playerType: .spotify,
            artwork: artwork,
            accentColor: colors.accent,
            secondaryColor: colors.secondary
        )
    }

    // MARK: - Playback Control Commands
    public func playPause() {
        executeScript("tell application \"Spotify\" to playpause")
    }

    public func nextTrack() {
        executeScript("tell application \"Spotify\" to next track")
    }

    public func previousTrack() {
        executeScript("tell application \"Spotify\" to previous track")
    }

    public func seek(to position: TimeInterval) {
        executeScript("tell application \"Spotify\" to set player position to \(position)")
    }

    public func setVolume(_ volume: Int) {
        let clamped = max(0, min(100, volume))
        executeScript("tell application \"Spotify\" to set sound volume to \(clamped)")
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
