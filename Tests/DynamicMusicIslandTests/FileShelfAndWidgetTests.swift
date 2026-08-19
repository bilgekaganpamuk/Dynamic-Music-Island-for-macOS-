import XCTest
@testable import DynamicMusicIsland

@MainActor
final class FileShelfAndWidgetTests: XCTestCase {
    func testFileDropManagerItemAdditionAndRemoval() {
        let manager = FileDropManager.shared
        manager.clearAll()

        let dummyURL = URL(fileURLWithPath: "/tmp/sample_song.mp3")
        manager.addFiles(from: [dummyURL])

        XCTAssertEqual(manager.items.count, 1)
        XCTAssertEqual(manager.items.first?.name, "sample_song.mp3")

        let itemId = manager.items.first!.id
        manager.removeItem(id: itemId)
        XCTAssertEqual(manager.items.count, 0)
    }

    func testWidgetManagerTabAndWidgetSwitching() {
        let manager = WidgetManager.shared

        manager.switchToTab(.tray)
        XCTAssertEqual(manager.activeTab, .tray)

        manager.switchToTab(.clipboard)
        XCTAssertEqual(manager.activeTab, .clipboard)

        manager.switchToWidget(.pomodoro)
        XCTAssertEqual(manager.activeWidget, .pomodoro)
        XCTAssertEqual(manager.activeTab, .home)

        manager.switchToWidget(.weather)
        XCTAssertEqual(manager.activeWidget, .weather)

        manager.switchToWidget(.calendar)
        XCTAssertEqual(manager.activeWidget, .calendar)
    }

    func testBatteryManagerInitialMetrics() {
        let battery = BatteryManager.shared
        XCTAssertGreaterThanOrEqual(battery.batteryLevel, 0)
        XCTAssertLessThanOrEqual(battery.batteryLevel, 100)
    }

    func testClipboardManagerOperations() {
        let clipboard = ClipboardManager.shared
        clipboard.clearAll()

        let item = ClipboardItem(text: "https://apple.com")
        XCTAssertTrue(item.isURL)
        XCTAssertEqual(item.typeIcon, "link")

        clipboard.history.append(item)
        XCTAssertEqual(clipboard.history.count, 1)

        clipboard.deleteItem(id: item.id)
        XCTAssertEqual(clipboard.history.count, 0)
    }

    func testPomodoroManagerTimerControls() {
        let pomodoro = PomodoroManager.shared
        pomodoro.switchMode(.shortBreak)
        XCTAssertEqual(pomodoro.timeRemaining, 5 * 60)
        XCTAssertEqual(pomodoro.timeString, "05:00")

        pomodoro.switchMode(.focus)
        XCTAssertEqual(pomodoro.timeRemaining, 25 * 60)
        XCTAssertEqual(pomodoro.timeString, "25:00")
        XCTAssertEqual(pomodoro.progress, 0.0)
    }

    func testAppShortcutsManagerAndCustomization() {
        let appManager = AppShortcutsManager.shared
        XCTAssertFalse(appManager.shortcuts.isEmpty)

        let initialCount = appManager.shortcuts.count
        let customAppURL = URL(fileURLWithPath: "/Applications/Calculator.app")
        appManager.addApp(from: customAppURL)

        XCTAssertTrue(appManager.shortcuts.contains(where: { $0.name == "Calculator" }))
        let addedItem = appManager.shortcuts.first(where: { $0.name == "Calculator" })!
        appManager.removeApp(id: addedItem.id)
        XCTAssertEqual(appManager.shortcuts.count, initialCount)
    }

    func testWebBookmarksManager() {
        let webManager = WebBookmarksManager.shared
        XCTAssertFalse(webManager.bookmarks.isEmpty)

        let initialCount = webManager.bookmarks.count
        webManager.addBookmark(name: "TestSite", url: "testsite.com")
        XCTAssertEqual(webManager.bookmarks.count, initialCount + 1)

        let added = webManager.bookmarks.last!
        XCTAssertEqual(added.url, "https://testsite.com")
        webManager.removeBookmark(id: added.id)
        XCTAssertEqual(webManager.bookmarks.count, initialCount)
    }

    func testLocalizationValues() {
        XCTAssertFalse(L10n.widgetsTab.isEmpty)
        XCTAssertFalse(L10n.shelfTab.isEmpty)
        XCTAssertFalse(L10n.clipboardTab.isEmpty)
        XCTAssertFalse(L10n.filesInShelf(count: 5).isEmpty)
    }
}
