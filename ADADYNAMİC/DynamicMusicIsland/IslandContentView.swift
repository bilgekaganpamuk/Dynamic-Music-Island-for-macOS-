import SwiftUI
import AppKit

struct IslandContentView: View {
    @StateObject private var musicController = SpotifyController() // Kendi controller ismin neyse o kalmalı
    @StateObject private var stashManager = FileStashManager()
    @State private var isExpanded = false
    @State private var isHovering = false
    @State private var showDropZone = false
    @State private var isDragTargeted = false
    
    init() {
    }
    
    var currentWidth: CGFloat {
        if showDropZone { return 360 }  // Drop zone için ferah genişlik
        if isExpanded { return 340 }
        if musicController.hasTrack {
            // Hover menüsüne yeni buton eklendiği için genişliği biraz artırdık (220 -> 250)
            return isHovering ? 250 : 200
        }
        return 140
    }
    
    var currentHeight: CGFloat {
        if showDropZone {
            return 130  // Yeni padding'lere uygun yükseklik
        }
        return isExpanded ? 240 : 36  // Music island only
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main island content (music player) - only show if drop zone is hidden
            if !showDropZone {
                ZStack {
                    // Color-adaptive background with dominant color from artwork
                    RoundedRectangle(cornerRadius: isExpanded ? 24 : 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(musicController.dominantColor).opacity(0.6),
                                    Color.black.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: isExpanded ? 24 : 18)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color(musicController.dominantColor).opacity(isHovering || isDragTargeted ? 0.6 : 0.3),
                                            .white.opacity(isHovering || isDragTargeted ? 0.3 : 0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: (isHovering || isDragTargeted) && !isExpanded ? 1.5 : 1
                                )
                        )
                        .shadow(
                            color: Color(musicController.dominantColor).opacity(isHovering ? 0.4 : 0.2),
                            radius: isHovering ? 25 : 20,
                            x: 0,
                            y: isHovering ? 12 : 10
                        )
                    
                    if isExpanded {
                        expandedContent
                    } else {
                        collapsedContent
                    }
                    
                    // Show drop indicator overlay when dragging
                    if isDragTargeted {
                        VStack {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Drop to show file zone")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 24 : 18))
                    }
                }
                .frame(height: isExpanded ? 240 : 36)  // Fixed height for music island
                .onDrop(of: [.fileURL, .url, .image, .png, .jpeg, .tiff, .data], isTargeted: $isDragTargeted) { providers in
                    for provider in providers {
                        stashManager.addFile(provider: provider)
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showDropZone = true
                    }
                    updateWindowSizeForDropZone()
                    return true
                }
            }
            
            // Drop zone (replaces the music island when visible)
            if showDropZone {
                DropZoneView(stashManager: stashManager)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
            }
        }
        .frame(width: currentWidth, height: currentHeight)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: musicController.hasTrack)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showDropZone)
        .animation(.easeInOut(duration: 0.5), value: musicController.dominantColor)
        .onTapGesture {
            if !isExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded = true
                }
                updateWindowSize(expanded: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CollapseIsland"))) { _ in
            if isExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded = false
                }
                updateWindowSize(expanded: false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HideDropZone"))) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showDropZone = false
                isExpanded = false  // Return to collapsed music view
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                updateWindowSize(expanded: false)  // Force collapsed size
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowDropZone"))) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showDropZone = true
            }
            updateWindowSizeForDropZone()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
            if !isExpanded && musicController.hasTrack {
                DispatchQueue.main.async {
                    updateWindowSizeForHover()
                }
            }
        }
    }
    
    // MARK: - Window Update Helpers
    private func updateWindowSize(expanded: Bool) {
        NotificationCenter.default.post(
            name: NSNotification.Name("RecenterWindow"),
            object: nil,
            userInfo: ["width": currentWidth, "height": currentHeight, "expanded": expanded]
        )
    }
    
    private func updateWindowSizeForHover() {
        NotificationCenter.default.post(
            name: NSNotification.Name("RecenterWindow"),
            object: nil,
            userInfo: ["width": currentWidth, "height": currentHeight, "expanded": isExpanded]
        )
    }
    
    private func updateWindowSizeForDropZone() {
        let newWidth = max(currentWidth, 360)
        NotificationCenter.default.post(
            name: NSNotification.Name("RecenterWindow"),
            object: nil,
            userInfo: ["width": newWidth, "height": currentHeight, "expanded": isExpanded]
        )
    }
    
    // MARK: - Collapsed View
    @ViewBuilder
    var collapsedContent: some View {
        HStack(spacing: 10) {
            // Album art or music icon
            ZStack {
                if let artwork = musicController.albumArtwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 26, height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color(musicController.dominantColor), Color(musicController.dominantColor).opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
            }
            
            if musicController.hasTrack {
                if isHovering {
                    // Hover edince çıkan tuşlar (En sağda Dosya/DropZone butonu)
                    HStack(spacing: 10) {
                        QuickActionButton(systemName: "shuffle", isActive: musicController.isShuffling) {
                            musicController.toggleShuffle()
                        }
                        
                        QuickActionButton(systemName: "backward.fill", isActive: false) {
                            musicController.previousTrack()
                        }
                        
                        QuickActionButton(
                            systemName: musicController.isPlaying ? "pause.fill" : "play.fill",
                            isActive: true
                        ) {
                            musicController.togglePlayPause()
                        }
                        
                        QuickActionButton(systemName: "forward.fill", isActive: false) {
                            musicController.nextTrack()
                        }
                        
                        // İŞTE BURASI: En sağdaki yeni dosya (DropZone) açma butonu
                        QuickActionButton(systemName: "folder.fill", isActive: false) {
                            NotificationCenter.default.post(name: NSNotification.Name("ShowDropZone"), object: nil)
                        }
                    }
                } else {
                    // Track info - show when not hovering
                    VStack(alignment: .leading, spacing: 1) {
                        Text(musicController.trackTitle)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(musicController.artistName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 100, alignment: .leading)
                    
                    Spacer()
                    
                    if musicController.isPlaying {
                        SoundWaveView(isPlaying: true, color: Color(musicController.dominantColor))
                            .frame(width: 20, height: 16)
                    } else {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            } else {
                Text("Not Playing")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
    }
    
    // MARK: - Expanded View
    @ViewBuilder
    var expandedContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Album artwork
                ZStack {
                    if let artwork = musicController.albumArtwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color(musicController.dominantColor).opacity(0.5), radius: 12, x: 0, y: 6)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color(musicController.dominantColor), Color(musicController.dominantColor).opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                }
                
                // Track info and controls
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(musicController.trackTitle.isEmpty ? "No Track" : musicController.trackTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(musicController.artistName.isEmpty ? "Unknown Artist" : musicController.artistName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                        
                        if !musicController.albumName.isEmpty {
                            Text(musicController.albumName)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Playback controls
                    HStack(spacing: 20) {
                        ControlButton(systemName: "backward.fill", size: 14) {
                            musicController.previousTrack()
                        }
                        
                        ControlButton(
                            systemName: musicController.isPlaying ? "pause.fill" : "play.fill",
                            size: 20,
                            isPrimary: true,
                            accentColor: Color(musicController.dominantColor)
                        ) {
                            musicController.togglePlayPause()
                        }
                        
                        ControlButton(systemName: "forward.fill", size: 14) {
                            musicController.nextTrack()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Progress bar
            SeekableProgressBar(
                progress: musicController.progress,
                duration: musicController.duration,
                elapsedTime: musicController.elapsedTime,
                accentColor: Color(musicController.dominantColor),
                onSeek: { percentage in
                    musicController.seek(to: percentage)
                }
            )
            .padding(.horizontal, 16)
            
            // Volume slider and quick actions
            HStack(spacing: 16) {
                // Shuffle button
                ControlButton(
                    systemName: "shuffle",
                    size: 12,
                    isActive: musicController.isShuffling,
                    accentColor: Color(musicController.dominantColor)
                ) {
                    musicController.toggleShuffle()
                }
                
                // Volume slider
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    
                    VolumeSlider(
                        volume: $musicController.volume,
                        accentColor: Color(musicController.dominantColor),
                        onVolumeChange: { newVolume in
                            musicController.setVolume(newVolume)
                        }
                    )
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                
                // İŞTE BURASI: Genişlemiş menüde Repeat yerine DropZone butonu
                ControlButton(
                    systemName: "folder.fill",
                    size: 12,
                    isActive: false,
                    accentColor: Color(musicController.dominantColor)
                ) {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowDropZone"), object: nil)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }
}

// MARK: - Control Button
struct ControlButton: View {
    let systemName: String
    let size: CGFloat
    var isPrimary: Bool = false
    var isActive: Bool = false
    var accentColor: Color = .white
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(isActive ? accentColor : .white)
                .frame(width: isPrimary ? 40 : 30, height: isPrimary ? 40 : 30)
                .background(
                    Circle()
                        .fill(isPrimary ? accentColor.opacity(0.3) : (isActive ? accentColor.opacity(0.2) : .clear))
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let systemName: String
    var isActive: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isActive ? .green : .white.opacity(0.7))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(isActive ? .white.opacity(0.15) : .white.opacity(0.05))
                )
                .scaleEffect(isPressed ? 0.85 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Volume Slider
struct VolumeSlider: View {
    @Binding var volume: Double
    let accentColor: Color
    let onVolumeChange: (Double) -> Void
    
    @State private var isHovering = false
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.2))
                    .frame(height: 4)
                
                // Volume fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * max(0, min(1, volume)), height: 4)
                
                // Thumb (shows on hover)
                if isHovering || isDragging {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 12, height: 12)
                        .shadow(color: accentColor.opacity(0.5), radius: 4, x: 0, y: 2)
                        .offset(x: (geometry.size.width * max(0, min(1, volume))) - 6)
                }
            }
            .frame(height: 12)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let newVolume = max(0, min(1, value.location.x / geometry.size.width))
                        volume = newVolume
                        onVolumeChange(newVolume)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .frame(height: 12)
    }
}

// MARK: - Sound Wave Animation
struct SoundWaveView: View {
    let isPlaying: Bool
    var color: Color = .green
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                SoundBar(isPlaying: isPlaying, delay: Double(index) * 0.1, color: color)
            }
        }
    }
}

struct SoundBar: View {
    let isPlaying: Bool
    let delay: Double
    var color: Color = .green
    
    @State private var height: CGFloat = 4
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(color)
            .frame(width: 3, height: height)
            .onAppear {
                if isPlaying {
                    startAnimation()
                }
            }
            .onChange(of: isPlaying) { _, playing in
                if playing {
                    startAnimation()
                } else {
                    height = 4
                }
            }
    }
    
    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: 0.4)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            height = CGFloat.random(in: 8...16)
        }
    }
}

// MARK: - Seekable Progress Bar
struct SeekableProgressBar: View {
    let progress: Double
    let duration: Double
    let elapsedTime: Double
    let accentColor: Color
    let onSeek: (Double) -> Void
    
    @State private var isHovering = false
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.2))
                        .frame(height: isHovering || isDragging ? 8 : 4)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * max(0, min(1, progress)), height: isHovering || isDragging ? 8 : 4)
                    
                    // Scrubber knob (shows on hover)
                    if isHovering || isDragging {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 14, height: 14)
                            .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            .offset(x: geometry.size.width * max(0, min(1, progress)) - 7)
                    }
                }
                .frame(height: isHovering || isDragging ? 14 : 4)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let percentage = max(0, min(1, value.location.x / geometry.size.width))
                            onSeek(percentage)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovering = hovering
                    }
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .frame(height: isHovering || isDragging ? 14 : 4)
            
            // Time labels
            HStack {
                Text(formatTime(elapsedTime))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
