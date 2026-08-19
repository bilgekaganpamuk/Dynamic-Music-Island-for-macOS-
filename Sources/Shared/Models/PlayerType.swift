import Foundation
import SwiftUI

/// Supported media players and streaming services
public enum PlayerType: String, CaseIterable, Identifiable, Sendable {
    case appleMusic = "Apple Music"
    case spotify = "Spotify"
    case youtubeMusic = "YouTube Music"
    case webMedia = "Web Media"
    case tidal = "Tidal"
    case unknown = "System Media"

    public var id: String { rawValue }

    /// SF Symbol icon associated with the player
    public var iconName: String {
        switch self {
        case .appleMusic:
            return "apple.logo"
        case .spotify:
            return "waveform.and.person.filled"
        case .youtubeMusic:
            return "play.rectangle.fill"
        case .webMedia:
            return "safari.fill"
        case .tidal:
            return "hifispeaker.fill"
        case .unknown:
            return "play.circle.fill"
        }
    }

    /// Brand theme accent color
    public var brandColor: Color {
        switch self {
        case .appleMusic:
            return Color(red: 0.98, green: 0.18, blue: 0.33) // Apple Music Rose/Pink
        case .spotify:
            return Color(red: 0.11, green: 0.84, blue: 0.38) // Spotify Emerald Green
        case .youtubeMusic:
            return Color(red: 1.00, green: 0.00, blue: 0.00) // YouTube Vibrant Red
        case .webMedia:
            return Color(red: 0.00, green: 0.48, blue: 1.00) // Safari Electric Blue
        case .tidal:
            return Color(red: 0.00, green: 0.00, blue: 0.00) // Tidal Onyx
        case .unknown:
            return Color.gray
        }
    }

    /// Bundle Identifier for automation commands
    public var bundleIdentifier: String {
        switch self {
        case .appleMusic:
            return "com.apple.Music"
        case .spotify:
            return "com.spotify.client"
        case .youtubeMusic, .webMedia:
            return "com.apple.Safari"
        case .tidal:
            return "com.tidal.desktop"
        case .unknown:
            return ""
        }
    }
}
