import Foundation
import SwiftUI
import Observation

/// Available dynamic widgets dockable in the notch
public enum WidgetType: String, CaseIterable, Identifiable, Sendable {
    case music = "Music"
    case pomodoro = "Focus"
    case notes = "Notes"
    case hydration = "Water"
    case shortcuts = "Apps"
    case browser = "Web"
    case weather = "Weather"
    case calendar = "Calendar"
    case mirror = "Mirror"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .music: return "music.note"
        case .pomodoro: return "timer"
        case .notes: return "square.and.pencil"
        case .hydration: return "drop.fill"
        case .shortcuts: return "square.grid.2x2.fill"
        case .browser: return "globe"
        case .weather: return "cloud.sun.fill"
        case .calendar: return "calendar"
        case .mirror: return "camera.viewfinder"
        }
    }

    public var title: String {
        switch self {
        case .music: return L10n.music
        case .pomodoro: return L10n.focus
        case .notes: return L10n.notes
        case .hydration: return L10n.water
        case .shortcuts: return L10n.apps
        case .browser: return L10n.web
        case .weather: return L10n.weather
        case .calendar: return L10n.calendar
        case .mirror: return L10n.mirror
        }
    }
}

/// Active tab mode in the expanded island: Home (Widgets/Music), Tray (Shelf & AirDrop), or Clipboard
public enum IslandTabMode: String, CaseIterable, Sendable {
    case home = "Widgets"
    case tray = "Shelf"
    case clipboard = "Clipboard"

    public var title: String {
        switch self {
        case .home: return L10n.widgetsTab
        case .tray: return L10n.shelfTab
        case .clipboard: return L10n.clipboardTab
        }
    }
}

/// Coordinates the active widget, weather, calendar, and camera states.
@Observable
@MainActor
public final class WidgetManager {
    public static let shared = WidgetManager()

    public var activeWidget: WidgetType = .music
    public var activeTab: IslandTabMode = .home

    // Mock/Live Weather data
    public var weatherCity: String = "Istanbul"
    public var weatherTemp: String = "24°C"
    public var weatherCondition: String = "Partly Cloudy"
    public var weatherHighLow: String = "21°C ~ 28°C"
    public var weatherIcon: String = "sun.max.fill"

    // Mock/Live Calendar data
    public var calendarEvents: [String] = [
        "18:00 Team Design Sync",
        "20:30 Coding Live Stream"
    ]

    public init() {}

    public func switchToWidget(_ widget: WidgetType) {
        withAnimation(Constants.Animation.liquidSpring) {
            self.activeWidget = widget
            self.activeTab = .home
        }
    }

    public func switchToTab(_ tab: IslandTabMode) {
        withAnimation(Constants.Animation.liquidSpring) {
            self.activeTab = tab
        }
    }
}
