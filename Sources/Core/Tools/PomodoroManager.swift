import Foundation
import SwiftUI
import Observation

public enum PomodoroMode: String, CaseIterable, Identifiable, Sendable {
    case focus = "Focus"
    case shortBreak = "ShortBreak"
    case longBreak = "LongBreak"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .focus: return L10n.focusSession
        case .shortBreak: return L10n.shortBreak
        case .longBreak: return L10n.longBreak
        }
    }

    public var totalSeconds: Int {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }

    public var color: Color {
        switch self {
        case .focus: return .orange
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
}

@Observable
@MainActor
public final class PomodoroManager {
    public static let shared = PomodoroManager()

    public var currentMode: PomodoroMode = .focus
    public var timeRemaining: Int = 25 * 60
    public var isRunning: Bool = false

    private var timer: Timer?

    public init() {
        self.timeRemaining = currentMode.totalSeconds
    }

    public var progress: Double {
        let total = Double(currentMode.totalSeconds)
        return total > 0 ? (1.0 - (Double(timeRemaining) / total)) : 0
    }

    public var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.pause()
                }
            }
        }
    }

    public func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    public func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }

    public func reset() {
        pause()
        timeRemaining = currentMode.totalSeconds
    }

    public func switchMode(_ mode: PomodoroMode) {
        pause()
        currentMode = mode
        timeRemaining = mode.totalSeconds
    }
}
