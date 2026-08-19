import SwiftUI
import UniformTypeIdentifiers

/// Notch file shelf supporting Drag & Drop file staging, dragging out to other apps, and instant AirDrop sharing.
public struct NotchTrayView: View {
    @State private var fileDropManager = FileDropManager.shared
    @State private var isShelfDropTargeted: Bool = false
    @State private var isAirDropTargeted: Bool = false

    public init() {}

    public var body: some View {
        HStack(spacing: 12) {
            // Main File Shelf Area (Left & Center)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Label(L10n.filesInShelf(count: fileDropManager.items.count), systemImage: "tray.full.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    // Quick Add File button via Finder picker
                    Button {
                        fileDropManager.pickFiles()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                            Text(L10n.add)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white.opacity(0.9))

                    if !fileDropManager.items.isEmpty {
                        Button(L10n.clear) {
                            withAnimation { fileDropManager.clearAll() }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red.opacity(0.85))
                    }
                }

                // File Items Container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isShelfDropTargeted ? Color.blue.opacity(0.2) : Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isShelfDropTargeted ? Color.blue : Color.white.opacity(0.18),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 5])
                                )
                        )

                    if fileDropManager.items.isEmpty {
                        VStack(spacing: 4) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 22))
                                .foregroundColor(isShelfDropTargeted ? .blue : .secondary)

                            Text(isShelfDropTargeted ? L10n.dropFilesHere : L10n.shelfDragHint)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(.vertical, 14)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(fileDropManager.items) { item in
                                    fileCard(for: item)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .frame(height: 88)
                .onDrop(of: [UTType.fileURL, UTType.item, UTType.data], isTargeted: $isShelfDropTargeted) { providers in
                    handleShelfDrop(providers: providers)
                }
            }

            // AirDrop Instant Target Station (Right Side)
            VStack(spacing: 5) {
                Text(L10n.airDrop)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Button {
                    let urls = fileDropManager.items.map { $0.url }
                    if !urls.isEmpty {
                        fileDropManager.triggerAirDrop(for: urls)
                    } else {
                        fileDropManager.pickFilesAndAirDrop()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isAirDropTargeted ? Color.blue.opacity(0.35) : Color.white.opacity(0.08))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        isAirDropTargeted ? Color.blue : Color.white.opacity(0.2),
                                        style: StrokeStyle(lineWidth: 1.5, dash: isAirDropTargeted ? [4, 4] : [])
                                    )
                            )

                        VStack(spacing: 2) {
                            Image(systemName: fileDropManager.showAirDropFeedback ? "checkmark.circle.fill" : "airdrop")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(fileDropManager.showAirDropFeedback ? .green : (isAirDropTargeted ? .blue : .white))

                            Text(fileDropManager.showAirDropFeedback ? "Sent!" : L10n.dropToSend)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(fileDropManager.showAirDropFeedback ? .green : .secondary)
                                .lineLimit(1)
                        }
                    }
                    .contentShape(Circle())
                    .onDrop(of: [UTType.fileURL, UTType.item, UTType.data], isTargeted: $isAirDropTargeted) { providers in
                        handleAirDropDrop(providers: providers)
                    }
                }
                .buttonStyle(.plain)
                .help(L10n.airDropHelp)
            }
            .frame(width: 80)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - File Card with Drag-Out Support
    private func fileCard(for item: DroppedFileItem) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)

                // Delete Button
                Button {
                    withAnimation { fileDropManager.removeItem(id: item.id) }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                        .background(Circle().fill(Color.black))
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }

            Text(item.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 58)

            Text(item.fileSizeString)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(6)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onDrag {
            // Allows dragging item out of notch to Finder, Slack, Discord, Chrome, etc.
            NSItemProvider(object: item.url as NSURL)
        }
        .contextMenu {
            Button(L10n.revealInFinder) {
                fileDropManager.revealInFinder(url: item.url)
            }
            Button(L10n.sendViaAirDrop) {
                fileDropManager.triggerAirDrop(for: [item.url])
            }
            Divider()
            Button(L10n.removeFromShelf, role: .destructive) {
                fileDropManager.removeItem(id: item.id)
            }
        }
    }

    // MARK: - Drop Handling
    private func handleShelfDrop(providers: [NSItemProvider]) -> Bool {
        let syncURLs = FileDropManager.getDroppedURLs(from: providers)
        if !syncURLs.isEmpty {
            withAnimation {
                fileDropManager.addFiles(from: syncURLs)
            }
            return true
        }

        Task { @MainActor in
            let urls = await FileDropManager.extractURLs(from: providers)
            if !urls.isEmpty {
                withAnimation {
                    fileDropManager.addFiles(from: urls)
                }
            }
        }
        return true
    }

    private func handleAirDropDrop(providers: [NSItemProvider]) -> Bool {
        let syncURLs = FileDropManager.getDroppedURLs(from: providers)
        if !syncURLs.isEmpty {
            // Delay slightly to let the drag session finish before showing the AirDrop popover
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                fileDropManager.triggerAirDrop(for: syncURLs)
            }
            return true
        }

        Task { @MainActor in
            let urls = await FileDropManager.extractURLs(from: providers)
            if !urls.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    fileDropManager.triggerAirDrop(for: urls)
                }
            }
        }
        return true
    }
}
