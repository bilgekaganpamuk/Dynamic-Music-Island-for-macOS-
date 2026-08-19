import Foundation
import AppKit
import SwiftUI

/// Media provider for Web Media playing in Safari (YouTube Music, YouTube, Web Spotify, Amazon Music)
public final class SafariMediaProvider: Sendable {
    public static let shared = SafariMediaProvider()

    public init() {}

    /// Checks if Safari is currently running
    public var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").isEmpty
    }

    /// Starts observing Safari media changes
    public func startObserving(onTrackUpdate: @escaping @MainActor @Sendable (MediaTrack) -> Void) {
        // Initial fetch if Safari is running
        if isRunning {
            Task { @MainActor in
                if let track = await self.fetchCurrentTrack() {
                    onTrackUpdate(track)
                }
            }
        }
    }

    /// Fetches the currently playing track from Safari (YouTube Music, YouTube, Web Media)
    public func fetchCurrentTrack() async -> MediaTrack? {
        guard isRunning else { return nil }

        return await Task.detached(priority: .userInitiated) { () -> MediaTrack? in
            let scriptSource = """
            tell application "Safari"
                if (count of windows) is 0 then return ""
                repeat with w in windows
                    repeat with t in tabs of w
                        set tabURL to URL of t
                        if tabURL contains "music.youtube.com" or tabURL contains "youtube.com/watch" or tabURL contains "open.spotify.com" or tabURL contains "music.amazon.com" then
                            set tabTitle to name of t
                            set isPlaying to "false"
                            try
                                set isPaused to do JavaScript "document.querySelector('video, audio') ? document.querySelector('video, audio').paused : true" in t
                                if isPaused is false or isPaused is "false" then
                                    set isPlaying to "true"
                                end if
                            on error
                                set isPlaying to "true"
                            end try
                            return tabURL & "|||" & tabTitle & "|||" & isPlaying
                        end if
                    end repeat
                end repeat
                return ""
            end tell
            """

            guard let script = NSAppleScript(source: scriptSource) else { return nil }
            var errorInfo: NSDictionary?
            let descriptor = script.executeAndReturnError(&errorInfo)
            let resultString = descriptor.stringValue ?? ""

            guard !resultString.isEmpty else { return nil }

            let parts = resultString.components(separatedBy: "|||")
            guard parts.count >= 2 else { return nil }

            let url = parts[0]
            let rawTitle = parts[1]
            let isPlaying = parts.count > 2 ? (parts[2].lowercased() == "true") : true

            return SafariMediaProvider.parseSafariTitle(rawTitle: rawTitle, url: url, isPlaying: isPlaying)
        }.value
    }

    /// Parses web page titles from Safari tabs into clean MediaTrack value objects
    public static func parseSafariTitle(rawTitle: String, url: String, isPlaying: Bool) -> MediaTrack {
        var cleanTitle = rawTitle
        var artist = "Safari Web Media"
        var playerType: PlayerType = .webMedia

        if url.contains("music.youtube.com") {
            playerType = .youtubeMusic
            artist = "YouTube Music"
            // Title format: "Song Name - Artist - YouTube Music" or "Song Name • Artist"
            var sanitized = rawTitle
                .replacingOccurrences(of: " - YouTube Music", with: "")
                .replacingOccurrences(of: " - YouTube", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if sanitized.contains(" • ") {
                let segments = sanitized.components(separatedBy: " • ")
                if segments.count >= 2 {
                    cleanTitle = segments[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    artist = segments[1].trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    cleanTitle = sanitized
                }
            } else if sanitized.contains(" - ") {
                let segments = sanitized.components(separatedBy: " - ")
                if segments.count >= 2 {
                    cleanTitle = segments[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    artist = segments[1].trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    cleanTitle = sanitized
                }
            } else {
                cleanTitle = sanitized
            }
        } else if url.contains("youtube.com/watch") {
            playerType = .youtubeMusic
            artist = "YouTube"
            var sanitized = rawTitle
                .replacingOccurrences(of: " - YouTube", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if sanitized.contains(" - ") {
                let segments = sanitized.components(separatedBy: " - ")
                if segments.count >= 2 {
                    artist = segments[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    cleanTitle = segments[1].trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    cleanTitle = sanitized
                }
            } else {
                cleanTitle = sanitized
            }
        } else if url.contains("open.spotify.com") {
            playerType = .spotify
            artist = "Spotify Web"
            cleanTitle = rawTitle
                .replacingOccurrences(of: " | Spotify", with: "")
                .replacingOccurrences(of: " - song and lyrics by ", with: " - ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if url.contains("music.amazon.com") {
            playerType = .webMedia
            artist = "Amazon Music"
            cleanTitle = rawTitle
                .replacingOccurrences(of: " on Amazon Music", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let accentColor = playerType.brandColor

        return MediaTrack(
            title: cleanTitle.isEmpty ? "Web Media" : cleanTitle,
            artist: artist,
            album: playerType.rawValue,
            duration: 0.0,
            elapsedTime: 0.0,
            isPlaying: isPlaying,
            playerType: playerType,
            artwork: nil,
            accentColor: accentColor,
            secondaryColor: accentColor.opacity(0.7)
        )
    }

    // MARK: - Playback Controls
    public func playPause() {
        executeSafariScript("""
        tell application "Safari"
            repeat with w in windows
                repeat with t in tabs of w
                    set tabURL to URL of t
                    if tabURL contains "music.youtube.com" or tabURL contains "youtube.com/watch" or tabURL contains "open.spotify.com" or tabURL contains "music.amazon.com" then
                        try
                            do JavaScript "var playBtn = document.querySelector('#play-pause-button, .play-pause-button, .ytp-play-button, button[data-testid=\\\"control-button-playpause\\\"]'); if (playBtn) { playBtn.click(); } else { var v = document.querySelector('video, audio'); if (v) { v.paused ? v.play() : v.pause(); } }" in t
                        end try
                        return
                    end if
                end repeat
            end repeat
        end tell
        """)
    }

    public func nextTrack() {
        executeSafariScript("""
        tell application "Safari"
            repeat with w in windows
                repeat with t in tabs of w
                    set tabURL to URL of t
                    if tabURL contains "music.youtube.com" or tabURL contains "youtube.com/watch" or tabURL contains "open.spotify.com" then
                        try
                            do JavaScript "var nextBtn = document.querySelector('.next-button, #next-button, .ytp-next-button, button[data-testid=\\\"control-button-skip-forward\\\"]'); if (nextBtn) { nextBtn.click(); }" in t
                        end try
                        return
                    end if
                end repeat
            end repeat
        end tell
        """)
    }

    public func previousTrack() {
        executeSafariScript("""
        tell application "Safari"
            repeat with w in windows
                repeat with t in tabs of w
                    set tabURL to URL of t
                    if tabURL contains "music.youtube.com" or tabURL contains "youtube.com/watch" or tabURL contains "open.spotify.com" then
                        try
                            do JavaScript "var prevBtn = document.querySelector('.previous-button, #previous-button, .ytp-prev-button, button[data-testid=\\\"control-button-skip-back\\\"]'); if (prevBtn) { prevBtn.click(); }" in t
                        end try
                        return
                    end if
                end repeat
            end repeat
        end tell
        """)
    }

    private func executeSafariScript(_ source: String) {
        Task.detached(priority: .userInitiated) {
            guard let script = NSAppleScript(source: source) else { return }
            var errorInfo: NSDictionary?
            script.executeAndReturnError(&errorInfo)
        }
    }
}
