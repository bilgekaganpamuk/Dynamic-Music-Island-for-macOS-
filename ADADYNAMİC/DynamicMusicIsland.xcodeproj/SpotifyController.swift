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
    
    var hasTrack: Bool {
        return !trackTitle.isEmpty
    }
    
    private var updateTimer: Timer?
    private var lastTrackId: String = ""
    
    public init() {
        print("🎧 SpotifyController initializing...")
        startPeriodicUpdate()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    private func startPeriodicUpdate() {
        // Update every 0.5 seconds for smooth progress
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.fetchNowPlayingInfo()
        }
        
        // Initial fetch
        fetchNowPlayingInfo()
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
                
                return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & trackDuration & "|||" & trackPosition & "|||" & isPlaying & "|||" & trackId
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
            
            guard components.count >= 7 else {
                print("⚠️ Unexpected response format: \(result)")
                return
            }
            
            let title = components[0]
            let artist = components[1]
            let album = components[2]
            let durationMs = Double(components[3]) ?? 0.0
            let positionSec = Double(components[4]) ?? 0.0
            let playing = components[5] == "true"
            let trackId = components[6]
            
            // Convert duration from milliseconds to seconds
            let duration = durationMs / 1000.0
            
            DispatchQueue.main.async {
                self.trackTitle = title
                self.artistName = artist
                self.albumName = album
                self.duration = duration
                self.elapsedTime = positionSec
                self.isPlaying = playing
                
                if duration > 0 {
                    self.progress = min(1.0, max(0.0, positionSec / duration))
                }
                
                print("🎧 Spotify: '\(title)' by '\(artist)' - \(playing ? "Playing" : "Paused")")
                
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
            
            // Download the artwork
            guard let url = URL(string: urlString) else {
                print("⚠️ Invalid artwork URL: \(urlString)")
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                if let image = NSImage(data: data) {
                    DispatchQueue.main.async {
                        self.albumArtwork = image
                        print("✅ Artwork loaded")
                    }
                }
            } catch {
                print("⚠️ Failed to load artwork: \(error)")
            }
        }
    }
    
    private func executeAppleScript(_ script: String) -> String? {
        guard let appleScript = NSAppleScript(source: script) else {
            print("❌ Failed to create AppleScript")
            return nil
        }
        
        var error: NSDictionary?
        let descriptor = appleScript.executeAndReturnError(&error)
        
        if let error = error {
            print("❌ AppleScript error: \(error)")
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
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.executeAppleScript(script)
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
