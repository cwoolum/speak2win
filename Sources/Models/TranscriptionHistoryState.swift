import Foundation
import Combine
import AppKit

@MainActor
class TranscriptionHistoryState: ObservableObject {
    @Published var entries: [TranscriptionHistoryEntry] = []
    @Published var searchQuery: String = ""
    @Published var errorMessage: String? = nil

    private let storage = TranscriptionHistoryStorage()

    var filteredEntries: [TranscriptionHistoryEntry] {
        if searchQuery.isEmpty {
            return entries
        }
        return entries.filter { entry in
            entry.text.localizedCaseInsensitiveContains(searchQuery) ||
            entry.modelUsed.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    func load() {
        entries = storage.load()
    }

    func save() {
        do {
            try storage.save(entries)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save history. Changes may not persist."
        }
    }

    func add(_ entry: TranscriptionHistoryEntry) {
        // Deduplicate: skip if identical to last entry
        if let lastEntry = entries.first,
           lastEntry.text == entry.text,
           lastEntry.modelUsed == entry.modelUsed {
            return
        }

        // Skip empty transcriptions
        guard !entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        // Insert at beginning (most recent first)
        entries.insert(entry, at: 0)

        // Auto-trim to 20
        if entries.count > 20 {
            entries = Array(entries.prefix(20))
        }

        save()
    }

    func delete(_ entry: TranscriptionHistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func deleteMultiple(_ entriesToDelete: [TranscriptionHistoryEntry]) {
        let idsToDelete = Set(entriesToDelete.map { $0.id })
        entries.removeAll { idsToDelete.contains($0.id) }
        save()
    }

    func clearAll() {
        entries = []
        do {
            try storage.clearAll()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to clear history."
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    func exportData() -> Data? {
        storage.exportToJSON(entries)
    }

    /// Copy text to clipboard
    func copyToClipboard(_ entry: TranscriptionHistoryEntry) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.text, forType: .string)
    }
}
