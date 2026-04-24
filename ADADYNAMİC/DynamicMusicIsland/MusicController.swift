import Foundation
import AppKit
import Combine

// MARK: - MediaRemote Dynamic Loading
class MediaRemoteManager {
    static let shared = MediaRemoteManager()
    
    private var handle: UnsafeMutableRawPointer?
    
    // Function pointers
    private var MRMediaRemoteGetNowPlayingInfo: (@convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void)?
    private var MRMediaRemoteRegisterForNowPlayingNotifications: (@convention(c) (DispatchQueue) -> Void)?
    private var MRMediaRemoteSendCommand: (@convention(c) (UInt32, [String: Any]?) -> Bool)?
    private var MRMediaRemoteSetElapsedTime: (@convention(c) (Double) -> Void)?
    private var MRMediaRemoteGetNowPlayingApplicationIsPlaying: (@convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void)?
    
    // Media Remote Commands
    static let commandPlay: UInt32 = 0
    static let commandPause: UInt32 = 1
    static let commandTogglePlayPause: UInt32 = 2
    static let commandStop: UInt32 = 3
    static let commandNextTrack: UInt32 = 4
    static let commandPreviousTrack: UInt32 = 5
    static let commandSeekToPosition: UInt32 = 21
    
    // Now Playing Info Keys
    static let kTitle = "kMRMediaRemoteNowPlayingInfoTitle"
    static let kArtist = "kMRMediaRemoteNowPlayingInfoArtist"
    static let kAlbum = "kMRMediaRemoteNowPlayingInfoAlbum"
    static let kArtworkData = "kMRMediaRemoteNowPlayingInfoArtworkData"
    static let kDuration = "kMRMediaRemoteNowPlayingInfoDuration"
    static let kElapsedTime = "kMRMediaRemoteNowPlayingInfoElapsedTime"
    static let kPlaybackRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"
    // NEW: Timestamp key for perfect sync
    static let kTimestamp = "kMRMediaRemoteNowPlayingInfoTimestamp"
    
    var isLoaded: Bool {
        return handle != nil
    }
    
    private init() {
        loadFramework()
    }
    
    private func loadFramework() {
        // Load MediaRemote framework
        let frameworkPath = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
        handle = dlopen(frameworkPath, RTLD_NOW)
        
        guard handle != nil else {
            print("❌ Failed to load MediaRemote framework at path: \(frameworkPath)")
            if let error = dlerror() {
                print("❌ Error: \(String(cString: error))")
            }
            return
        }
        
        print("✅ MediaRemote framework handle obtained")
        
        // Load functions
        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(sym, to: (@convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void).self)
            print("✅ MRMediaRemoteGetNowPlayingInfo loaded")
        } else {
            print("❌ Failed to load MRMediaRemoteGetNowPlayingInfo")
        }
        
        if let sym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
            MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(sym, to: (@convention(c) (DispatchQueue) -> Void).self)
            print("✅ MRMediaRemoteRegisterForNowPlayingNotifications loaded")
        } else {
            print("❌ Failed to load MRMediaRemoteRegisterForNowPlayingNotifications")
        }
        
        if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
            MRMediaRemoteSendCommand = unsafeBitCast(sym, to: (@convention(c) (UInt32, [String: Any]?) -> Bool).self)
            print("✅ MRMediaRemoteSendCommand loaded")
        } else {
            print("❌ Failed to load MRMediaRemoteSendCommand")
        }
        
        if let sym = dlsym(handle, "MRMediaRemoteSetElapsedTime") {
            MRMediaRemoteSetElapsedTime = unsafeBitCast(sym, to: (@convention(c) (Double) -> Void).self)
            print("✅ MRMediaRemoteSetElapsedTime loaded")
        } else {
            print("❌ Failed to load MRMediaRemoteSetElapsedTime")
        }
        
        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
            MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(sym, to: (@convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void).self)
            print("✅ MRMediaRemoteGetNowPlayingApplicationIsPlaying loaded")
        } else {
            print("❌ Failed to load MRMediaRemoteGetNowPlayingApplicationIsPlaying")
        }
        
        print("✅ MediaRemote framework loaded successfully")
    }
    
    func getNowPlayingInfo(completion: @escaping ([String: Any]) -> Void) {
        MRMediaRemoteGetNowPlayingInfo?(DispatchQueue.main, completion)
    }
    
    func getIsPlaying(completion: @escaping (Bool) -> Void) {
        if let fn = MRMediaRemoteGetNowPlayingApplicationIsPlaying {
            fn(DispatchQueue.main, completion)
        } else {
            completion(false)
        }
    }
    
    func registerForNotifications() {
        MRMediaRemoteRegisterForNowPlayingNotifications?(DispatchQueue.main)
    }
    
    @discardableResult
    func sendCommand(_ command: UInt32, options: [String: Any]? = nil) -> Bool {
        return MRMediaRemoteSendCommand?(command, options) ?? false
    }
    
    func setElapsedTime(_ time: Double) {
        MRMediaRemoteSetElapsedTime?(time)
    }
    
    deinit {
        if let handle = handle {
            dlclose(handle)
        }
    }
}

// MARK: - Music Controller
class MusicController: ObservableObject {
    @Published var trackTitle: String = ""
    @Published var artistName: String = ""
    @Published var albumName: String = ""
    @Published var albumArtwork: NSImage?
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var elapsedTime: Double = 0.0
    
    var hasTrack: Bool {
        return !trackTitle.isEmpty
    }
    
    private let mediaRemote = MediaRemoteManager.shared
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Anchor points for strict interpolation
    private var anchorDate: Date = Date()
    private var anchorElapsedTime: Double = 0
    private var playbackRate: Double = 0
    
    init() {
        print("🎛️ MusicController initializing...")
        
        setupNowPlayingObserver()
        startPeriodicUpdate()
        print("⏱️ Starting initial fetch...")
        
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
            print("❌ MediaRemote not loaded, using timer-only updates")
            return
        }
        
        print("✅ MediaRemote framework loaded successfully")
        
        // Register for now playing notifications
        mediaRemote.registerForNotifications()
        print("📡 Registered for now playing notifications")
        
        // Observe now playing info changes
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
                self?.fetchPlayingState()
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicUpdate() {
        // High frequency update for smooth UI (60fps target = 0.016, but 0.05 is sufficient)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
        // Sync check every 2 seconds
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchNowPlayingInfo()
        }
    }
    
    private func updateProgress() {
        // Strictly calculate time based on the anchor point
        // Formula: CurrentTime = AnchorTime + (TimeSinceAnchor * PlaybackRate)
        if duration > 0 {
            let timeSinceAnchor = Date().timeIntervalSince(anchorDate)
            let computedElapsed = anchorElapsedTime + (timeSinceAnchor * playbackRate)
            
            DispatchQueue.main.async {
                self.elapsedTime = min(computedElapsed, self.duration)
                self.progress = min(1.0, max(0.0, self.elapsedTime / self.duration))
            }
        }
    }
    
    private func fetchPlayingState() {
        mediaRemote.getIsPlaying { [weak self] playing in
            DispatchQueue.main.async {
                self?.isPlaying = playing
                // If paused, rate effectively becomes 0 for interpolation logic
                if !playing {
                    self?.playbackRate = 0
                    self?.anchorDate = Date()
                    self?.anchorElapsedTime = self?.elapsedTime ?? 0
                }
            }
        }
    }
    
    // MARK: - Fetch Now Playing Info
    
    func fetchNowPlayingInfo() {
        guard mediaRemote.isLoaded else {
            print("❌ MediaRemote not loaded in fetchNowPlayingInfo")
            return
        }
        
        print("🔍 Fetching now playing info...")
        
        mediaRemote.getNowPlayingInfo { [weak self] info in
            guard let self = self else { return }
            
            print("📦 Received now playing info dictionary with \(info.count) keys")
            
            // Debug: Print ALL key-value pairs with their types
            for (key, value) in info {
                let valueType = type(of: value)
                print("   [\(key)] (\(valueType)): \(value)")
            }
            
            DispatchQueue.main.async {
                var foundTitle = false
                var foundArtist = false
                var foundAlbum = false
                var foundArtwork = false
                
                // Try to extract values by searching for keys that contain certain substrings
                for (key, value) in info {
                    let lowercaseKey = key.lowercased()
                    
                    // Title
                    if !foundTitle && lowercaseKey.contains("title") {
                        if let title = value as? String, !title.isEmpty {
                            self.trackTitle = title
                            foundTitle = true
                            print("✅ Found title at key '\(key)': \(title)")
                        }
                    }
                    
                    // Artist
                    if !foundArtist && lowercaseKey.contains("artist") && !lowercaseKey.contains("album") {
                        if let artist = value as? String, !artist.isEmpty {
                            self.artistName = artist
                            foundArtist = true
                            print("✅ Found artist at key '\(key)': \(artist)")
                        }
                    }
                    
                    // Album
                    if !foundAlbum && lowercaseKey.contains("album") && !lowercaseKey.contains("artist") {
                        if let album = value as? String, !album.isEmpty {
                            self.albumName = album
                            foundAlbum = true
                            print("✅ Found album at key '\(key)': \(album)")
                        }
                    }
                    
                    // Artwork - try multiple types
                    if !foundArtwork && lowercaseKey.contains("artwork") {
                        // Try as Data first
                        if let artworkData = value as? Data {
                            if let image = NSImage(data: artworkData) {
                                self.albumArtwork = image
                                foundArtwork = true
                                print("✅ Found artwork as Data at key '\(key)'")
                            }
                        }
                        // Try as NSImage
                        else if let image = value as? NSImage {
                            self.albumArtwork = image
                            foundArtwork = true
                            print("✅ Found artwork as NSImage at key '\(key)'")
                        }
                        // Try as dictionary with data
                        else if let artworkDict = value as? [String: Any],
                                let imageData = artworkDict["data"] as? Data {
                            if let image = NSImage(data: imageData) {
                                self.albumArtwork = image
                                foundArtwork = true
                                print("✅ Found artwork in dictionary at key '\(key)'")
                            }
                        }
                    }
                }
                
                // If we didn't find values with substring search, try exact key matches
                if !foundTitle {
                    for possibleKey in ["kMRMediaRemoteNowPlayingInfoTitle", "title", "Title"] {
                        if let title = info[possibleKey] as? String, !title.isEmpty {
                            self.trackTitle = title
                            foundTitle = true
                            print("✅ Found title with exact key '\(possibleKey)': \(title)")
                            break
                        }
                    }
                }
                
                if !foundArtist {
                    for possibleKey in ["kMRMediaRemoteNowPlayingInfoArtist", "artist", "Artist"] {
                        if let artist = info[possibleKey] as? String, !artist.isEmpty {
                            self.artistName = artist
                            foundArtist = true
                            print("✅ Found artist with exact key '\(possibleKey)': \(artist)")
                            break
                        }
                    }
                }
                
                if !foundAlbum {
                    for possibleKey in ["kMRMediaRemoteNowPlayingInfoAlbum", "album", "Album"] {
                        if let album = info[possibleKey] as? String, !album.isEmpty {
                            self.albumName = album
                            foundAlbum = true
                            print("✅ Found album with exact key '\(possibleKey)': \(album)")
                            break
                        }
                    }
                }
                
                if !foundArtwork {
                    for possibleKey in ["kMRMediaRemoteNowPlayingInfoArtworkData", "artwork", "Artwork", "artworkData"] {
                        if let artworkData = info[possibleKey] as? Data,
                           let image = NSImage(data: artworkData) {
                            self.albumArtwork = image
                            foundArtwork = true
                            print("✅ Found artwork with exact key '\(possibleKey)'")
                            break
                        }
                    }
                }
                
                print("🎵 Track: '\(self.trackTitle)' by '\(self.artistName)'")
                print("💿 Album: '\(self.albumName)'")
                print("🖼️ Has artwork: \(self.albumArtwork != nil)")
                
                if !foundTitle {
                    print("⚠️ Track title not found")
                    self.trackTitle = ""
                }
                if !foundArtist {
                    print("⚠️ Artist not found")
                    self.artistName = ""
                }
                if !foundAlbum {
                    self.albumName = ""
                }
                if !foundArtwork {
                    self.albumArtwork = nil
                }
                
                // Duration
                if let duration = info[MediaRemoteManager.kDuration] as? Double, duration > 0 {
                    self.duration = duration
                } else if let duration = info[MediaRemoteManager.kDuration] as? NSNumber {
                    self.duration = duration.doubleValue
                }
                
                // Playback Rate
                var rate: Double = 0
                if let r = info[MediaRemoteManager.kPlaybackRate] as? Double {
                    rate = r
                } else if let r = info[MediaRemoteManager.kPlaybackRate] as? NSNumber {
                    rate = r.doubleValue
                }
                self.playbackRate = rate
                self.isPlaying = rate > 0 // Simple inference, refined by fetchPlayingState
                
                // --- SYNC LOGIC ---
                
                // Raw elapsed time from system
                var remoteElapsed: Double = 0
                if let elapsed = info[MediaRemoteManager.kElapsedTime] as? Double {
                    remoteElapsed = elapsed
                } else if let elapsed = info[MediaRemoteManager.kElapsedTime] as? NSNumber {
                    remoteElapsed = elapsed.doubleValue
                }
                
                // Timestamp: The exact time the system calculated that elapsed value
                let timestamp = info[MediaRemoteManager.kTimestamp] as? Date
                
                if let validTimestamp = timestamp {
                    // Perfect Sync: We know exactly when remoteElapsed was valid.
                    // Calculate the drift between THEN and NOW.
                    let timeSinceInfo = Date().timeIntervalSince(validTimestamp)
                    
                    // Set our anchor to NOW, adjusted for the drift
                    self.anchorDate = Date()
                    self.anchorElapsedTime = remoteElapsed + (timeSinceInfo * rate)
                } else {
                    // Fallback: Assume remoteElapsed is valid roughly NOW
                    self.anchorDate = Date()
                    self.anchorElapsedTime = remoteElapsed
                }
                
                // Immediate update to UI
                self.elapsedTime = self.anchorElapsedTime
                if self.duration > 0 {
                    self.progress = min(1.0, max(0.0, self.elapsedTime / self.duration))
                }
                
                // Artwork
                if let artworkData = info[MediaRemoteManager.kArtworkData] as? Data {
                    self.albumArtwork = NSImage(data: artworkData)
                }
            }
        }
        
        fetchPlayingState()
    }
    
    // MARK: - Playback Controls
    
    func togglePlayPause() {
        mediaRemote.sendCommand(MediaRemoteManager.commandTogglePlayPause)
        
        // Optimistic UI update
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
        
        // Update local state immediately
        DispatchQueue.main.async {
            self.elapsedTime = targetTime
            self.progress = percentage
            // Reset anchor to this new time
            self.anchorDate = Date()
            self.anchorElapsedTime = targetTime
        }
        
        mediaRemote.setElapsedTime(targetTime)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchNowPlayingInfo()
        }
    }
}
