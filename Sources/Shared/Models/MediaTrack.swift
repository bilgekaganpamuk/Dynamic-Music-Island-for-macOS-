import Foundation
import SwiftUI
import AppKit

/// Represents the current playing track with all associated metadata, playback state, and styling colors.
public struct MediaTrack: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public let album: String
    public let duration: TimeInterval
    public var elapsedTime: TimeInterval
    public let isPlaying: Bool
    public let playerType: PlayerType
    public let artwork: NSImage?
    public let accentColor: Color
    public let secondaryColor: Color
    public let timestamp: Date

    public init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        album: String = "",
        duration: TimeInterval = 0,
        elapsedTime: TimeInterval = 0,
        isPlaying: Bool = false,
        playerType: PlayerType = .unknown,
        artwork: NSImage? = nil,
        accentColor: Color = Color.accentColor,
        secondaryColor: Color = Color.secondary,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.artist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        self.album = album.trimmingCharacters(in: .whitespacesAndNewlines)
        self.duration = max(0, duration)
        self.elapsedTime = max(0, min(elapsedTime, duration > 0 ? duration : Double.infinity))
        self.isPlaying = isPlaying
        self.playerType = playerType
        self.artwork = artwork
        self.accentColor = accentColor
        self.secondaryColor = secondaryColor
        self.timestamp = timestamp
    }

    /// Computed progress between 0.0 and 1.0
    public var progress: Double {
        guard duration > 0 else { return 0.0 }
        return min(1.0, max(0.0, elapsedTime / duration))
    }

    /// Formatted elapsed time string (e.g. "03:42")
    public var formattedElapsedTime: String {
        Self.formatTime(elapsedTime)
    }

    /// Formatted total duration string (e.g. "04:15")
    public var formattedDuration: String {
        Self.formatTime(duration)
    }

    /// Formatted remaining time string (e.g. "-00:33")
    public var formattedRemainingTime: String {
        let remaining = max(0, duration - elapsedTime)
        return "-\(Self.formatTime(remaining))"
    }

    public static func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, timeInterval))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Empty track placeholder when no media is playing
    public static let empty = MediaTrack(
        title: "No Media Playing",
        artist: "Ready for playback",
        album: "",
        duration: 0,
        elapsedTime: 0,
        isPlaying: false,
        playerType: .unknown,
        artwork: nil,
        accentColor: .gray,
        secondaryColor: .gray.opacity(0.6)
    )

    public static func == (lhs: MediaTrack, rhs: MediaTrack) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.artist == rhs.artist &&
        lhs.album == rhs.album &&
        lhs.duration == rhs.duration &&
        lhs.isPlaying == rhs.isPlaying &&
        lhs.playerType == rhs.playerType &&
        abs(lhs.elapsedTime - rhs.elapsedTime) < 1.0
    }
}
