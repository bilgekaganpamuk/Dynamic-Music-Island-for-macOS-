import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Fully customizable App Quick Launcher shortcuts widget in the notch.
public struct AppShortcutsWidgetView: View {
    @State private var manager = AppShortcutsManager.shared
    @State private var isDragTargeted: Bool = false
    @State private var showInstalledAppsSheet: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            // Header: Title + Add App & Edit Buttons
            HStack {
                Label(L10n.appShortcuts, systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                // Add App Button (Shows installed apps or opens Finder)
                Button {
                    withAnimation { showInstalledAppsSheet.toggle() }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text(L10n.addApp)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.9))

                // Edit Mode Toggle
                Button {
                    withAnimation { manager.isEditing.toggle() }
                } label: {
                    Text(manager.isEditing ? L10n.done : L10n.edit)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(manager.isEditing ? .blue : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(manager.isEditing ? Color.blue.opacity(0.2) : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Installed Apps Quick Chooser (Inline Drawer)
            if showInstalledAppsSheet {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Installed Apps (Click to Add)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)

                        Spacer()

                        Button("Browse Finder...") {
                            showInstalledAppsSheet = false
                            manager.pickApp()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.blue)

                        Button {
                            withAnimation { showInstalledAppsSheet = false }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(manager.discoveredApplications().prefix(12)) { app in
                                Button {
                                    manager.addApp(from: URL(fileURLWithPath: app.appPath))
                                    withAnimation { showInstalledAppsSheet = false }
                                } label: {
                                    HStack(spacing: 4) {
                                        if let icon = app.customIcon {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .frame(width: 14, height: 14)
                                        }
                                        Text(app.name)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal, 16)
                .transition(.opacity)
            }

            // Horizontal Grid of Active App Shortcuts
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(manager.shortcuts) { app in
                        appButton(for: app)
                    }

                    // Quick Add Placeholder Box
                    Button {
                        withAnimation { showInstalledAppsSheet.toggle() }
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                    .frame(width: 38, height: 38)

                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Text(L10n.add)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 52)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 4)
        .background(isDragTargeted ? Color.blue.opacity(0.15) : Color.clear)
        .onDrop(of: [UTType.fileURL, UTType.item, UTType.data], isTargeted: $isDragTargeted) { providers in
            let urls = FileDropManager.getDroppedURLs(from: providers)
            if !urls.isEmpty {
                for url in urls where url.pathExtension == "app" {
                    manager.addApp(from: url)
                }
            } else {
                Task { @MainActor in
                    let asyncURLs = await FileDropManager.extractURLs(from: providers)
                    for url in asyncURLs where url.pathExtension == "app" {
                        manager.addApp(from: url)
                    }
                }
            }
            return true
        }
    }

    private func appButton(for app: AppShortcutItem) -> some View {
        Button {
            if manager.isEditing {
                withAnimation { manager.removeApp(id: app.id) }
            } else {
                manager.launch(app: app)
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        // High-contrast circular background
                        Circle()
                            .fill(app.color.opacity(0.25))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(app.color.opacity(0.5), lineWidth: 1)
                            )

                        if let customIcon = app.customIcon {
                            Image(nsImage: customIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: app.iconSystemName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(app.color)
                        }
                    }

                    // Delete badge when in Edit mode
                    if manager.isEditing {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .background(Circle().fill(Color.black))
                            .offset(x: 2, y: -2)
                    }
                }

                Text(app.name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
            }
            .frame(width: 52)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open \(app.name)") {
                manager.launch(app: app)
            }
            Divider()
            Button("Remove Shortcut", role: .destructive) {
                manager.removeApp(id: app.id)
            }
        }
    }
}
