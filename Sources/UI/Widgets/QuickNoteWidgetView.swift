import SwiftUI
import AppKit

/// Instant scratchpad widget in the notch with persistent storage.
public struct QuickNoteWidgetView: View {
    @AppStorage("NotchQuickNoteContent") private var noteText: String = L10n.defaultNote
    @State private var isCopied: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                Label(L10n.notchScratchpad, systemImage: "note.text")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                if isCopied {
                    Text(L10n.copied)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(noteText, forType: .string)
                    withAnimation { isCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation { isCopied = false }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 9))
                        Text(L10n.copy)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(L10n.clear) {
                    withAnimation { noteText = "" }
                }
                .buttonStyle(.plain)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.red.opacity(0.8))
            }
            .padding(.horizontal, 16)

            TextEditor(text: $noteText)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 16)
                .frame(height: 72)
        }
        .padding(.vertical, 4)
    }
}
