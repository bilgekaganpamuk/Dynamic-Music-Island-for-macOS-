import SwiftUI

/// Elegant 3-step onboarding wizard introducing features and requesting automation permissions.
public struct OnboardingView: View {
    @State private var currentStep: Int = 1
    @State private var permissionManager = PermissionManager.shared
    public let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Header Logo & Title
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.pink, Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: "waveform.and.person.filled")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Dynamic Music Island")
                    .font(.system(size: 22, weight: .bold))

                Text("The liquid notch music experience for macOS")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Divider()

            // Step Content
            if currentStep == 1 {
                welcomeStep
            } else if currentStep == 2 {
                permissionsStep
            } else {
                readyStep
            }

            Spacer()

            // Navigation Buttons
            HStack {
                if currentStep > 1 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Button(currentStep == 3 ? "Get Started" : "Continue") {
                    if currentStep < 3 {
                        withAnimation { currentStep += 1 }
                    } else {
                        onComplete()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(28)
        .frame(width: 480, height: 420)
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow))
    }

    // MARK: - Step 1: Welcome
    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            featureRow(
                icon: "sparkles",
                color: .pink,
                title: "Liquid Notch Dynamics",
                subtitle: "Hugs your MacBook notch with 120Hz ProMotion fluid physics and ambient album colors."
            )

            featureRow(
                icon: "music.note.list",
                color: .green,
                title: "Seamless Media Control",
                subtitle: "Interactive controls, scrubbing, and volume for Apple Music and Spotify."
            )

            featureRow(
                icon: "leaf.fill",
                color: .emeraldAccent,
                title: "Zero-Polling & Ultra Light",
                subtitle: "Zero CPU usage in background. 100% App Store sandbox and privacy compliant."
            )
        }
    }

    // MARK: - Step 2: Permissions
    private var permissionsStep: some View {
        VStack(spacing: 16) {
            Text("Enable Player Automation")
                .font(.system(size: 15, weight: .semibold))

            Text("macOS requires automation permission so Dynamic Island can read track info and control playback.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                permissionRow(
                    player: .appleMusic,
                    title: "Apple Music Automation",
                    isGranted: permissionManager.isMusicPermissionGranted
                ) {
                    permissionManager.requestPermission(for: .appleMusic)
                }

                permissionRow(
                    player: .spotify,
                    title: "Spotify Automation",
                    isGranted: permissionManager.isSpotifyPermissionGranted
                ) {
                    permissionManager.requestPermission(for: .spotify)
                }
            }
            .padding(12)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Step 3: Ready
    private var readyStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.green)

            Text("You're All Set!")
                .font(.system(size: 18, weight: .bold))

            Text("Play any track in Apple Music or Spotify, or click 'Try Demo' to test the island immediately.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Load Showcase Demo Track") {
                MediaManager.shared.loadDemoTrack()
            }
            .buttonStyle(.bordered)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func permissionRow(player: PlayerType, title: String, isGranted: Bool, onRequest: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: player.iconName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(player.brandColor)

            Text(title)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            if isGranted {
                Label("Allowed", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
            } else {
                Button("Allow") {
                    onRequest()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
}

extension Color {
    static let emeraldAccent = Color(red: 0.15, green: 0.78, blue: 0.45)
}

/// VisualEffectBlur bridge for macOS window styling
public struct VisualEffectBlur: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
