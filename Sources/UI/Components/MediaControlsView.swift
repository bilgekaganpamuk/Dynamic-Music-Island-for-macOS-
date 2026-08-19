import SwiftUI

/// Media controls bar featuring play/pause, track skipping, volume slider, and haptic animations.
public struct MediaControlsView: View {
    public let isPlaying: Bool
    public let playerType: PlayerType
    public let onPlayPause: () -> Void
    public let onNext: () -> Void
    public let onPrevious: () -> Void
    public let onVolumeChange: (Double) -> Void

    @State private var volume: Double = 75.0
    @State private var isHoveringPlay: Bool = false

    public init(
        isPlaying: Bool,
        playerType: PlayerType,
        onPlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onVolumeChange: @escaping (Double) -> Void
    ) {
        self.isPlaying = isPlaying
        self.playerType = playerType
        self.onPlayPause = onPlayPause
        self.onNext = onNext
        self.onPrevious = onPrevious
        self.onVolumeChange = onVolumeChange
    }

    public var body: some View {
        HStack(spacing: 20) {
            // Previous track button
            Button(action: onPrevious) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .buttonStyle(.plain)
            .help("Previous Track")

            // Play / Pause prominent button
            Button(action: onPlayPause) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                        .shadow(color: Color.white.opacity(0.2), radius: 6, x: 0, y: 2)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .offset(x: isPlaying ? 0 : 1.5)
                }
                .scaleEffect(isHoveringPlay ? 1.08 : 1.0)
                .animation(Constants.Animation.quickSpring, value: isHoveringPlay)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringPlay = $0 }
            .help(isPlaying ? "Pause" : "Play")

            // Next track button
            Button(action: onNext) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .buttonStyle(.plain)
            .help("Next Track")

            Spacer()

            // Volume Control Slider
            HStack(spacing: 6) {
                Image(systemName: volume == 0 ? "speaker.slash.fill" : (volume < 50 ? "speaker.wave.1.fill" : "speaker.wave.2.fill"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 14)

                Slider(value: $volume, in: 0...100) { _ in
                    onVolumeChange(volume)
                }
                .frame(width: 80)
                .accentColor(playerType.brandColor)
            }
        }
    }
}
