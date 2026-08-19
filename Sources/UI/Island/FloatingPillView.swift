import SwiftUI
import UniformTypeIdentifiers

/// Floating pill view designed for notchless displays, external 4K monitors, and iMac screens.
public struct FloatingPillView: View {
    public let track: MediaTrack
    public let onExpand: () -> Void

    @State private var isDragTargeted: Bool = false

    public init(track: MediaTrack, onExpand: @escaping () -> Void) {
        self.track = track
        self.onExpand = onExpand
    }

    public var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 10) {
                // Mini Artwork
                if isDragTargeted {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                } else if let artwork = track.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 22, height: 22)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: track.playerType.iconName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(track.playerType.brandColor)
                }

                // Title & Artist
                VStack(alignment: .leading, spacing: 1) {
                    Text(isDragTargeted ? "Drop Files into Shelf" : track.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isDragTargeted ? .blue : .white)
                        .lineLimit(1)

                    Text(isDragTargeted ? "Release to stage" : track.artist)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: 140, alignment: .leading)

                Spacer(minLength: 4)

                // Waveform
                WaveformVisualizerView(
                    isPlaying: track.isPlaying,
                    barColor: track.accentColor,
                    barCount: 3
                )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(width: Constants.Layout.floatingPillWidth, height: Constants.Layout.floatingPillHeight)
            .background(isDragTargeted ? Color.blue.opacity(0.3) : Color.black.opacity(0.85))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isDragTargeted ? Color.blue : Color.white.opacity(0.18), lineWidth: isDragTargeted ? 1.5 : 0.5)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .onDrop(of: [UTType.fileURL, UTType.item, UTType.data], isTargeted: $isDragTargeted) { providers in
            Task { @MainActor in
                let urls = await FileDropManager.extractURLs(from: providers)
                if !urls.isEmpty {
                    FileDropManager.shared.addFiles(from: urls)
                    WidgetManager.shared.switchToTab(.tray)
                    onExpand()
                }
            }
            return true
        }
    }
}
