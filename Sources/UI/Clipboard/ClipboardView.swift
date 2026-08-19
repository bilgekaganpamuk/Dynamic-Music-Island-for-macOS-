import SwiftUI

/// Notch view to browse, search, copy, and drag clipboard history snippets.
public struct ClipboardView: View {
    @State private var clipboardManager = ClipboardManager.shared
    @State private var copiedItemId: UUID? = nil

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            // Search Bar & Actions
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    TextField(L10n.searchSnippets, text: $clipboardManager.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(.white)

                    if !clipboardManager.searchText.isEmpty {
                        Button {
                            clipboardManager.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Text("\(clipboardManager.filteredHistory.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())

                if !clipboardManager.history.isEmpty {
                    Button(L10n.clear) {
                        withAnimation {
                            clipboardManager.clearAll()
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.red.opacity(0.85))
                }
            }
            .padding(.horizontal, 16)

            // Snippets List
            if clipboardManager.filteredHistory.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                    Text(clipboardManager.searchText.isEmpty ? L10n.noClipboardHistory : L10n.noMatchingSnippets)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 80)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 5) {
                        ForEach(clipboardManager.filteredHistory) { item in
                            snippetRow(item: item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }
                .frame(height: 95)
            }
        }
        .padding(.vertical, 4)
    }

    private func snippetRow(item: ClipboardItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.typeIcon)
                .font(.system(size: 11))
                .foregroundColor(.blue.opacity(0.85))
                .frame(width: 16)

            Text(item.preview)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if copiedItemId == item.id {
                Text(L10n.copied)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.green)
                    .transition(.opacity)
            }

            // Copy Action Button
            Button {
                clipboardManager.copyToClipboard(item: item)
                withAnimation {
                    copiedItemId = item.id
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    if copiedItemId == item.id {
                        withAnimation { copiedItemId = nil }
                    }
                }
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .help(L10n.copyToClipboard)

            // Delete Action Button
            Button {
                withAnimation {
                    clipboardManager.deleteItem(id: item.id)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help(L10n.deleteSnippet)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onDrag {
            NSItemProvider(object: item.text as NSString)
        }
    }
}
