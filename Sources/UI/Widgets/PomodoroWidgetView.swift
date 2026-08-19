import SwiftUI

/// Pomodoro Focus timer widget in the notch.
public struct PomodoroWidgetView: View {
    @State private var pomodoro = PomodoroManager.shared

    public init() {}

    public var body: some View {
        HStack(spacing: 16) {
            // Circular Progress Timer
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 5)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: pomodoro.progress)
                    .stroke(
                        pomodoro.currentMode.color,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 60, height: 60)
                    .animation(.linear(duration: 1.0), value: pomodoro.progress)

                VStack(spacing: 1) {
                    Text(pomodoro.timeString)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }

            // Controls & Modes
            VStack(alignment: .leading, spacing: 6) {
                // Mode Selectors
                HStack(spacing: 4) {
                    ForEach(PomodoroMode.allCases) { mode in
                        Button {
                            withAnimation { pomodoro.switchMode(mode) }
                        } label: {
                            Text(mode.title)
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(pomodoro.currentMode == mode ? mode.color.opacity(0.3) : Color.white.opacity(0.08))
                                .clipShape(Capsule())
                                .foregroundColor(pomodoro.currentMode == mode ? mode.color : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Play/Pause & Reset Buttons
                HStack(spacing: 8) {
                    Button {
                        pomodoro.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: pomodoro.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 10))
                            Text(pomodoro.isRunning ? L10n.pause : L10n.startFocus)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(pomodoro.currentMode.color)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        pomodoro.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(5)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(L10n.resetTimer)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
