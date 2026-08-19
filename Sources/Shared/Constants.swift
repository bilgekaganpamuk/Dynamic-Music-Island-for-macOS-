import Foundation
import SwiftUI

/// Centralized design tokens, animation curves, and system identifiers
public enum Constants {
    public enum Animation {
        /// Apple-like fluid spring physics for notch expansion/contraction
        public static let liquidSpring = SwiftUI.Animation.spring(response: 0.38, dampingFraction: 0.72)
        public static let quickSpring = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.8)
        public static let bouncySpring = SwiftUI.Animation.spring(response: 0.45, dampingFraction: 0.65)
        public static let waveformFade = SwiftUI.Animation.easeInOut(duration: 0.2)
    }

    public enum Layout {
        public static let compactHeight: CGFloat = 34.0
        public static let compactWingWidth: CGFloat = 42.0
        public static let hoverWidth: CGFloat = 360.0
        public static let hoverHeight: CGFloat = 76.0
        public static let expandedWidth: CGFloat = 440.0
        public static let expandedHeight: CGFloat = 230.0
        
        // Dynamic Web Browser Dimensions
        public static let browserWidthCompact: CGFloat = 440.0
        public static let browserWidthStandard: CGFloat = 480.0
        public static let browserWidthLarge2X: CGFloat = 520.0
        
        public static let browserHeightCompact: CGFloat = 260.0
        public static let browserHeightStandard: CGFloat = 360.0
        public static let browserHeightLarge2X: CGFloat = 480.0

        public static let floatingPillWidth: CGFloat = 280.0
        public static let floatingPillHeight: CGFloat = 40.0
        public static let cornerRadius: CGFloat = 16.0
        public static let expandedCornerRadius: CGFloat = 26.0
    }

    public enum Notifications {
        public static let appleMusicPlayerInfo = "com.apple.Music.playerInfo"
        public static let spotifyPlaybackStateChanged = "com.spotify.client.PlaybackStateChanged"
    }

    public enum Players {
        public static let appleMusicBundleId = "com.apple.Music"
        public static let spotifyBundleId = "com.spotify.client"
    }

    public enum Defaults {
        public static let launchAtLoginKey = "LaunchAtLogin"
        public static let autoExpandOnTrackChangeKey = "AutoExpandOnTrackChange"
        public static let proMotionEnabledKey = "ProMotionEnabled"
        public static let selectedThemeKey = "SelectedTheme"
        public static let floatingPillPositionKey = "FloatingPillPosition"
    }
}
