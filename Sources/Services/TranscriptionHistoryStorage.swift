import Foundation

class TranscriptionHistoryStorage {
    private static let maxEntries = 20
    private static let maxTextLength = 10_000  // Prevent huge transcriptions from bloating file

    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let speak2Dir = appSupport.appendingPathComponent("Speak2")

        // Create directory if needed
        if !FileManager.default.fileExists(atPath: speak2Dir.path) {
            try? FileManager.default.createDirectory(at: speak2Dir, withIntermediateDirectories: true)
        }

        return speak2Dir.appendingPathComponent("transcription_history.json")
    }

    func load() -> [TranscriptionHistoryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([TranscriptionHistoryEntry].self, from: data)
        } catch {
            print("Failed to load transcription history: \(error)")
            return []
        }
    }

    func save(_ entries: [TranscriptionHistoryEntry]) throws {
        // Auto-trim to keep only most recent entries
        let trimmed = Array(entries.prefix(Self.maxEntries))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(trimmed)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Truncate text if it exceeds max length
    static func truncateIfNeeded(_ text: String) -> String {
        if text.count > maxTextLength {
            return String(text.prefix(maxTextLength))
        }
        return text
    }

    func exportToJSON(_ entries: [TranscriptionHistoryEntry]) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(entries)
    }

    func clearAll() throws {
        try save([])
    }
}
