import SwiftUI

/// Main container view for the Dynamic Music Island.
/// Renders fluid liquid transitions between Compact Notch, Hover Preview, and Expanded Card modes.
public struct IslandRootView: View {
    @State private var mediaManager = MediaManager.shared
    @State private var screenObserver = ScreenObserver.shared
    @State private var coordinator = IslandStateCoordinator.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Visible Dynamic Island Card docked at top center
            activeCardView
                .contentShape(Rectangle())
                .onHover { hovering in
                    coordinator.setHovering(hovering)
                }

            Spacer(minLength: 0)
        }
        .frame(width: IslandWindowController.canvasWidth, height: IslandWindowController.canvasHeight, alignment: .top)
        .ignoresSafeArea()
        .animation(Constants.Animation.liquidSpring, value: coordinator.activePresentationState)
        .animation(Constants.Animation.liquidSpring, value: mediaManager.currentTrack)
    }

    @ViewBuilder
    private var activeCardView: some View {
        switch coordinator.activePresentationState {
        case .compact:
            if screenObserver.currentGeometry.hasHardwareNotch {
                CompactNotchView(
                    track: mediaManager.currentTrack,
                    notchWidth: screenObserver.currentGeometry.notchWidth,
                    notchHeight: screenObserver.currentGeometry.notchHeight,
                    onFileDropped: {
                        coordinator.expand()
                    }
                )
                .onTapGesture {
                    coordinator.expand()
                }
            } else {
                FloatingPillView(
                    track: mediaManager.currentTrack,
                    onExpand: {
                        coordinator.expand()
                    }
                )
            }

        case .hover:
            HoverPreviewView(
                track: mediaManager.currentTrack,
                hasHardwareNotch: screenObserver.currentGeometry.hasHardwareNotch,
                notchHeight: screenObserver.currentGeometry.notchHeight
            )
            .onTapGesture {
                coordinator.expand()
            }

        case .expanded:
            ExpandedIslandView(
                track: mediaManager.currentTrack,
                hasHardwareNotch: screenObserver.currentGeometry.hasHardwareNotch,
                notchHeight: screenObserver.currentGeometry.notchHeight,
                onPlayPause: { MediaManager.shared.playPause() },
                onNext: { MediaManager.shared.nextTrack() },
                onPrevious: { MediaManager.shared.previousTrack() },
                onSeek: { targetTime in MediaManager.shared.seek(to: targetTime) },
                onVolumeChange: { volume in MediaManager.shared.setVolume(volume) },
                onCollapse: { coordinator.collapse() }
            )

        case .floatingPill:
            FloatingPillView(
                track: mediaManager.currentTrack,
                onExpand: {
                    coordinator.expand()
                }
            )

        case .hidden:
            Color.clear
                .frame(width: 0, height: 0)
        }
    }
}
