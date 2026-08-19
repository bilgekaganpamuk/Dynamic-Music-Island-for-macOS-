import SwiftUI

/// Smooth horizontal auto-scrolling marquee text for long titles or artists that exceed available container width.
public struct MarqueeText: View {
    public let text: String
    public let font: Font
    public let color: Color
    public let delay: Double

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isAnimating: Bool = false

    public init(
        _ text: String,
        font: Font = .system(size: 13, weight: .semibold),
        color: Color = .white,
        delay: Double = 2.0
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.delay = delay
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Text(text)
                    .font(font)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize()
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.onAppear {
                                textWidth = textGeo.size.width
                                containerWidth = geometry.size.width
                                triggerScrollIfNeeded()
                            }
                            .onChange(of: text) { _, _ in
                                textWidth = textGeo.size.width
                                containerWidth = geometry.size.width
                                resetAndScroll()
                            }
                        }
                    )
                    .offset(x: offset)
            }
            .clipped()
        }
        .frame(height: 18)
    }

    private func triggerScrollIfNeeded() {
        guard textWidth > containerWidth && containerWidth > 0 else {
            offset = 0
            return
        }

        let overflow = textWidth - containerWidth
        let scrollDuration = Double(overflow) / 25.0 // Constant speed ~25 pts/sec

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }

            withAnimation(.linear(duration: scrollDuration)) {
                offset = -overflow - 12
            }

            try? await Task.sleep(nanoseconds: UInt64((scrollDuration + 1.0) * 1_000_000_000))
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.5)) {
                offset = 0
            }

            try? await Task.sleep(nanoseconds: 1_500_000_000)
            triggerScrollIfNeeded()
        }
    }

    private func resetAndScroll() {
        offset = 0
        triggerScrollIfNeeded()
    }
}
