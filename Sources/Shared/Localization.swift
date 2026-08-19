import Foundation

/// Centralized localization engine that dynamically adapts to the user's macOS system language.
/// Uses Turkish if macOS language is set to Turkish; defaults to English for all other systems.
public enum L10n {
    public static var isTurkish: Bool {
        let preferred = Locale.preferredLanguages.first ?? Locale.current.identifier
        return preferred.lowercased().hasPrefix("tr")
    }

    // Top Header Tabs
    public static var widgetsTab: String { isTurkish ? "Widget'lar" : "Widgets" }
    public static var shelfTab: String { isTurkish ? "Raf" : "Shelf" }
    public static var clipboardTab: String { isTurkish ? "Pano" : "Clipboard" }

    // Widget Titles & Switcher
    public static var music: String { isTurkish ? "Müzik" : "Music" }
    public static var focus: String { isTurkish ? "Odak" : "Focus" }
    public static var notes: String { isTurkish ? "Notlar" : "Notes" }
    public static var water: String { isTurkish ? "Su" : "Water" }
    public static var apps: String { isTurkish ? "Uygulamalar" : "Apps" }
    public static var web: String { "Web" }
    public static var weather: String { isTurkish ? "Hava" : "Weather" }
    public static var calendar: String { isTurkish ? "Takvim" : "Calendar" }
    public static var mirror: String { isTurkish ? "Ayna" : "Mirror" }

    // Shelf & AirDrop
    public static func filesInShelf(count: Int) -> String {
        isTurkish ? "\(count) Dosya Rafta" : "\(count) Files in Shelf"
    }
    public static var add: String { isTurkish ? "Ekle" : "Add" }
    public static var clear: String { isTurkish ? "Temizle" : "Clear" }
    public static var dropFilesHere: String { isTurkish ? "Dosyaları Buraya Bırakın" : "Drop Files Here" }
    public static var shelfDragHint: String { isTurkish ? "Finder'dan dosyaları sürükleyin, sonra kullanın" : "Drag files from Finder to hold, drag out to use later" }
    public static var dropToSend: String { isTurkish ? "Gönder" : "Drop to Send" }
    public static var airDrop: String { "AirDrop" }
    public static var airDropHelp: String { isTurkish ? "Dosyaları buraya bırakın veya rafdaki dosyaları AirDrop ile gönderin" : "Drop files here or click to send shelf items via AirDrop" }
    public static var sendViaAirDrop: String { isTurkish ? "AirDrop ile Gönder" : "Send via AirDrop" }
    public static var revealInFinder: String { isTurkish ? "Finder'da Göster" : "Reveal in Finder" }
    public static var removeFromShelf: String { isTurkish ? "Raftan Kaldır" : "Remove from Shelf" }

    // Clipboard
    public static var searchSnippets: String { isTurkish ? "Pano geçmişinde ara..." : "Search clipboard snippets..." }
    public static var noClipboardHistory: String { isTurkish ? "Henüz pano geçmişi yok" : "No clipboard history yet" }
    public static var noMatchingSnippets: String { isTurkish ? "Eşleşen öğe bulunamadı" : "No matching snippets found" }
    public static var copied: String { isTurkish ? "Kopyalandı!" : "Copied!" }
    public static var copyToClipboard: String { isTurkish ? "Panoya Kopyala" : "Copy to Clipboard" }
    public static var deleteSnippet: String { isTurkish ? "Öğeyi Sil" : "Delete Snippet" }

    // Focus / Pomodoro
    public static var startFocus: String { isTurkish ? "Başlat" : "Start Focus" }
    public static var pause: String { isTurkish ? "Duraklat" : "Pause" }
    public static var resetTimer: String { isTurkish ? "Sıfırla" : "Reset Timer" }
    public static var focusSession: String { isTurkish ? "Odak (25dk)" : "Focus (25m)" }
    public static var shortBreak: String { isTurkish ? "Kısa Mola (5dk)" : "Short Break (5m)" }
    public static var longBreak: String { isTurkish ? "Uzun Mola (15dk)" : "Long Break (15m)" }

    // Notes
    public static var notchScratchpad: String { isTurkish ? "Çentik Not Defteri" : "Notch Scratchpad" }
    public static var copy: String { isTurkish ? "Kopyala" : "Copy" }
    public static var defaultNote: String {
        isTurkish ? "💡 Fikir / Toplantı Notu:\n- Çentik rafını kontrol et\n- Yeni özellikleri test et" : "💡 Meeting note / idea:\n- Check dynamic island\n- Ship release build"
    }

    // Water
    public static var dailyHydration: String { isTurkish ? "Günlük Su Takibi" : "Daily Hydration" }
    public static var drinkCup: String { isTurkish ? "Bardak İç" : "Drink Cup" }
    public static var goalReached: String { isTurkish ? "🎉 Hedefe Ulaşıldı! Harika!" : "🎉 Goal Reached! Great job!" }
    public static func cupsLeft(count: Int) -> String {
        isTurkish ? "Hedefe \(count) bardak kaldı" : "\(count) cups left to reach your goal"
    }

    // Apps
    public static var appShortcuts: String { isTurkish ? "Uygulama Kısayolları" : "App Shortcuts" }
    public static var addApp: String { isTurkish ? "Uygulama Ekle" : "Add App" }
    public static var edit: String { isTurkish ? "Düzenle" : "Edit" }
    public static var done: String { isTurkish ? "Bitti" : "Done" }
    public static var addToNotch: String { isTurkish ? "Çentiğe Ekle" : "Add to Notch" }

    // Web
    public static var enterURL: String { isTurkish ? "Web sitesi veya arama..." : "Enter website URL or search..." }
    public static var openInSafari: String { isTurkish ? "Tarayıcıda Aç" : "Open in Safari" }
    public static var addBookmark: String { isTurkish ? "Yer İmi Ekle" : "Add Bookmark" }
    public static var save: String { isTurkish ? "Kaydet" : "Save" }
    public static var cancel: String { isTurkish ? "Vazgeç" : "Cancel" }
}
