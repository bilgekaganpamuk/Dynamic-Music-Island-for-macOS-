import Foundation
import SwiftUI

/// Represents the visual presentation state of the Dynamic Island
public enum IslandState: String, CaseIterable, Sendable {
    /// Completely hidden when no media is active or user closed it
    case hidden
    /// Snug around the notch with album artwork on left wing and animated waveform on right wing
    case compact
    /// Slightly expanded on cursor hover showing title, artist, and mini progress indicator
    case hover
    /// Full expanded card with controls, scrubbing bar, volume, and lyrics/details
    case expanded
    /// Floating pill mode used on notchless screens, iMac, or external monitors
    case floatingPill

    /// Animation duration for state transitions
    public var transitionDuration: Double {
        switch self {
        case .hidden:
            return 0.25
        case .compact:
            return 0.35
        case .hover:
            return 0.28
        case .expanded:
            return 0.42
        case .floatingPill:
            return 0.35
        }
    }
}
