import SwiftUI
import UniformTypeIdentifiers

struct TranscriptionHistoryView: View {
    @EnvironmentObject var historyState: TranscriptionHistoryState
    @State private var searchText: String = ""
    @State private var showingClearConfirmation = false
    @State private var selectedEntries = Set<TranscriptionHistoryEntry.ID>()

    var body: some View {
        VStack(spacing: 0) {
            // Error banner
            if let error = historyState.errorMessage {
                errorBanner(error)
            }

            // Main content
            if historyState.filteredEntries.isEmpty && searchText.isEmpty {
                emptyStateView
            } else {
                listView
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search history...")
        .onChange(of: searchText) { _, newValue in
            historyState.searchQuery = newValue
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Export button
                Menu {
                    Button("Export...", systemImage: "square.and.arrow.up") {
                        exportHistory()
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }

                // Clear all button
                Button {
                    showingClearConfirmation = true
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
                .disabled(historyState.entries.isEmpty)
                .confirmationDialog(
                    "Clear all transcription history?",
                    isPresented: $showingClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear All", role: .destructive) {
                        historyState.clearAll()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
    }

    private var listView: some View {
        VStack(spacing: 0) {
            List(selection: $selectedEntries) {
                ForEach(historyState.filteredEntries) { entry in
                    TranscriptionHistoryRow(
                        entry: entry,
                        onCopy: { historyState.copyToClipboard(entry) },
                        onDelete: { historyState.delete(entry) }
                    )
                    .tag(entry.id)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            // Footer
            HStack {
                Text("\(historyState.filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !searchText.isEmpty {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(historyState.entries.count) total")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(.tertiary)

            VStack(spacing: 6) {
                Text("No History Yet")
                    .font(.title2)
                    .fontWeight(.medium)
                Text("Your recent transcriptions will appear here.\nClick any entry to copy it to the clipboard.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(error)
                .font(.subheadline)
            Spacer()
            Button {
                withAnimation { historyState.dismissError() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func exportHistory() {
        guard let data = historyState.exportData() else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "speak2_history.json"

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
}
