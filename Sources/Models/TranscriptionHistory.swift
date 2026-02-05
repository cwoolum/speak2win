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

    /// Formatted time for the metadata footer (e.g., "2:34 PM")
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

/// Date sections for grouping history entries
enum DateSection: String, CaseIterable, Hashable {
    case today = "Today"
    case yesterday = "Yesterday"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case older = "Older"

    static func from(_ date: Date) -> DateSection {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return .today
        } else if calendar.isDateInYesterday(date) {
            return .yesterday
        } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                  date >= weekAgo {
            return .last7Days
        } else if let monthAgo = calendar.date(byAdding: .day, value: -30, to: now),
                  date >= monthAgo {
            return .last30Days
        } else {
            return .older
        }
    }
}
