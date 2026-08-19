import Cocoa
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static var shared: AppDelegate?

    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupMenuBar()
        IslandWindowController.shared.showIsland()

        // Show onboarding on first launch or if permissions not configured
        if !UserDefaults.standard.bool(forKey: "HasCompletedOnboarding") {
            showOnboarding()
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.and.person.filled", accessibilityDescription: "Dynamic Music Island")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Dynamic Music Island", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let loadDemoItem = NSMenuItem(title: "Load Demo Track", action: #selector(loadDemoAction), keyEquivalent: "d")
        loadDemoItem.target = self
        menu.addItem(loadDemoItem)

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let onboardingItem = NSMenuItem(title: "Setup & Permissions...", action: #selector(openOnboardingAction), keyEquivalent: "")
        onboardingItem.target = self
        menu.addItem(onboardingItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Dynamic Music Island", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func loadDemoAction() {
        MediaManager.shared.loadDemoTrack()
    }

    @objc private func openSettingsAction() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Dynamic Music Island Settings"
            window.level = .floating
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView())

            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    if self?.onboardingWindow?.isVisible != true {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
            }
            self.settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.orderFrontRegardless()
    }

    @objc private func openOnboardingAction() {
        showOnboarding()
    }

    public func showOnboarding() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if onboardingWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Welcome to Dynamic Music Island"
            window.level = .floating
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(
                rootView: OnboardingView { [weak self] in
                    UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
                    self?.onboardingWindow?.close()
                }
            )

            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    if self?.settingsWindow?.isVisible != true {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
            }
            self.onboardingWindow = window
        }
        onboardingWindow?.makeKeyAndOrderFront(nil)
        onboardingWindow?.orderFrontRegardless()
    }

    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}
