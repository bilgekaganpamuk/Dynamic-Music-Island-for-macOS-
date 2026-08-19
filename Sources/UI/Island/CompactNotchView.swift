import SwiftUI
import UniformTypeIdentifiers

/// Compact notch view that hugs the physical MacBook notch with left/right wing indicators and drop-to-shelf support.
public struct CompactNotchView: View {
    public let track: MediaTrack
    public let notchWidth: CGFloat
    public let notchHeight: CGFloat
    public let onFileDropped: () -> Void

    @State private var isDragTargeted: Bool = false

    public init(
        track: MediaTrack,
        notchWidth: CGFloat = 185.0,
        notchHeight: CGFloat = 34.0,
        onFileDropped: @escaping () -> Void = {}
    ) {
        self.track = track
        self.notchWidth = notchWidth
        self.notchHeight = notchHeight
        self.onFileDropped = onFileDropped
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Left Wing: Album Artwork or Player Icon
            HStack(spacing: 0) {
                if isDragTargeted {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                } else if let artwork = track.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 19, height: 19)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                        )
                } else {
                    Image(systemName: track.playerType.iconName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(track.playerType.brandColor)
                }
            }
            .frame(width: Constants.Layout.compactWingWidth, height: notchHeight)

            // Hardware Notch Center Void (matches the physical notch footprint)
            Color.clear
                .frame(width: max(0, notchWidth), height: notchHeight)

            // Right Wing: Audio Waveform Visualizer
            HStack(spacing: 0) {
                if isDragTargeted {
                    Text("Drop")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                } else {
                    WaveformVisualizerView(
                        isPlaying: track.isPlaying,
                        barColor: track.accentColor,
                        barCount: 4
                    )
                }
            }
            .frame(width: Constants.Layout.compactWingWidth, height: notchHeight)
        }
        .padding(.horizontal, 4)
        .background(isDragTargeted ? Color.blue.opacity(0.3) : Color.black)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    bottomLeading: 14.0,
                    bottomTrailing: 14.0
                )
            )
        )
        .onDrop(of: [UTType.fileURL, UTType.item, UTType.data], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        Task { @MainActor in
            let urls = await FileDropManager.extractURLs(from: providers)
            if !urls.isEmpty {
                FileDropManager.shared.addFiles(from: urls)
                WidgetManager.shared.switchToTab(.tray)
                onFileDropped()
            }
        }
        return true
    }
}
