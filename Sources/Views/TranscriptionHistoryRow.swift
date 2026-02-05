import SwiftUI

struct TranscriptionHistoryRow: View {
    let entry: TranscriptionHistoryEntry
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false
    @State private var justCopied = false

    var body: some View {
        HStack(spacing: 12) {
            // Timestamp badge
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayTimestamp)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(entry.modelUsed)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 100, alignment: .leading)

            Divider()

            // Transcription text
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayText)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                if entry.text != entry.displayText {
                    Text("\(entry.text.count) characters")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Language badge
            Text(entry.language.displayName)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                .foregroundStyle(.secondary)

            // Actions
            HStack(spacing: 6) {
                Button(action: {
                    onCopy()
                    // Show "Copied!" feedback
                    justCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        justCopied = false
                    }
                }) {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help(justCopied ? "Copied!" : "Copy to clipboard")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red.opacity(0.8))
                .help("Delete")
            }
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onCopy()
        }
    }
}
