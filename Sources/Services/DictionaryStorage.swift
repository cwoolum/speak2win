import Foundation

class DictionaryStorage {
    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let speak2Dir = appSupport.appendingPathComponent("Speak2")

        // Create directory if needed
        if !FileManager.default.fileExists(atPath: speak2Dir.path) {
            try? FileManager.default.createDirectory(at: speak2Dir, withIntermediateDirectories: true)
        }

        return speak2Dir.appendingPathComponent("personal_dictionary.json")
    }

    func load() -> [DictionaryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([DictionaryEntry].self, from: data)
        } catch {
            print("Failed to load dictionary: \(error)")
            return []
        }
    }

    func save(_ entries: [DictionaryEntry]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }

    func exportToJSON(_ entries: [DictionaryEntry]) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(entries)
    }

    func importFromJSON(_ data: Data) throws -> [DictionaryEntry] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([DictionaryEntry].self, from: data)
    }
}
