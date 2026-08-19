import SwiftUI

/// Full expanded island card featuring rich media controls, file shelf (Tray), AirDrop station, clipboard hub, and dynamic widgets.
public struct ExpandedIslandView: View {
    public let track: MediaTrack
    public let hasHardwareNotch: Bool
    public let notchHeight: CGFloat
    public let onPlayPause: () -> Void
    public let onNext: () -> Void
    public let onPrevious: () -> Void
    public let onSeek: (TimeInterval) -> Void
    public let onVolumeChange: (Double) -> Void
    public let onCollapse: () -> Void

    @State private var widgetManager = WidgetManager.shared
    @State private var batteryManager = BatteryManager.shared
    @State private var fileDropManager = FileDropManager.shared
    @State private var clipboardManager = ClipboardManager.shared
    @State private var networkMonitor = NetworkSpeedMonitor.shared

    public init(
        track: MediaTrack,
        hasHardwareNotch: Bool = true,
        notchHeight: CGFloat = 34.0,
        onPlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onSeek: @escaping (TimeInterval) -> Void,
        onVolumeChange: @escaping (Double) -> Void,
        onCollapse: @escaping () -> Void
    ) {
        self.track = track
        self.hasHardwareNotch = hasHardwareNotch
        self.notchHeight = notchHeight
        self.onPlayPause = onPlayPause
        self.onNext = onNext
        self.onPrevious = onPrevious
        self.onSeek = onSeek
        self.onVolumeChange = onVolumeChange
        self.onCollapse = onCollapse
    }

    public var body: some View {
        VStack(spacing: 10) {
            // Space reserved for hardware notch if present
            if hasHardwareNotch {
                Color.clear
                    .frame(height: notchHeight)
            }

            // Top Header: [Widgets] / [Shelf] / [Clipboard] Tabs & Metrics
            HStack(spacing: 6) {
                // Tab Switcher
                HStack(spacing: 3) {
                    tabButton(mode: .home, icon: "sparkles", title: L10n.widgetsTab)
                    tabButton(mode: .tray, icon: "tray.full.fill", title: L10n.shelfTab, badgeCount: fileDropManager.items.count)
                    tabButton(mode: .clipboard, icon: "doc.on.clipboard", title: L10n.clipboardTab, badgeCount: clipboardManager.history.count)
                }
                .padding(2)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .layoutPriority(1)

                Spacer(minLength: 2)

                // Network Speed Indicator
                HStack(spacing: 3) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(networkMonitor.downloadSpeedString)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())

                // Battery Status Indicator
                HStack(spacing: 3) {
                    Text("\(batteryManager.batteryLevel)%")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)

                    Image(systemName: batteryManager.isCharging ? "battery.100.bolt" : "battery.100")
                        .font(.system(size: 10))
                        .foregroundColor(batteryManager.isCharging ? .green : (batteryManager.batteryLevel < 20 ? .red : .white))
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

                // Collapse Button
                Button(action: onCollapse) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(4)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Collapse to Notch")
            }
            .padding(.horizontal, 16)

            // Content Area depending on Active Tab
            switch widgetManager.activeTab {
            case .tray:
                NotchTrayView()
            case .clipboard:
                ClipboardView()
            case .home:
                homeWidgetContent
                widgetSwitcherBar
            }
        }
        .frame(width: (widgetManager.activeTab == .home && widgetManager.activeWidget == .browser) ? WebBookmarksManager.shared.sizeMode.width : Constants.Layout.expandedWidth)
        .animation(Constants.Animation.liquidSpring, value: WebBookmarksManager.shared.sizeMode)
        .background(
            ZStack {
                Color.black.opacity(0.95)

                // Subtle ambient radial background glow matching current track
                RadialGradient(
                    colors: [track.secondaryColor.opacity(0.25), Color.clear],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 220
                )
            }
        )
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    bottomLeading: Constants.Layout.expandedCornerRadius,
                    bottomTrailing: Constants.Layout.expandedCornerRadius
                )
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    bottomLeading: Constants.Layout.expandedCornerRadius,
                    bottomTrailing: Constants.Layout.expandedCornerRadius
                )
            )
            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.7), radius: 24, x: 0, y: 10)
    }

    // MARK: - Tab Button
    private func tabButton(mode: IslandTabMode, icon: String, title: String, badgeCount: Int = 0) -> some View {
        Button {
            widgetManager.switchToTab(mode)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))

                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(widgetManager.activeTab == mode ? Color.white.opacity(0.2) : Color.clear)
            .clipShape(Capsule())
            .foregroundColor(widgetManager.activeTab == mode ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Home Tab Widget Router
    @ViewBuilder
    private var homeWidgetContent: some View {
        switch widgetManager.activeWidget {
        case .music:
            musicPlayerContent
        case .pomodoro:
            PomodoroWidgetView()
        case .notes:
            QuickNoteWidgetView()
        case .hydration:
            HydrationWidgetView()
        case .shortcuts:
            AppShortcutsWidgetView()
        case .browser:
            QuickWebBrowserView()
        case .weather:
            WeatherWidgetView()
        case .calendar:
            CalendarWidgetView()
        case .mirror:
            CameraMirrorWidgetView()
        }
    }

    // MARK: - Music Player Content
    private var musicPlayerContent: some View {
        VStack(spacing: 10) {
            // Center Content: Album Art + Track Information + Waveform
            HStack(spacing: 14) {
                // High-Res Album Art with Dynamic Ambient Glow
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(track.accentColor.opacity(0.4))
                        .blur(radius: 10)
                        .frame(width: 50, height: 50)

                    if let artwork = track.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [Color.gray.opacity(0.3), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                }

                // Track Details
                VStack(alignment: .leading, spacing: 3) {
                    MarqueeText(
                        track.title,
                        font: .system(size: 14, weight: .bold),
                        color: .white
                    )

                    Text(track.artist)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)

                    if !track.album.isEmpty {
                        Text(track.album)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Waveform Visualizer
                WaveformVisualizerView(
                    isPlaying: track.isPlaying,
                    barColor: track.accentColor,
                    barCount: 5
                )
            }
            .padding(.horizontal, 16)

            // Timeline Scrubber
            TimelineScrubberView(track: track, onSeek: onSeek)
                .padding(.horizontal, 16)

            // Playback Controls & Volume
            MediaControlsView(
                isPlaying: track.isPlaying,
                playerType: track.playerType,
                onPlayPause: onPlayPause,
                onNext: onNext,
                onPrevious: onPrevious,
                onVolumeChange: onVolumeChange
            )
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Bottom Widget Switcher Bar
    private var widgetSwitcherBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(WidgetType.allCases) { widget in
                        Button {
                            withAnimation(Constants.Animation.liquidSpring) {
                                widgetManager.switchToWidget(widget)
                                proxy.scrollTo(widget.id, anchor: .center)
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: widget.iconName)
                                    .font(.system(size: 9, weight: .semibold))
                                Text(widget.title)
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(widgetManager.activeWidget == widget ? Color.white.opacity(0.22) : Color.white.opacity(0.06))
                            .clipShape(Capsule())
                            .foregroundColor(widgetManager.activeWidget == widget ? .white : .secondary)
                        }
                        .buttonStyle(.plain)
                        .id(widget.id)
                    }
                }
                .padding(.horizontal, 16)
            }
            .mask(
                HStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 8)
                    Rectangle().fill(Color.black)
                    LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 8)
                }
            )
            .padding(.bottom, 8)
            .onChange(of: widgetManager.activeWidget) { _, newWidget in
                withAnimation {
                    proxy.scrollTo(newWidget.id, anchor: .center)
                }
            }
        }
    }
}

