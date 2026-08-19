import SwiftUI

/// Animated audio waveform visualizer that reacts smoothly to music playback state with fluid ProMotion heights.
public struct WaveformVisualizerView: View {
    public let isPlaying: Bool
    public let barColor: Color
    public let barCount: Int

    @State private var barHeights: [CGFloat] = []
    @State private var timerSubscription: Task<Void, Never>?

    public init(isPlaying: Bool, barColor: Color = .white, barCount: Int = 4) {
        self.isPlaying = isPlaying
        self.barColor = barColor
        self.barCount = barCount
        self._barHeights = State(initialValue: Array(repeating: 4.0, count: barCount))
    }

    public var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(barColor)
                    .frame(width: 3.0, height: barHeights.indices.contains(index) ? barHeights[index] : 4.0)
            }
        }
        .frame(height: 16.0)
        .onAppear {
            updateAnimationState()
        }
        .onChange(of: isPlaying) { _, _ in
            updateAnimationState()
        }
        .onDisappear {
            stopAnimation()
        }
    }

    private func updateAnimationState() {
        if isPlaying {
            startAnimation()
        } else {
            stopAnimation()
            withAnimation(Constants.Animation.waveformFade) {
                barHeights = Array(repeating: 3.5, count: barCount)
            }
        }
    }

    private func startAnimation() {
        stopAnimation()
        timerSubscription = Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
                    barHeights = (0..<barCount).map { _ in
                        CGFloat.random(in: 4.0...14.0)
                    }
                }
                try? await Task.sleep(nanoseconds: 140_000_000) // ~7 updates per second for lively yet efficient animation
            }
        }
    }

    private func stopAnimation() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
}

#Preview {
    WaveformVisualizerView(isPlaying: true, barColor: .green, barCount: 4)
        .padding()
        .background(Color.black)
}
