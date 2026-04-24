import SwiftUI
import AppKit

@main
struct DynamicMusicIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// Custom window class that can control dragging behavior
class NonDraggableWindow: NSWindow {
    var shouldAllowDragging = true
    
    override var isMovableByWindowBackground: Bool {
        get { shouldAllowDragging }
        set { }
    }
    
    // Prevent window from being moved when shouldAllowDragging is false
    override func mouseDown(with event: NSEvent) {
        if !shouldAllowDragging {
            // Don't call super, this prevents the window from being dragged
            return
        }
        super.mouseDown(with: event)
    }
}

// 1. Conform to NSWindowDelegate to detect moves
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var floatingWindow: NonDraggableWindow?
    var statusItem: NSStatusItem?
    var clickMonitor: Any?
    var isDropZoneVisible = false  // Track drop zone visibility
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusBar()
        setupFloatingWindow()
        setupClickOutsideHandler()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResizeNotification(_:)),
            name: NSNotification.Name("RecenterWindow"), // We keep the name but change logic
            object: nil
        )
        
        // Listen for drop zone visibility changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDropZoneVisibility(_:)),
            name: NSNotification.Name("ShowDropZone"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDropZoneHidden(_:)),
            name: NSNotification.Name("HideDropZone"),
            object: nil
        )
        
        // Request permissions after a short delay to let the UI settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestPermissionsIfNeeded()
        }
    }
    
    func requestPermissionsIfNeeded() {
        // Check if we've already requested permissions
        let hasRequestedPermissions = UserDefaults.standard.bool(forKey: "hasRequestedMusicPermissions")
        
        if !hasRequestedPermissions {
            print("🔐 First launch - requesting permissions...")
            PermissionHelper.showPermissionAlert()
            UserDefaults.standard.set(true, forKey: "hasRequestedMusicPermissions")
        } else {
            // Silently request permissions in the background (won't show dialog if already granted)
            PermissionHelper.requestAllPermissions()
        }
    }
    
    func setupClickOutsideHandler() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.checkClickOutside()
        }
        
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            if event.window != self?.floatingWindow {
                self?.checkClickOutside()
            }
            return event
        }
    }
    
    func checkClickOutside() {
        guard let window = floatingWindow else { return }
        
        // Don't collapse if drop zone is visible
        if isDropZoneVisible {
            return
        }
        
        let mouseLocation = NSEvent.mouseLocation
        if !window.frame.contains(mouseLocation) {
            NotificationCenter.default.post(name: NSNotification.Name("CollapseIsland"), object: nil)
        }
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music Island")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Island", action: #selector(showIsland), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Hide Island", action: #selector(hideIsland), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Show Drop Zone", action: #selector(showDropZone), keyEquivalent: "d"))
        menu.addItem(NSMenuItem(title: "Reset Position", action: #selector(resetPosition), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Request Permissions...", action: #selector(requestPermissions), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    func setupFloatingWindow() {
        let contentView = IslandContentView()
        
        floatingWindow = NonDraggableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 36),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        floatingWindow?.isOpaque = false
        floatingWindow?.backgroundColor = .clear
        floatingWindow?.level = .floating
        floatingWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        floatingWindow?.hasShadow = false
        floatingWindow?.contentView = NSHostingView(rootView: contentView)
        
        // Enable drag and drop by registering file URL types
        floatingWindow?.registerForDraggedTypes([.fileURL, .URL, .png, .tiff])
        
        // 2. Set Delegate to self to listen for moves
        floatingWindow?.delegate = self
        
        // 3. Restore position from UserDefaults or default to center
        restoreWindowPosition(width: 200, height: 36)
        
        floatingWindow?.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - Window Positioning Logic
    
    func restoreWindowPosition(width: CGFloat, height: CGFloat) {
        guard let window = floatingWindow else { return }
        
        if let savedString = UserDefaults.standard.string(forKey: "islandTopCenter"),
           let savedPoint = NSPointFromString(savedString) as NSPoint? {
            
            // Calculate Origin based on saved Top-Center point
            let x = savedPoint.x - (width / 2)
            let y = savedPoint.y - height
            window.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
            
        } else {
            // First run: Center on screen
            centerWindowOnScreen(width: width, height: height)
        }
    }
    
    func centerWindowOnScreen(width: CGFloat, height: CGFloat) {
        guard let screen = NSScreen.main, let window = floatingWindow else { return }
        let screenFrame = screen.frame
        let x = (screenFrame.width - width) / 2 + screenFrame.origin.x
        let y = screenFrame.maxY - height - 10
        window.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true, animate: true)
        
        // Save this initial default position
        saveWindowPosition()
    }

    // 4. Handle window resizing (expanding/collapsing) relative to ITSELF
    @objc func handleResizeNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let width = userInfo["width"] as? CGFloat,
              let height = userInfo["height"] as? CGFloat,
              let window = floatingWindow else { return }
        
        // Get CURRENT window top-center
        let currentFrame = window.frame
        let currentTopCenter = NSPoint(x: currentFrame.midX, y: currentFrame.maxY)
        
        // Calculate NEW origin to keep Top-Center constant
        let newX = currentTopCenter.x - (width / 2)
        let newY = currentTopCenter.y - height
        
        DispatchQueue.main.async {
            window.setFrame(NSRect(x: newX, y: newY, width: width, height: height), display: true, animate: true)
        }
    }
    
    // 5. Detect when user moves the window manually
    func windowDidMove(_ notification: Notification) {
        saveWindowPosition()
    }
    
    // 6. Handle drop zone visibility
    @objc func handleDropZoneVisibility(_ notification: Notification) {
        // Completely disable window dragging when drop zone is visible
        isDropZoneVisible = true
        floatingWindow?.shouldAllowDragging = false
    }
    
    @objc func handleDropZoneHidden(_ notification: Notification) {
        // Re-enable window dragging when drop zone is hidden
        isDropZoneVisible = false
        floatingWindow?.shouldAllowDragging = true
    }
    
    func saveWindowPosition() {
        guard let window = floatingWindow else { return }
        // We save the Top-Center point because width/height changes dynamically.
        // If we saved just x/y (bottom-left), expanding the window would shift it visually.
        let topCenter = NSPoint(x: window.frame.midX, y: window.frame.maxY)
        UserDefaults.standard.set(NSStringFromPoint(topCenter), forKey: "islandTopCenter")
    }

    // MARK: - Actions
    
    @objc func showIsland() {
        floatingWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc func hideIsland() {
        floatingWindow?.orderOut(nil)
    }
    
    @objc func showDropZone() {
        NotificationCenter.default.post(name: NSNotification.Name("ShowDropZone"), object: nil)
    }
    
    @objc func resetPosition() {
        // Option to reset if it gets lost
        UserDefaults.standard.removeObject(forKey: "islandTopCenter")
        
        // Default to collapsed size
        let width: CGFloat = 200
        let height: CGFloat = 36
        
        // Force reset
        centerWindowOnScreen(width: width, height: height)
        
        // Notify SwiftUI to reset state if needed (optional)
        NotificationCenter.default.post(name: NSNotification.Name("CollapseIsland"), object: nil)
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    @objc func requestPermissions() {
        PermissionHelper.showPermissionAlert()
    }
}
