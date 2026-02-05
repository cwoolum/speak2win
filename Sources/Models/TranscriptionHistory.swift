import Foundation

/// A single entry in the transcription history
struct TranscriptionHistoryEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let text: String                    // Final processed transcription text
    let timestamp: Date                  // When transcription completed
    let modelUsed: String               // TranscriptionModel.displayName
    let language: SupportedLanguage     // Language used for transcription
    let audioLength: TimeInterval?      // Optional: length of audio in seconds

    init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date = Date(),
        modelUsed: String,
        language: SupportedLanguage,
        audioLength: TimeInterval? = nil
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.modelUsed = modelUsed
        self.language = language
        self.audioLength = audioLength
    }

    /// Truncated text for display in list (first 50 chars + ellipsis)
    var displayText: String {
        if text.count > 50 {
            return String(text.prefix(50)) + "..."
        }
        return text
    }

    /// Formatted timestamp for display
    var displayTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
