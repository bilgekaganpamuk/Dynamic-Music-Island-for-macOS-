import Foundation
import AppKit
import Combine

/// A hybrid music controller that supports both Spotify and Apple Music
/// Uses MediaRemote for Spotify and universal controls
/// Falls back to AppleScript for Apple Music if needed
class HybridMusicController: ObservableObject {
    @Published var trackTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumName: String = ""
    @Published var albumArtwork: NSImage?
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var elapsedTime: Double = 0.0
    @Published var currentApp: String = "None"
    
    var hasTrack: Bool {
        return !trackTitle.isEmpty
    }
    
    private let mediaRemote = MediaRemoteManager.shared
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Anchor points for interpolation
    private var anchorDate: Date = Date()
    private var anchorElapsedTime: Double = 0
    private var playbackRate: Double = 0
    
    init() {
        print("🎛️ HybridMusicController initializing...")
        setupNowPlayingObserver()
        startPeriodicUpdate()
        
        // Initial fetch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.fetchNowPlayingInfo()
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupNowPlayingObserver() {
        guard mediaRemote.isLoaded else {
            print("❌ MediaRemote not loaded")
            return
        }
        
        print("✅ MediaRemote framework loaded")
        mediaRemote.registerForNotifications()
        
        // Observe now playing changes
        NotificationCenter.default.publisher(for: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"))
            .sink { [weak self] _ in
                print("🎵 Now playing info changed")
                self?.fetchNowPlayingInfo()
            }
            .store(in: &cancellables)
        
        // Observe playback state changes
        NotificationCenter.default.publisher(for: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"))
            .sink { [weak self] _ in
                print("▶️ Playback state changed")
                self?.fetchNowPlayingInfo()
            }
            .store(in: &cancellables)
        
        // Observe active app changes
        NotificationCenter.default.publisher(for: NSNotification.Name("kMRMediaRemoteNowPlayingApplicationDidChangeNotification"))
            .sink { [weak self] _ in
                print("📱 Now playing app changed")
                self?.fetchNowPlayingInfo()
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicUpdate() {
        // Smooth progress updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
        
        // Periodic info refresh
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchNowPlayingInfo()
        }
    }
    
    private func updateProgress() {
        if duration > 0 {
            let timeSinceAnchor = Date().timeIntervalSince(anchorDate)
            let computedElapsed = anchorElapsedTime + (timeSinceAnchor * playbackRate)
            
            DispatchQueue.main.async {
                self.elapsedTime = min(computedElapsed, self.duration)
                self.progress = min(1.0, max(0.0, self.elapsedTime / self.duration))
            }
        }
    }
    
    // MARK: - Detect Current App
    
    private func detectNowPlayingApp() -> String? {
        let runningApps = NSWorkspace.shared.runningApplications
        
        // Check for Spotify
        if runningApps.contains(where: { $0.bundleIdentifier == "com.spotify.client" }) {
            // Simple check: is Spotify the frontmost app? (not reliable)
            // Better: use MediaRemote to get the actual app
            return "Spotify"
        }
        
        // Check for Apple Music
        if runningApps.contains(where: { $0.bundleIdentifier == "com.apple.Music" }) {
            return "Apple Music"
        }
        
        return nil
    }
    
    // MARK: - Fetch Now Playing Info
    
    func fetchNowPlayingInfo() {
        guard mediaRemote.isLoaded else {
            print("❌ MediaRemote not loaded")
            return
        }
        
        print("🔍 Fetching now playing info...")
        
        mediaRemote.getNowPlayingInfo { [weak self] info in
            guard let self = self else { return }
            
            print("📦 Received dictionary with \(info.count) keys")
            
            // Print all keys and values for debugging
            print("📦 All keys:")
            for (key, value) in info.sorted(by: { $0.key < $1.key }) {
                print("   [\(key)] = \(value)")
            }
            
            DispatchQueue.main.async {
                // Try to detect which app is playing
                if let app = self.detectNowPlayingApp() {
                    self.currentApp = app
                    print("🎼 Current app: \(app)")
                }
                
                // Extract metadata
                self.extractMetadata(from: info)
                self.extractPlaybackInfo(from: info)
                
                print("🎵 Extracted: '\(self.trackTitle)' by '\(self.artistName)'")
                print("💿 Album: '\(self.albumName)'")
                print("▶️ Playing: \(self.isPlaying), Duration: \(self.duration)s")
            }
        }
        
        // Also fetch playing state
        mediaRemote.getIsPlaying { [weak self] playing in
            DispatchQueue.main.async {
                self?.isPlaying = playing
                if !playing {
                    self?.playbackRate = 0
                }
            }
        }
    }
    
    private func extractMetadata(from info: [String: Any]) {
        var foundTitle = false
        var foundArtist = false
        var foundAlbum = false
        var foundArtwork = false
        
        // Search through all keys
        for (key, value) in info {
            let lowercaseKey = key.lowercased()
            
            // Title
            if !foundTitle && lowercaseKey.contains("title") {
                if let title = value as? String, !title.isEmpty {
                    self.trackTitle = title
                    foundTitle = true
                    print("✅ Title: '\(title)' (key: \(key))")
                }
            }
            
            // Artist
            if !foundArtist && lowercaseKey.contains("artist") && !lowercaseKey.contains("album") {
                if let artist = value as? String, !artist.isEmpty {
                    self.artistName = artist
                    foundArtist = true
                    print("✅ Artist: '\(artist)' (key: \(key))")
                }
            }
            
            // Album
            if !foundAlbum && lowercaseKey.contains("album") && !lowercaseKey.contains("artist") {
                if let album = value as? String, !album.isEmpty {
                    self.albumName = album
                    foundAlbum = true
                    print("✅ Album: '\(album)' (key: \(key))")
                }
            }
            
            // Artwork
            if !foundArtwork && lowercaseKey.contains("artwork") {
                if let artworkData = value as? Data, let image = NSImage(data: artworkData) {
                    self.albumArtwork = image
                    foundArtwork = true
                    print("✅ Artwork found (key: \(key))")
                }
            }
        }
        
        // Reset values that weren't found
        if !foundTitle { self.trackTitle = "" }
        if !foundArtist { self.artistName = "" }
        if !foundAlbum { self.albumName = "" }
        if !foundArtwork { self.albumArtwork = nil }
    }
    
    private func extractPlaybackInfo(from info: [String: Any]) {
        // Duration
        for key in ["kMRMediaRemoteNowPlayingInfoDuration", "duration", "Duration"] {
            if let duration = info[key] as? Double, duration > 0 {
                self.duration = duration
                print("✅ Duration: \(duration)s (key: \(key))")
                break
            } else if let duration = info[key] as? NSNumber {
                self.duration = duration.doubleValue
                print("✅ Duration: \(duration)s (key: \(key))")
                break
            }
        }
        
        // Elapsed time
        var elapsed: Double = 0
        for key in ["kMRMediaRemoteNowPlayingInfoElapsedTime", "elapsedTime", "ElapsedTime"] {
            if let time = info[key] as? Double {
                elapsed = time
                print("✅ Elapsed: \(time)s (key: \(key))")
                break
            } else if let time = info[key] as? NSNumber {
                elapsed = time.doubleValue
                print("✅ Elapsed: \(time)s (key: \(key))")
                break
            }
        }
        
        // Playback rate
        var rate: Double = 0
        for key in ["kMRMediaRemoteNowPlayingInfoPlaybackRate", "playbackRate", "PlaybackRate"] {
            if let r = info[key] as? Double {
                rate = r
                print("✅ Rate: \(rate) (key: \(key))")
                break
            } else if let r = info[key] as? NSNumber {
                rate = r.doubleValue
                print("✅ Rate: \(rate) (key: \(key))")
                break
            }
        }
        
        self.playbackRate = rate
        self.isPlaying = rate > 0
        
        // Set anchor point
        self.anchorDate = Date()
        self.anchorElapsedTime = elapsed
        self.elapsedTime = elapsed
        
        if self.duration > 0 {
            self.progress = min(1.0, max(0.0, self.elapsedTime / self.duration))
        }
    }
    
    // MARK: - Playback Controls
    
    func togglePlayPause() {
        mediaRemote.sendCommand(MediaRemoteManager.commandTogglePlayPause)
        DispatchQueue.main.async {
            self.isPlaying.toggle()
            self.playbackRate = self.isPlaying ? 1.0 : 0.0
            self.anchorDate = Date()
            self.anchorElapsedTime = self.elapsedTime
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.fetchNowPlayingInfo()
        }
    }
    
    func play() {
        mediaRemote.sendCommand(MediaRemoteManager.commandPlay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.fetchNowPlayingInfo()
        }
    }
    
    func pause() {
        mediaRemote.sendCommand(MediaRemoteManager.commandPause)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.fetchNowPlayingInfo()
        }
    }
    
    func nextTrack() {
        mediaRemote.sendCommand(MediaRemoteManager.commandNextTrack)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchNowPlayingInfo()
        }
    }
    
    func previousTrack() {
        mediaRemote.sendCommand(MediaRemoteManager.commandPreviousTrack)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchNowPlayingInfo()
        }
    }
    
    func seek(to percentage: Double) {
        guard duration > 0 else { return }
        let targetTime = duration * max(0, min(1, percentage))
        
        DispatchQueue.main.async {
            self.elapsedTime = targetTime
            self.progress = percentage
            self.anchorDate = Date()
            self.anchorElapsedTime = targetTime
        }
        
        mediaRemote.setElapsedTime(targetTime)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchNowPlayingInfo()
        }
    }
}
