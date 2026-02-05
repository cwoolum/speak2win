import SwiftUI
import UniformTypeIdentifiers

struct HistorySettingsView: View {
    @EnvironmentObject var historyState: TranscriptionHistoryState
    @State private var searchText: String = ""
    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Error banner
            if let error = historyState.errorMessage {
                errorBanner(error)
            }

            // Main content
            if historyState.entries.isEmpty {
                emptyStateView
            } else if historyState.groupedEntries.isEmpty && !searchText.isEmpty {
                noResultsView
            } else {
                listView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search history...")
        .onChange(of: searchText) { _, newValue in
            historyState.searchQuery = newValue
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Model filter
                Menu {
                    Button {
                        historyState.modelFilter = nil
                    } label: {
                        if historyState.modelFilter == nil {
                            Label("All Models", systemImage: "checkmark")
                        } else {
                            Text("All Models")
                        }
                    }
                    Divider()
                    ForEach(historyState.availableModels, id: \.self) { model in
                        Button {
                            historyState.modelFilter = model
                        } label: {
                            if historyState.modelFilter == model {
                                Label(model, systemImage: "checkmark")
                            } else {
                                Text(model)
                            }
                        }
                    }
                } label: {
                    Label(
                        historyState.modelFilter ?? "All Models",
                        systemImage: "waveform"
                    )
                }

                // Export
                Menu {
                    Button("Export...", systemImage: "square.and.arrow.up") {
                        exportHistory()
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }

                // Clear all
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
            List {
                ForEach(historyState.groupedEntries, id: \.section) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            TranscriptionHistoryRow(
                                entry: entry,
                                onCopy: { historyState.copyToClipboard(entry) },
                                onDelete: { historyState.delete(entry) }
                            )
                        }
                    } header: {
                        Text(group.section.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            // Footer
            HStack {
                Text("\(historyState.filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !searchText.isEmpty || historyState.modelFilter != nil {
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

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(.tertiary)

            Text("No results for \"\(searchText)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
