import Foundation
import AppKit
import Combine

// MARK: - Apple Script Based Music Controller (Fallback)
class EnhancedMusicController: ObservableObject {
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
    
    private var updateTimer: Timer?
    
    init() {
        startPeriodicUpdate()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    private func startPeriodicUpdate() {
        // Update every 0.5 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.fetchNowPlayingInfo()
        }
        
        // Initial fetch
        fetchNowPlayingInfo()
    }
    
    func fetchNowPlayingInfo() {
        // Check which music app is running
        let runningApps = NSWorkspace.shared.runningApplications
        let musicAppRunning = runningApps.contains { app in
            app.bundleIdentifier == "com.apple.Music"
        }
        let spotifyRunning = runningApps.contains { app in
            app.bundleIdentifier == "com.spotify.client"
        }
        
        // Try Spotify first, then Music
        if spotifyRunning {
            fetchSpotifyInfo()
            return
        } else if musicAppRunning {
            fetchAppleMusicInfo()
            return
        } else {
            // No music app running
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
        }
    }
    
    private func fetchSpotifyInfo() {
        let script = """
        tell application "Spotify"
            if player state is not stopped then
                set trackName to name of current track
                set trackArtist to artist of current track
                set trackAlbum to album of current track
                set trackDuration to (duration of current track) / 1000
                set trackPosition to player position
                set isPlaying to (player state is playing)
                
                return trackName & "|" & trackArtist & "|" & trackAlbum & "|" & trackDuration & "|" & trackPosition & "|" & isPlaying
            else
                return ""
            end if
        end tell
        """
        
        processNowPlayingScript(script)
    }
    
    private func fetchAppleMusicInfo() {
        let script = """
        tell application "Music"
            if player state is not stopped then
                set trackName to name of current track
                set trackArtist to artist of current track
                set trackAlbum to album of current track
                set trackDuration to duration of current track
                set trackPosition to player position
                set isPlaying to (player state is playing)
                
                return trackName & "|" & trackArtist & "|" & trackAlbum & "|" & trackDuration & "|" & trackPosition & "|" & isPlaying
            else
                return ""
            end if
        end tell
        """
        
        processNowPlayingScript(script)
    }
    
    private func processNowPlayingScript(_ script: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let result = self?.executeAppleScript(script) else { return }
            
            if result.isEmpty {
                DispatchQueue.main.async {
                    self?.trackTitle = ""
                    self?.artistName = ""
                    self?.albumName = ""
                    self?.albumArtwork = nil
                    self?.isPlaying = false
                    self?.progress = 0.0
                    self?.duration = 0.0
                    self?.elapsedTime = 0.0
                }
                return
            }
            
            let components = result.split(separator: "|").map(String.init)
            
            guard components.count >= 6 else { return }
            
            let title = components[0]
            let artist = components[1]
            let album = components[2]
            let duration = Double(components[3]) ?? 0.0
            let position = Double(components[4]) ?? 0.0
            let playing = components[5] == "true"
            
            DispatchQueue.main.async {
                self?.trackTitle = title
                self?.artistName = artist
                self?.albumName = album
                self?.duration = duration
                self?.elapsedTime = position
                self?.isPlaying = playing
                
                if duration > 0 {
                    self?.progress = min(1.0, max(0.0, position / duration))
                }
                
                // Fetch artwork if track changed
                if self?.trackTitle != title {
                    self?.fetchArtwork()
                }
            }
        }
    }
    
    private func fetchArtwork() {
        // Check which app is running for artwork
        let runningApps = NSWorkspace.shared.runningApplications
        let musicAppRunning = runningApps.contains { app in
            app.bundleIdentifier == "com.apple.Music"
        }
        
        // Only Apple Music supports artwork via AppleScript
        guard musicAppRunning else { return }
        
        let script = """
        tell application "Music"
            if player state is not stopped then
                try
                    set artworkData to data of artwork 1 of current track
                    return artworkData
                on error
                    return missing value
                end try
            else
                return missing value
            end if
        end tell
        """
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                let descriptor = appleScript.executeAndReturnError(&error)
                
                if error == nil, descriptor.data != nil {
                    let data = descriptor.data
                    if let image = NSImage(data: data) {
                        DispatchQueue.main.async {
                            self?.albumArtwork = image
                        }
                    }
                }
            }
        }
    }
    
    private func executeAppleScript(_ script: String) -> String {
        guard let appleScript = NSAppleScript(source: script) else {
            return ""
        }
        
        var error: NSDictionary?
        let descriptor = appleScript.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript error: \(error)")
            return ""
        }
        
        return descriptor.stringValue ?? ""
    }
    
    // MARK: - Playback Controls
    
    func togglePlayPause() {
        // Determine which app to control
        let runningApps = NSWorkspace.shared.runningApplications
        let spotifyRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
        let musicAppRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
        
        if spotifyRunning {
            executeSimpleCommand("playpause", forApp: "Spotify")
        } else if musicAppRunning {
            executeSimpleCommand("playpause", forApp: "Music")
        }
    }
    
    func play() {
        let runningApps = NSWorkspace.shared.runningApplications
        let spotifyRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
        let musicAppRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
        
        if spotifyRunning {
            executeSimpleCommand("play", forApp: "Spotify")
        } else if musicAppRunning {
            executeSimpleCommand("play", forApp: "Music")
        }
    }
    
    func pause() {
        let runningApps = NSWorkspace.shared.runningApplications
        let spotifyRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
        let musicAppRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
        
        if spotifyRunning {
            executeSimpleCommand("pause", forApp: "Spotify")
        } else if musicAppRunning {
            executeSimpleCommand("pause", forApp: "Music")
        }
    }
    
    func nextTrack() {
        let runningApps = NSWorkspace.shared.runningApplications
        let spotifyRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
        let musicAppRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
        
        if spotifyRunning {
            executeSimpleCommand("next track", forApp: "Spotify")
        } else if musicAppRunning {
            executeSimpleCommand("next track", forApp: "Music")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchNowPlayingInfo()
        }
    }
    
    func previousTrack() {
        let runningApps = NSWorkspace.shared.runningApplications
        let spotifyRunning = runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
        let musicAppRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
        
        if spotifyRunning {
            executeSimpleCommand("previous track", forApp: "Spotify")
        } else if musicAppRunning {
            executeSimpleCommand("previous track", forApp: "Music")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.fetchNowPlayingInfo()
        }
    }
    
    func seek(to percentage: Double) {
        guard duration > 0 else { return }
        let targetTime = duration * max(0, min(1, percentage))
        
        // Only Music app supports seeking via AppleScript
        let runningApps = NSWorkspace.shared.runningApplications
        let musicAppRunning = runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
        
        guard musicAppRunning else { return }
        
        let script = """
        tell application "Music"
            set player position to \(targetTime)
        end tell
        """
        
        DispatchQueue.main.async {
            self.elapsedTime = targetTime
            self.progress = percentage
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.executeAppleScript(script)
        }
    }
    
    private func executeSimpleCommand(_ command: String, forApp appName: String) {
        let script = """
        tell application "\(appName)"
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
