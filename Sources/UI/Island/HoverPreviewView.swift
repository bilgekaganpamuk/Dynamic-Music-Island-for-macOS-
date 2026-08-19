import SwiftUI

/// Medium preview card displayed when hovering over the notch.
public struct HoverPreviewView: View {
    public let track: MediaTrack
    public let hasHardwareNotch: Bool
    public let notchHeight: CGFloat

    public init(track: MediaTrack, hasHardwareNotch: Bool = true, notchHeight: CGFloat = 34.0) {
        self.track = track
        self.hasHardwareNotch = hasHardwareNotch
        self.notchHeight = notchHeight
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Space reserved for hardware notch if present
            if hasHardwareNotch {
                Color.clear
                    .frame(height: notchHeight)
            }

            HStack(spacing: 12) {
                // Album Art
                if let artwork = track.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 26, height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(track.playerType.brandColor.opacity(0.2))
                            .frame(width: 26, height: 26)

                        Image(systemName: track.playerType.iconName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(track.playerType.brandColor)
                    }
                }

                // Title & Artist
                VStack(alignment: .leading, spacing: 2) {
                    MarqueeText(track.title, font: .system(size: 12, weight: .semibold), color: .white)
                    Text(track.artist)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Waveform
                WaveformVisualizerView(
                    isPlaying: track.isPlaying,
                    barColor: track.accentColor,
                    barCount: 4
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)

            // Slim Bottom Progress Line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 2)

                    Rectangle()
                        .fill(track.accentColor)
                        .frame(width: max(0, geo.size.width * track.progress), height: 2)
                }
            }
            .frame(height: 2)
        }
        .frame(width: Constants.Layout.hoverWidth)
        .background(Color.black)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    bottomLeading: Constants.Layout.cornerRadius,
                    bottomTrailing: Constants.Layout.cornerRadius
                )
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    bottomLeading: Constants.Layout.cornerRadius,
                    bottomTrailing: Constants.Layout.cornerRadius
                )
            )
            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 12, x: 0, y: 4)
    }
}
