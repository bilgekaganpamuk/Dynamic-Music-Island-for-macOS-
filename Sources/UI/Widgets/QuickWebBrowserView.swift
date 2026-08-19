import SwiftUI
import WebKit

/// Interactive WKWebView wrapper with navigation support
public struct MiniWebView: NSViewRepresentable {
    public let urlString: String
    @Binding public var webViewRef: WKWebView?

    public init(urlString: String, webViewRef: Binding<WKWebView?>) {
        self.urlString = urlString
        self._webViewRef = webViewRef
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        DispatchQueue.main.async {
            self.webViewRef = webView
        }
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        if let currentURL = nsView.url?.absoluteString, currentURL != urlString, let url = URL(string: urlString) {
            nsView.load(URLRequest(url: url))
        }
    }
}

/// Fully featured Notch Mini Web Browser view with dynamic 2X resizing
public struct QuickWebBrowserView: View {
    @State private var bookmarksManager = WebBookmarksManager.shared
    @State private var currentURL: String = "https://google.com"
    @State private var inputURL: String = "https://google.com"
    @State private var webView: WKWebView?
    @State private var showAddBookmark: Bool = false
    @State private var newBookmarkName: String = ""
    @State private var newBookmarkURL: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 6) {
            // Top Controls & Navigation Bar
            HStack(spacing: 6) {
                // Back & Forward & Reload & Home
                HStack(spacing: 2) {
                    Button {
                        webView?.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(4)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        webView?.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(4)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        webView?.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(4)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        currentURL = "https://google.com"
                        inputURL = currentURL
                    } label: {
                        Image(systemName: "house.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(4)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                // Interactive URL Address Bar
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.green.opacity(0.85))

                    TextField(L10n.enterURL, text: $inputURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .onSubmit {
                            navigateToInputURL()
                        }

                    Button {
                        navigateToInputURL()
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())

                // Size Switcher Presets [S] [M] [2X]
                HStack(spacing: 2) {
                    ForEach(BrowserSizeMode.allCases) { mode in
                        Button {
                            withAnimation(Constants.Animation.liquidSpring) {
                                bookmarksManager.sizeMode = mode
                            }
                        } label: {
                            Text(mode.rawValue)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 3)
                                .background(bookmarksManager.sizeMode == mode ? Color.blue : Color.white.opacity(0.1))
                                .foregroundColor(bookmarksManager.sizeMode == mode ? .white : .secondary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Open in External Safari / Default Browser
                Button {
                    if let url = URL(string: currentURL) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help(L10n.openInSafari)
            }
            .padding(.horizontal, 16)

            // Bookmarks Bar
            HStack(spacing: 6) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(bookmarksManager.bookmarks) { bookmark in
                            Button {
                                if bookmarksManager.isEditing {
                                    withAnimation { bookmarksManager.removeBookmark(id: bookmark.id) }
                                } else {
                                    currentURL = bookmark.url
                                    inputURL = bookmark.url
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: bookmark.iconName)
                                        .font(.system(size: 8))
                                    Text(bookmark.name)
                                        .font(.system(size: 9, weight: .medium))

                                    if bookmarksManager.isEditing {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 7, weight: .bold))
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(currentURL.contains(bookmark.name.lowercased()) ? Color.blue.opacity(0.3) : Color.white.opacity(0.08))
                                .clipShape(Capsule())
                                .foregroundColor(currentURL.contains(bookmark.name.lowercased()) ? .blue : .secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        // Add Bookmark Button
                        Button {
                            withAnimation { showAddBookmark.toggle() }
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "plus")
                                    .font(.system(size: 8, weight: .bold))
                                Text(L10n.add)
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Edit Bookmarks Mode Toggle
                Button {
                    withAnimation { bookmarksManager.isEditing.toggle() }
                } label: {
                    Text(bookmarksManager.isEditing ? L10n.done : L10n.edit)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(bookmarksManager.isEditing ? .blue : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Add Bookmark Form
            if showAddBookmark {
                HStack(spacing: 6) {
                    TextField("Name (e.g. Perplexity)", text: $newBookmarkName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 9))
                        .padding(4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    TextField("URL (e.g. perplexity.ai)", text: $newBookmarkURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 9))
                        .padding(4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Button(L10n.save) {
                        if !newBookmarkURL.isEmpty {
                            bookmarksManager.addBookmark(name: newBookmarkName, url: newBookmarkURL)
                            newBookmarkName = ""
                            newBookmarkURL = ""
                            withAnimation { showAddBookmark = false }
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.blue)

                    Button(L10n.cancel) {
                        withAnimation { showAddBookmark = false }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .transition(.opacity)
            }

            // Spacious Responsive Mini Web Browser View
            MiniWebView(urlString: currentURL, webViewRef: $webView)
                .frame(height: bookmarksManager.sizeMode.webViewHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .padding(.horizontal, 14)
                .animation(Constants.Animation.liquidSpring, value: bookmarksManager.sizeMode)
        }
        .padding(.vertical, 4)
    }

    private func navigateToInputURL() {
        var clean = inputURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.hasPrefix("http://") && !clean.hasPrefix("https://") {
            if clean.contains(".") {
                clean = "https://" + clean
            } else {
                clean = "https://google.com/search?q=" + clean.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            }
        }
        currentURL = clean
        inputURL = clean
    }
}
