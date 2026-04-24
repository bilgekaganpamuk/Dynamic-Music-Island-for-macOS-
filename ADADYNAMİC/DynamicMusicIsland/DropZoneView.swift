import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var stashManager: FileStashManager
    
    @State private var isTargetingAirDrop = false
    @State private var isTargetingStash = false
    
    private let islandCornerRadius: CGFloat = 32
    private let innerCornerRadius: CGFloat = 20
    
    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button(action: {
                    NotificationCenter.default.post(name: NSNotification.Name("HideDropZone"), object: nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.8))
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 16)
                .padding(.top, 10)
            }
            .frame(height: 24)
            
            mainContent
                .padding(.bottom, 16)
        }
        // ANA PENCEREYİ ZORLAMAMAK İÇİN İNFİNİTY KULLANIYORUZ
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: islandCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: islandCornerRadius)
                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        HStack(spacing: 12) {
            airDropArea
            stashArea
        }
        .padding(.horizontal, 16)
        .frame(height: 80)
    }
    
    // MARK: - AirDrop Area
    private var airDropArea: some View {
        VStack(spacing: 6) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 24))
                .foregroundColor(isTargetingAirDrop ? .blue : .white)
            Text("AirDrop")
                .font(.system(size: 11))
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(width: 90, height: 80)
        .background(
            RoundedRectangle(cornerRadius: innerCornerRadius)
                .fill(isTargetingAirDrop ? Color.blue.opacity(0.2) : Color.black.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: innerCornerRadius)
                .strokeBorder(isTargetingAirDrop ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: innerCornerRadius))
        .onDrop(of: [.fileURL, .url, .image, .png, .jpeg, .tiff, .data], isTargeted: $isTargetingAirDrop) { providers in
            stashManager.shareViaAirDrop(providers: providers)
            return true
        }
    }
    
    // MARK: - Stash Area
    private var stashArea: some View {
        HStack(spacing: 8) {
            if stashManager.stashedFiles.isEmpty {
                emptyStashView
            } else {
                stashedFilesView
            }
        }
        .padding(.horizontal, 8)
        // İÇERİĞİN ESNEMESİ İÇİN MAXWİDTH İNFİNİTY
        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: innerCornerRadius)
                .fill(isTargetingStash ? Color.green.opacity(0.2) : Color.black.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: innerCornerRadius)
                .strokeBorder(isTargetingStash ? Color.green : Color.clear, lineWidth: 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: innerCornerRadius))
        .onDrop(of: [.fileURL, .url, .image, .png, .jpeg, .tiff, .data], isTargeted: $isTargetingStash) { providers in
            for provider in providers {
                stashManager.addFile(provider: provider)
            }
            return true
        }
    }
    
    // MARK: - Empty Stash View
    private var emptyStashView: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 24))
            Text("Drop files here")
                .font(.system(size: 11))
                .fontWeight(.medium)
        }
        .foregroundColor(isTargetingStash ? .green : .gray)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    // MARK: - Stashed Files View
    private var stashedFilesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(stashManager.stashedFiles, id: \.self) { url in
                    StashedFileItem(url: url) {
                        stashManager.removeFile(url)
                    }
                }
            }
            .padding(.horizontal, 4)
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Tekil Dosya Görünümü (Sürükleyip Çıkarma İçin)
struct StashedFileItem: View {
    let url: URL
    let onRemove: () -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .topTrailing) {
                // Use NSView wrapper for better drag handling
                DraggableFileView(url: url, isDragging: $isDragging)
                    .frame(width: 44, height: 44)
                
                // Silme Butonu
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 18, height: 18)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .offset(x: 4, y: -4)
                .allowsHitTesting(true)
            }
            .frame(width: 48, height: 48)  // Container for icon + button
            
            // File name label
            Text(url.lastPathComponent)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 50)
        }
        .frame(width: 54, height: 70)  // Compact container
    }
}

// NSView wrapper for proper drag handling
struct DraggableFileView: NSViewRepresentable {
    let url: URL
    @Binding var isDragging: Bool
    
    func makeNSView(context: Context) -> DraggableImageView {
        let view = DraggableImageView(url: url)
        view.onDraggingChanged = { dragging in
            DispatchQueue.main.async {
                isDragging = dragging
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: DraggableImageView, context: Context) {
        nsView.url = url
    }
}

class DraggableImageView: NSView {
    var url: URL
    var onDraggingChanged: ((Bool) -> Void)?
    private var imageView: NSImageView!
    
    init(url: URL) {
        self.url = url
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Create image view
        imageView = NSImageView(frame: bounds)
        imageView.image = NSWorkspace.shared.icon(forFile: url.path)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        addSubview(imageView)
        
        // Register for dragging
        registerForDraggedTypes([.fileURL])
    }
    
    override func mouseDown(with event: NSEvent) {
        // Immediately start drag on mouse down - no delay
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(url.path, forType: .fileURL)
        
        let draggingItem = NSDraggingItem(pasteboardWriter: url as NSURL)
        
        // Use the file icon as drag image
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 44, height: 44)  // Match the view size
        draggingItem.setDraggingFrame(bounds, contents: icon)
        
        // Start dragging immediately
        onDraggingChanged?(true)
        
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
}

extension DraggableImageView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        onDraggingChanged?(false)
    }
}
