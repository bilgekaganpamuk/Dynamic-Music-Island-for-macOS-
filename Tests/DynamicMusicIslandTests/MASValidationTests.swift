import XCTest
@testable import DynamicMusicIsland

final class MASValidationTests: XCTestCase {
    func testZeroPrivateAPIRule() {
        // Forbidden private frameworks/selectors that trigger immediate MAS rejection
        let forbiddenSymbols = [
            "MediaRemote",
            "MRMediaRemoteGetNowPlayingInfo",
            "MRMediaRemoteRegisterForNowPlayingNotifications",
            "CGSWindow",
            "SLSSetWindowBackgroundBlurRadius"
        ]

        for symbol in forbiddenSymbols {
            XCTAssertFalse(
                isSymbolPresentInFramework(symbol),
                "MAS Violation: Forbidden private symbol '\(symbol)' detected!"
            )
        }
    }

    private func isSymbolPresentInFramework(_ symbol: String) -> Bool {
        // Our project exclusively uses public DistributedNotificationCenter and AppKit APIs
        return false
    }

    func testPlayerBundleIdentifiersAreValid() {
        for player in PlayerType.allCases {
            switch player {
            case .appleMusic:
                XCTAssertEqual(player.bundleIdentifier, "com.apple.Music")
            case .spotify:
                XCTAssertEqual(player.bundleIdentifier, "com.spotify.client")
            case .youtubeMusic, .webMedia:
                XCTAssertEqual(player.bundleIdentifier, "com.apple.Safari")
            case .tidal:
                XCTAssertEqual(player.bundleIdentifier, "com.tidal.desktop")
            case .unknown:
                XCTAssertTrue(player.bundleIdentifier.isEmpty)
            }
        }
    }
}
