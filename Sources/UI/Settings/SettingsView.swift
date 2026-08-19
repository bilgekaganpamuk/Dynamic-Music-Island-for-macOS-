import SwiftUI

/// Modern macOS Settings window covering appearance, notch physics, display behavior, and developer portfolio credits.
public struct SettingsView: View {
    @AppStorage(Constants.Defaults.launchAtLoginKey) private var launchAtLogin: Bool = true
    @AppStorage(Constants.Defaults.autoExpandOnTrackChangeKey) private var autoExpand: Bool = true
    @AppStorage(Constants.Defaults.proMotionEnabledKey) private var proMotionEnabled: Bool = true
    @AppStorage(Constants.Defaults.selectedThemeKey) private var selectedTheme: String = "adaptive"

    public init() {}

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }

            displayTab
                .tabItem {
                    Label("Display", systemImage: "display.2")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
        }
        .frame(width: 480, height: 320)
        .padding(20)
    }

    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Auto-expand Island briefly on track change", isOn: $autoExpand)
            } header: {
                Text("Startup & Behavior")
            }

            Section {
                Button("Test Permissions & Setup Wizard") {
                    // Open onboarding
                }
                Button("Load Demo Track (Test Island)") {
                    MediaManager.shared.loadDemoTrack()
                }
            } header: {
                Text("Diagnostics & Test")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Appearance Tab
    private var appearanceTab: some View {
        Form {
            Section {
                Picker("Island Theme", selection: $selectedTheme) {
                    Text("Adaptive Album Ambient Glow").tag("adaptive")
                    Text("Onyx Pure Black").tag("black")
                    Text("Frost Glassmorphism").tag("glass")
                }

                Toggle("120Hz ProMotion Fluid Springs", isOn: $proMotionEnabled)
            } header: {
                Text("Visual Style & Fluidity")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Display Tab
    private var displayTab: some View {
        Form {
            Section {
                Text("Hardware Notch: \(ScreenObserver.shared.currentGeometry.hasHardwareNotch ? "Detected (MacBook Notch Mode)" : "None (Floating Pill Mode)")")
                    .font(.system(size: 13, weight: .medium))

                Text("External Monitors automatically switch to floating pill overlay.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } header: {
                Text("Screen Detection")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - About & Portfolio Tab
    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 36))
                .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Dynamic Music Island for macOS")
                .font(.system(size: 16, weight: .bold))

            Text("Version 1.0.0 • Portfolio Edition")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text("Crafted with Swift 6, SwiftUI & AppKit by Bilge Kağan Pamuk.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)

            Divider()

            HStack(spacing: 16) {
                Link("GitHub Repository", destination: URL(string: "https://github.com/bilgekaganpamuk")!)
                Link("Developer Portfolio", destination: URL(string: "https://bilgekagan.dev")!)
            }
            .font(.system(size: 12, weight: .semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
