import Foundation
import SwiftUI
import Observation
import AppKit

/// Central media manager coordinating player providers, state updates, and zero-polling energy efficiency.
@Observable
@MainActor
public final class MediaManager {
    public static let shared = MediaManager()

    public var currentTrack: MediaTrack = .empty
    public var activePlayer: PlayerType = .unknown
    public var isIslandVisible: Bool = false
    public var currentVolume: Double = 75.0

    private var tickerTask: Task<Void, Never>?

    public init() {
        setupObservers()
        refreshCurrentState()
    }

    /// Initializes provider listeners and system app launch observers
    public func setupObservers() {
        AppleMusicProvider.shared.startObserving { [weak self] track in
            self?.handleTrackUpdate(track, from: .appleMusic)
        }

        SpotifyProvider.shared.startObserving { [weak self] track in
            self?.handleTrackUpdate(track, from: .spotify)
        }

        SafariMediaProvider.shared.startObserving { [weak self] track in
            self?.handleTrackUpdate(track, from: track.playerType)
        }

        // Detect when Spotify, Music, or Safari launches or quits
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshCurrentState()
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshCurrentState()
            }
        }
    }

    /// Actively checks currently running players on app launch so already-open music is instantly recognized
    public func refreshCurrentState() {
        Task { @MainActor in
            if SpotifyProvider.shared.isRunning {
                if let track = await SpotifyProvider.shared.fetchCurrentTrack() {
                    self.handleTrackUpdate(track, from: .spotify)
                    return
                }
            }

            if AppleMusicProvider.shared.isRunning {
                if let track = await AppleMusicProvider.shared.fetchCurrentTrack() {
                    self.handleTrackUpdate(track, from: .appleMusic)
                    return
                }
            }

            if SafariMediaProvider.shared.isRunning {
                if let track = await SafariMediaProvider.shared.fetchCurrentTrack() {
                    self.handleTrackUpdate(track, from: track.playerType)
                    return
                }
            }
        }
    }

    /// Processes track updates from any provider
    public func handleTrackUpdate(_ track: MediaTrack, from player: PlayerType) {
        // If current player is paused and a different player starts playing, switch active player
        if track.isPlaying || self.activePlayer == player || self.activePlayer == .unknown {
            self.currentTrack = track
            self.activePlayer = player
            self.isIslandVisible = track.isPlaying || !track.title.isEmpty

            if track.isPlaying {
                startProgressTicker()
            } else {
                stopProgressTicker()
            }
        }
    }

    // MARK: - Zero-Polling Energy-Efficient Progress Ticker
    private func startProgressTicker() {
        stopProgressTicker()
        tickerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self, self.currentTrack.isPlaying else { break }
                if self.currentTrack.elapsedTime < self.currentTrack.duration {
                    self.currentTrack.elapsedTime += 1.0
                }
            }
        }
    }

    private func stopProgressTicker() {
        tickerTask?.cancel()
        tickerTask = nil
    }

    // MARK: - Playback Controls
    public func playPause() {
        switch activePlayer {
        case .spotify:
            SpotifyProvider.shared.playPause()
        case .appleMusic:
            AppleMusicProvider.shared.playPause()
        case .youtubeMusic, .webMedia:
            SafariMediaProvider.shared.playPause()
        case .tidal, .unknown:
            if SpotifyProvider.shared.isRunning {
                activePlayer = .spotify
                SpotifyProvider.shared.playPause()
            } else if AppleMusicProvider.shared.isRunning {
                activePlayer = .appleMusic
                AppleMusicProvider.shared.playPause()
            } else if SafariMediaProvider.shared.isRunning {
                activePlayer = .youtubeMusic
                SafariMediaProvider.shared.playPause()
            }
        }

        // Check state after a brief delay if starting from stopped
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            self.refreshCurrentState()
        }
    }

    public func nextTrack() {
        switch activePlayer {
        case .appleMusic:
            AppleMusicProvider.shared.nextTrack()
        case .spotify:
            SpotifyProvider.shared.nextTrack()
        case .youtubeMusic, .webMedia:
            SafariMediaProvider.shared.nextTrack()
        default:
            if SpotifyProvider.shared.isRunning {
                SpotifyProvider.shared.nextTrack()
            } else if AppleMusicProvider.shared.isRunning {
                AppleMusicProvider.shared.nextTrack()
            } else if SafariMediaProvider.shared.isRunning {
                SafariMediaProvider.shared.nextTrack()
            }
        }
    }

    public func previousTrack() {
        switch activePlayer {
        case .appleMusic:
            AppleMusicProvider.shared.previousTrack()
        case .spotify:
            SpotifyProvider.shared.previousTrack()
        case .youtubeMusic, .webMedia:
            SafariMediaProvider.shared.previousTrack()
        default:
            if SpotifyProvider.shared.isRunning {
                SpotifyProvider.shared.previousTrack()
            } else if AppleMusicProvider.shared.isRunning {
                AppleMusicProvider.shared.previousTrack()
            } else if SafariMediaProvider.shared.isRunning {
                SafariMediaProvider.shared.previousTrack()
            }
        }
    }

    public func seek(to time: TimeInterval) {
        currentTrack.elapsedTime = time
        switch activePlayer {
        case .appleMusic:
            AppleMusicProvider.shared.seek(to: time)
        case .spotify:
            SpotifyProvider.shared.seek(to: time)
        default:
            if SpotifyProvider.shared.isRunning {
                SpotifyProvider.shared.seek(to: time)
            } else {
                AppleMusicProvider.shared.seek(to: time)
            }
        }
    }

    public func setVolume(_ volume: Double) {
        currentVolume = volume
        let intVol = Int(volume)
        switch activePlayer {
        case .appleMusic:
            AppleMusicProvider.shared.setVolume(intVol)
        case .spotify:
            SpotifyProvider.shared.setVolume(intVol)
        default:
            if SpotifyProvider.shared.isRunning {
                SpotifyProvider.shared.setVolume(intVol)
            } else {
                AppleMusicProvider.shared.setVolume(intVol)
            }
        }
    }

    // MARK: - Showcase / Demo Track Injection
    public func loadDemoTrack() {
        currentTrack = MediaTrack(
            title: "Lose Control",
            artist: "Teddy Swims",
            album: "I've Tried Everything But Therapy",
            duration: 211,
            elapsedTime: 78,
            isPlaying: true,
            playerType: .spotify,
            artwork: nil,
            accentColor: Color(red: 0.95, green: 0.55, blue: 0.2),
            secondaryColor: Color(red: 0.3, green: 0.1, blue: 0.5).opacity(0.6)
        )
        activePlayer = .spotify
        isIslandVisible = true
        startProgressTicker()
    }
}
