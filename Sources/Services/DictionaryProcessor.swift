import Foundation

/// Processes transcribed text using the personal dictionary
/// Replaces misheard words with correct dictionary entries
class DictionaryProcessor {
    private let phoneticMatcher = PhoneticMatcher()

    /// Process transcribed text, replacing misheard words with dictionary entries
    /// - Parameters:
    ///   - text: The transcribed text to process
    ///   - entries: Dictionary entries to use for replacement
    ///   - language: The language to filter entries by
    /// - Returns: Processed text with replacements applied
    func process(_ text: String, using entries: [DictionaryEntry], language: SupportedLanguage) -> String {
        guard !text.isEmpty else { return text }

        let relevantEntries = entries.filter { $0.language == language && $0.isEnabled }
        guard !relevantEntries.isEmpty else { return text }

        var result = text

        for entry in relevantEntries {
            // Step 1: Direct alias replacement (exact match, case-insensitive)
            for alias in entry.aliases {
                result = replaceWholeWord(in: result, find: alias, with: entry.word)
            }

            // Step 2: Phonetic fuzzy matching
            // Uses pronunciation hint if provided, otherwise matches against the word itself
            result = phoneticMatcher.replacePhoneticMatches(
                in: result,
                target: entry.word,
                pronunciation: entry.pronunciation
            )
        }

        return result
    }

    /// Replace whole words only (not partial matches)
    private func replaceWholeWord(in text: String, find: String, with replacement: String) -> String {
        // Use word boundary matching
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: find))\\b"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }

        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }
}
