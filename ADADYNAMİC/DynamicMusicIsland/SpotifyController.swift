import Foundation
import AppKit
import Combine

/// Spotify-specific controller using AppleScript
/// More reliable than MediaRemote for getting Spotify metadata
public class SpotifyController: ObservableObject {
    @Published var trackTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumName: String = ""
    @Published var albumArtwork: NSImage?
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var elapsedTime: Double = 0.0
    @Published var volume: Double = 0.5
    @Published var isShuffling: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var dominantColor: NSColor = .purple
    
    enum RepeatMode: String {
        case off = "off"
        case track = "one"
        case context = "all"
    }
    
    var hasTrack: Bool {
        return !trackTitle.isEmpty
    }
    
    private var updateTimer: Timer?
    private var progressTimer: Timer?
    private var lastTrackId: String = ""
    private var lastServerSync: Date = Date()
    private var lastSyncedPosition: Double = 0.0
    
    public init() {
        startPeriodicUpdate()
        startProgressTimer()
    }
    
    deinit {
        updateTimer?.invalidate()
        progressTimer?.invalidate()
    }
    
    private func startPeriodicUpdate() {
        // Update every 0.5 seconds for smooth progress
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.fetchNowPlayingInfo()
        }
        
        // Initial fetch
        fetchNowPlayingInfo()
    }
    
    private func startProgressTimer() {
        // Update progress bar smoothly every 0.1 seconds when playing
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateLocalProgress()
        }
    }
    
    private func updateLocalProgress() {
        // Capture current state on main thread
        let currentlyPlaying = isPlaying
        let currentDuration = duration
        let syncedPosition = lastSyncedPosition
        let syncTime = lastServerSync
        
        guard currentlyPlaying, currentDuration > 0 else { return }
        
        // Calculate time elapsed since last server sync
        let timeSinceSync = Date().timeIntervalSince(syncTime)
        let estimatedElapsed = syncedPosition + timeSinceSync
        
        // Update progress smoothly
        let newElapsed = min(currentDuration, estimatedElapsed)
        let newProgress = min(1.0, max(0.0, newElapsed / currentDuration))
        
        DispatchQueue.main.async {
            self.elapsedTime = newElapsed
            self.progress = newProgress
        }
    }
    
    func fetchNowPlayingInfo() {
        // Check if Spotify is running
        let runningApps = NSWorkspace.shared.runningApplications
        let spotifyRunning = runningApps.contains { app in
            app.bundleIdentifier == "com.spotify.client"
        }
        
        guard spotifyRunning else {
            DispatchQueue.main.async {
                self.trackTitle = ""
                self.artistName = ""
                self.albumName = ""
                self.albumArtwork = nil
                self.isPlaying = false
                self.progress = 0.0
                self.duration = 0.0
                self.elapsedTime = 0.0
            }
            return
        }
        
        let script = """
        tell application "Spotify"
            if player state is not stopped then
                set trackName to name of current track
                set trackArtist to artist of current track
                set trackAlbum to album of current track
                set trackDuration to duration of current track
                set trackPosition to player position
                set trackId to id of current track
                set isPlaying to (player state is playing)
                set currentVolume to sound volume
                set isShuffling to shuffling
                set repeatState to repeating
                
                return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & trackDuration & "|||" & trackPosition & "|||" & isPlaying & "|||" & trackId & "|||" & currentVolume & "|||" & isShuffling & "|||" & repeatState
            else
                return ""
            end if
        end tell
        """
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let result = self.executeAppleScript(script), !result.isEmpty else {
                DispatchQueue.main.async {
                    self.trackTitle = ""
                    self.artistName = ""
                    self.albumName = ""
                    self.isPlaying = false
                    self.progress = 0.0
                    self.duration = 0.0
                    self.elapsedTime = 0.0
                }
                return
            }
            
            let components = result.split(separator: "|||").map(String.init)
            
            guard components.count >= 10 else {
                return
            }
            
            let title = components[0]
            let artist = components[1]
            let album = components[2]
            // Handle locale-specific decimal separator (comma vs period)
            let durationString = components[3].replacingOccurrences(of: ",", with: ".")
            let positionString = components[4].replacingOccurrences(of: ",", with: ".")
            let durationMs = Double(durationString) ?? 0.0
            let positionMs = Double(positionString) ?? 0.0
            let playing = components[5] == "true"
            let trackId = components[6]
            let volumeValue = Double(components[7]) ?? 50.0
            let shuffling = components[8] == "true"
            let repeatState = components[9]
            
            // Spotify returns duration in milliseconds but position in seconds!
            let duration = durationMs / 1000.0
            let positionSec = positionMs  // Already in seconds
            
            DispatchQueue.main.async {
                self.trackTitle = title
                self.artistName = artist
                self.albumName = album
                self.duration = duration
                self.elapsedTime = positionSec
                self.isPlaying = playing
                self.volume = volumeValue / 100.0
                self.isShuffling = shuffling
                
                // Parse repeat mode
                if repeatState == "true" {
                    self.repeatMode = .context
                } else {
                    self.repeatMode = .off
                }
                
                // Mark the time we synced with Spotify
                self.lastServerSync = Date()
                self.lastSyncedPosition = positionSec
                
                if duration > 0 {
                    self.progress = min(1.0, max(0.0, positionSec / duration))
                }
                
                // Fetch artwork if track changed
                if self.lastTrackId != trackId {
                    self.lastTrackId = trackId
                    self.fetchArtwork()
                }
            }
        }
    }
    
    private func fetchArtwork() {
        let script = """
        tell application "Spotify"
            if player state is not stopped then
                set artworkUrl to artwork url of current track
                return artworkUrl
            else
                return ""
            end if
        end tell
        """
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            guard let urlString = self.executeAppleScript(script), !urlString.isEmpty else {
                return
            }
            
            guard let url = URL(string: urlString) else { return }
            
            do {
                let data = try Data(contentsOf: url)
                if let image = NSImage(data: data) {
                    // Extract dominant color
                    let color = self.extractDominantColor(from: image)
                    
                    DispatchQueue.main.async {
                        self.albumArtwork = image
                        self.dominantColor = color
                    }
                }
            } catch {
                // Silently fail - artwork is optional
            }
        }
    }
    
    private func extractDominantColor(from image: NSImage) -> NSColor {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .purple
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return .purple
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Sample colors and find dominant
        var redSum: CGFloat = 0
        var greenSum: CGFloat = 0
        var blueSum: CGFloat = 0
        var count: CGFloat = 0
        
        // Sample every 10th pixel for performance
        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0
                
                // Skip very dark or very light pixels
                let brightness = (r + g + b) / 3.0
                if brightness > 0.15 && brightness < 0.85 {
                    redSum += r
                    greenSum += g
                    blueSum += b
                    count += 1
                }
            }
        }
        
        guard count > 0 else { return .purple }
        
        return NSColor(
            red: redSum / count,
            green: greenSum / count,
            blue: blueSum / count,
            alpha: 1.0
        )
    }
    
    private func executeAppleScript(_ script: String) -> String? {
        guard let appleScript = NSAppleScript(source: script) else {
            return nil
        }
        
        var error: NSDictionary?
        let descriptor = appleScript.executeAndReturnError(&error)
        
        if error != nil {
            return nil
        }
        
        return descriptor.stringValue
    }
    
    // MARK: - Playback Controls
    
    func togglePlayPause() {
        executeSimpleCommand("playpause")
    }
    
    func play() {
        executeSimpleCommand("play")
    }
    
    func pause() {
        executeSimpleCommand("pause")
    }
    
    func nextTrack() {
        executeSimpleCommand("next track")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchNowPlayingInfo()
        }
    }
    
    func previousTrack() {
        executeSimpleCommand("previous track")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchNowPlayingInfo()
        }
    }
    
    func seek(to percentage: Double) {
        guard duration > 0 else { return }
        let targetTime = duration * max(0, min(1, percentage))
        
        let script = """
        tell application "Spotify"
            set player position to \(targetTime)
        end tell
        """
        
        DispatchQueue.main.async {
            self.elapsedTime = targetTime
            self.progress = percentage
            self.lastServerSync = Date()
            self.lastSyncedPosition = targetTime
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.executeAppleScript(script)
        }
    }
    
    func setVolume(_ level: Double) {
        let volumePercent = Int(level * 100)
        let script = """
        tell application "Spotify"
            set sound volume to \(volumePercent)
        end tell
        """
        
        DispatchQueue.main.async {
            self.volume = level
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.executeAppleScript(script)
        }
    }
    
    func toggleShuffle() {
        let script = """
        tell application "Spotify"
            set shuffling to not shuffling
        end tell
        """
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.executeAppleScript(script)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.fetchNowPlayingInfo()
        }
    }
    
    func toggleRepeat() {
        let script = """
        tell application "Spotify"
            set repeating to not repeating
        end tell
        """
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.executeAppleScript(script)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.fetchNowPlayingInfo()
        }
    }
    
    private func executeSimpleCommand(_ command: String) {
        let script = """
        tell application "Spotify"
            \(command)
        end tell
        """
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.executeAppleScript(script)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.fetchNowPlayingInfo()
        }
    }
}
