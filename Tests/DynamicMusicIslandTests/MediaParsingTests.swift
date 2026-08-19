import XCTest
@testable import DynamicMusicIsland

final class MediaParsingTests: XCTestCase {
    func testAppleMusicTrackParsing() async {
        let mockUserInfo: [AnyHashable: Any] = [
            "Name": "Blinding Lights",
            "Artist": "The Weeknd",
            "Album": "After Hours",
            "Total Time": 200000.0, // 200 seconds in ms
            "Player Position": 45.0,
            "Player State": "Playing"
        ]

        let track = await AppleMusicProvider.shared.parseTrack(from: mockUserInfo)

        XCTAssertEqual(track.title, "Blinding Lights")
        XCTAssertEqual(track.artist, "The Weeknd")
        XCTAssertEqual(track.album, "After Hours")
        XCTAssertEqual(track.duration, 200.0)
        XCTAssertEqual(track.elapsedTime, 45.0)
        XCTAssertTrue(track.isPlaying)
        XCTAssertEqual(track.playerType, .appleMusic)
        XCTAssertEqual(track.formattedDuration, "03:20")
        XCTAssertEqual(track.formattedElapsedTime, "00:45")
    }

    func testSpotifyTrackParsing() async {
        let mockUserInfo: [AnyHashable: Any] = [
            "Name": "Midnight City",
            "Artist": "M83",
            "Album": "Hurry Up, We're Dreaming",
            "Duration": 243.0,
            "Playback Position": 120.0,
            "Player State": "Playing"
        ]

        let track = await SpotifyProvider.shared.parseTrack(from: mockUserInfo)

        XCTAssertEqual(track.title, "Midnight City")
        XCTAssertEqual(track.artist, "M83")
        XCTAssertEqual(track.album, "Hurry Up, We're Dreaming")
        XCTAssertEqual(track.duration, 243.0)
        XCTAssertEqual(track.elapsedTime, 120.0)
        XCTAssertTrue(track.isPlaying)
        XCTAssertEqual(track.playerType, .spotify)
    }

    func testEmptyTrackFormatting() {
        let empty = MediaTrack.empty
        XCTAssertEqual(empty.formattedDuration, "00:00")
        XCTAssertEqual(empty.progress, 0.0)
        XCTAssertFalse(empty.isPlaying)
    }

    func testYouTubeMusicTrackParsing() {
        let rawTitle = "Starboy • The Weeknd - YouTube Music"
        let url = "https://music.youtube.com/watch?v=mock"
        let track = SafariMediaProvider.parseSafariTitle(rawTitle: rawTitle, url: url, isPlaying: true)

        XCTAssertEqual(track.title, "Starboy")
        XCTAssertEqual(track.artist, "The Weeknd")
        XCTAssertEqual(track.playerType, .youtubeMusic)
        XCTAssertTrue(track.isPlaying)
    }

    func testYouTubeVideoParsing() {
        let rawTitle = "Daft Punk - Get Lucky - YouTube"
        let url = "https://youtube.com/watch?v=mock"
        let track = SafariMediaProvider.parseSafariTitle(rawTitle: rawTitle, url: url, isPlaying: true)

        XCTAssertEqual(track.artist, "Daft Punk")
        XCTAssertEqual(track.title, "Get Lucky")
        XCTAssertEqual(track.playerType, .youtubeMusic)
        XCTAssertTrue(track.isPlaying)
    }
}
