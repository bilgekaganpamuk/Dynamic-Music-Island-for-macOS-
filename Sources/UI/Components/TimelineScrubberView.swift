import SwiftUI

/// Interactive timeline scrubbing bar supporting click-and-drag seeking with elapsed/remaining time labels.
public struct TimelineScrubberView: View {
    public let track: MediaTrack
    public let onSeek: (TimeInterval) -> Void

    @State private var isDragging: Bool = false
    @State private var dragProgress: Double = 0.0

    public init(track: MediaTrack, onSeek: @escaping (TimeInterval) -> Void) {
        self.track = track
        self.onSeek = onSeek
    }

    private var currentDisplayProgress: Double {
        isDragging ? dragProgress : track.progress
    }

    public var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background capsule
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: isDragging ? 6 : 4)

                    // Elapsed progress capsule with gradient
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [track.accentColor, track.accentColor.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(0, min(geometry.size.width, geometry.size.width * currentDisplayProgress)),
                            height: isDragging ? 6 : 4
                        )

                    // Scrubber thumb circle
                    if isDragging || true {
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .frame(width: isDragging ? 12 : 8, height: isDragging ? 12 : 8)
                            .offset(x: max(0, min(geometry.size.width - (isDragging ? 12 : 8), (geometry.size.width * currentDisplayProgress) - (isDragging ? 6 : 4))))
                    }
                }
                .frame(height: 12)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let progress = max(0.0, min(1.0, value.location.x / geometry.size.width))
                            dragProgress = progress
                        }
                        .onEnded { value in
                            let progress = max(0.0, min(1.0, value.location.x / geometry.size.width))
                            dragProgress = progress
                            isDragging = false
                            let targetTime = progress * track.duration
                            onSeek(targetTime)
                        }
                )
            }
            .frame(height: 12)

            // Time labels
            HStack {
                Text(isDragging ? MediaTrack.formatTime(dragProgress * track.duration) : track.formattedElapsedTime)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)

                Spacer()

                Text(track.formattedRemainingTime)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
}
