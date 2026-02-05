import SwiftUI

struct TranscriptionHistoryRow: View {
    let entry: TranscriptionHistoryEntry
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var justCopied = false
    @State private var isTruncated = false
    @State private var fullTextHeight: CGFloat = 0
    @State private var truncatedTextHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Transcription text (the hero)
            Text(entry.text)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .background(
                    // Hidden full-height text to measure natural size
                    Text(entry.text)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .background(GeometryReader { geo in
                            Color.clear.preference(
                                key: FullHeightKey.self,
                                value: geo.size.height
                            )
                        })
                )
                .background(GeometryReader { geo in
                    Color.clear.preference(
                        key: TruncatedHeightKey.self,
                        value: geo.size.height
                    )
                })
                .onPreferenceChange(FullHeightKey.self) { height in
                    fullTextHeight = height
                    updateTruncation()
                }
                .onPreferenceChange(TruncatedHeightKey.self) { height in
                    truncatedTextHeight = height
                    updateTruncation()
                }

            // "Show More / Less" only when text is actually being clipped
            if isTruncated || isExpanded {
                Button(isExpanded ? "Show Less" : "Show More") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }

            // Metadata footer line
            HStack(spacing: 6) {
                Text(entry.displayTime)
                    .foregroundStyle(.secondary)

                Text("\u{00B7}")
                    .foregroundStyle(.quaternary)

                Text(entry.modelUsed)
                    .foregroundStyle(.secondary)

                Text("\u{00B7}")
                    .foregroundStyle(.quaternary)

                Text(entry.language.displayName)
                    .foregroundStyle(.secondary)

                Spacer()

                // Copy button
                Button {
                    onCopy()
                    justCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        justCopied = false
                    }
                } label: {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .foregroundColor(justCopied ? .green : .accentColor)
                .help("Copy to clipboard")

                // Delete button
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red.opacity(0.6))
                .help("Delete")
            }
            .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }

    private func updateTruncation() {
        if !isExpanded {
            isTruncated = fullTextHeight > truncatedTextHeight + 1
        }
    }
}

// MARK: - Preference Keys

private struct FullHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct TruncatedHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
