import Foundation
import AppKit

/// Helper to request automation permissions for Spotify and Music
class PermissionHelper {
    
    /// Request permission to control Spotify
    static func requestSpotifyPermission() {
        let script = """
        tell application "Spotify"
            get player state
        end tell
        """
        executeAppleScript(script)
    }
    
    /// Request permission to control Music
    static func requestMusicPermission() {
        let script = """
        tell application "Music"
            get player state
        end tell
        """
        executeAppleScript(script)
    }
    
    /// Request all music app permissions
    static func requestAllPermissions() {
        print("🔐 Requesting permissions for Spotify...")
        requestSpotifyPermission()
        
        print("🔐 Requesting permissions for Music...")
        requestMusicPermission()
    }
    
    @discardableResult
    private static func executeAppleScript(_ script: String) -> Bool {
        guard let appleScript = NSAppleScript(source: script) else {
            print("❌ Failed to create AppleScript")
            return false
        }
        
        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)
        
        if let error = error {
            print("⚠️ AppleScript error (this is expected on first run): \(error)")
            return false
        }
        
        print("✅ Permission granted")
        return true
    }
    
    /// Check if Spotify is running
    static func isSpotifyRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
    }
    
    /// Check if Music is running
    static func isMusicRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.Music" }
    }
    
    /// Show an alert explaining permissions
    static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Music Control Permissions Needed"
        alert.informativeText = """
        This app needs permission to read and control music from Spotify and Apple Music.
        
        Steps to grant permission:
        1. Click OK below
        2. You'll see permission dialogs - click "OK" or "Allow"
        3. If no dialogs appear, go to:
           System Settings → Privacy & Security → Automation
        4. Enable this app to control Spotify and/or Music
        
        Then restart the app and play some music!
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            requestAllPermissions()
        }
    }
}
