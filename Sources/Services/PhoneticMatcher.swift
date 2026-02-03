import Foundation

/// Provides phonetic matching using multiple algorithms for robust matching
class PhoneticMatcher {

    /// Minimum similarity score (0-1) for fuzzy matching
    private let minSimilarityScore: Double = 0.7

    /// Replace words in text that phonetically match the target word
    /// - Parameters:
    ///   - text: The input text to process
    ///   - target: The correct word to use as replacement
    ///   - pronunciation: Optional phonetic hint for matching
    /// - Returns: Text with phonetically similar words replaced
    func replacePhoneticMatches(in text: String, target: String, pronunciation: String?) -> String {
        let words = text.components(separatedBy: .whitespaces)
        let matchKey = pronunciation ?? target

        // Pre-compute phonetic codes for target
        let targetSoundex = soundex(matchKey)
        let targetMetaphone = metaphone(matchKey)

        guard !targetSoundex.isEmpty || !targetMetaphone.isEmpty else { return text }

        var result: [String] = []

        for word in words {
            // Preserve punctuation
            let (prefix, core, suffix) = extractPunctuation(from: word)

            // Skip if already matches target
            guard core.lowercased() != target.lowercased() else {
                result.append(word)
                continue
            }

            // Check if word matches using any of our matching strategies
            if isPhoneticMatch(word: core, target: target, matchKey: matchKey,
                             targetSoundex: targetSoundex, targetMetaphone: targetMetaphone) {
                result.append("\(prefix)\(target)\(suffix)")
            } else {
                result.append(word)
            }
        }

        return result.joined(separator: " ")
    }

    /// Check if a word matches the target using multiple phonetic strategies
    private func isPhoneticMatch(word: String, target: String, matchKey: String,
                                  targetSoundex: String, targetMetaphone: String) -> Bool {
        let wordLower = word.lowercased()
        let targetLower = target.lowercased()

        // Strategy 1: Soundex match (traditional)
        let wordSoundex = soundex(word)
        if !wordSoundex.isEmpty && wordSoundex == targetSoundex && isLengthSimilar(word, to: target) {
            return true
        }

        // Strategy 2: Metaphone match (better for English phonetics)
        let wordMetaphone = metaphone(word)
        if !wordMetaphone.isEmpty && wordMetaphone == targetMetaphone && isLengthSimilar(word, to: target) {
            return true
        }

        // Strategy 3: Fuzzy string matching using normalized Levenshtein distance
        let similarity = normalizedLevenshteinSimilarity(wordLower, targetLower)
        if similarity >= minSimilarityScore {
            return true
        }

        // Strategy 4: Check if phonetic codes are similar (not exact) with high string similarity
        let soundexSimilarity = normalizedLevenshteinSimilarity(wordSoundex, targetSoundex)
        let metaphoneSimilarity = normalizedLevenshteinSimilarity(wordMetaphone, targetMetaphone)
        if (soundexSimilarity >= 0.75 || metaphoneSimilarity >= 0.75) && similarity >= 0.6 {
            return true
        }

        return false
    }

    /// Extract leading and trailing punctuation from a word
    private func extractPunctuation(from word: String) -> (prefix: String, core: String, suffix: String) {
        var prefix = ""
        var suffix = ""
        var core = word

        // Extract leading punctuation
        while let first = core.first, first.isPunctuation {
            prefix.append(first)
            core.removeFirst()
        }

        // Extract trailing punctuation
        while let last = core.last, last.isPunctuation {
            suffix = String(last) + suffix
            core.removeLast()
        }

        return (prefix, core, suffix)
    }

    /// Soundex algorithm for phonetic encoding
    /// Returns a 4-character code representing the phonetic sound
    func soundex(_ string: String) -> String {
        let normalized = string.lowercased().filter { $0.isLetter }
        guard let first = normalized.first else { return "" }

        let mapping: [Character: Character] = [
            "b": "1", "f": "1", "p": "1", "v": "1",
            "c": "2", "g": "2", "j": "2", "k": "2", "q": "2", "s": "2", "x": "2", "z": "2",
            "d": "3", "t": "3",
            "l": "4",
            "m": "5", "n": "5",
            "r": "6"
        ]

        var code = String(first).uppercased()
        var lastCode: Character? = mapping[first]

        for char in normalized.dropFirst() {
            if let digit = mapping[char], digit != lastCode {
                code.append(digit)
                lastCode = digit
            } else if mapping[char] == nil {
                lastCode = nil
            }

            if code.count == 4 { break }
        }

        // Pad with zeros if needed
        while code.count < 4 {
            code.append("0")
        }

        return code
    }

    /// Check if two words have similar length (within 20% difference)
    private func isLengthSimilar(_ word1: String, to word2: String) -> Bool {
        guard !word1.isEmpty && !word2.isEmpty else { return false }
        let ratio = Double(min(word1.count, word2.count)) / Double(max(word1.count, word2.count))
        return ratio >= 0.8
    }

    // MARK: - Metaphone Algorithm

    /// Metaphone algorithm for better English phonetic encoding
    /// More accurate than Soundex for English pronunciation
    func metaphone(_ string: String) -> String {
        let normalized = string.lowercased().filter { $0.isLetter }
        guard !normalized.isEmpty else { return "" }

        var result = ""
        let chars = Array(normalized)
        var i = 0

        // Handle special beginning cases
        if chars.count >= 2 {
            let prefix = String(chars.prefix(2))
            switch prefix {
            case "kn", "gn", "pn", "ae", "wr":
                i = 1
            case "wh":
                result.append("W")
                i = 2
            default:
                break
            }
        }

        if i == 0 && chars[0] == "x" {
            result.append("S")
            i = 1
        }

        while i < chars.count {
            let char = chars[i]
            let prev = i > 0 ? chars[i - 1] : nil
            let next = i + 1 < chars.count ? chars[i + 1] : nil
            let nextNext = i + 2 < chars.count ? chars[i + 2] : nil

            // Skip duplicates
            if char == prev {
                i += 1
                continue
            }

            switch char {
            case "a", "e", "i", "o", "u":
                // Vowels only at the beginning
                if i == 0 || (i == 1 && result.isEmpty) {
                    result.append(Character(char.uppercased()))
                }

            case "b":
                // B is silent after M at end of word
                if !(prev == "m" && next == nil) {
                    result.append("P")
                }

            case "c":
                if next == "i" || next == "e" || next == "y" {
                    result.append("S")
                } else if next == "h" {
                    result.append("X")
                    i += 1
                } else {
                    result.append("K")
                }

            case "d":
                if next == "g" && (nextNext == "e" || nextNext == "y" || nextNext == "i") {
                    result.append("J")
                    i += 1
                } else {
                    result.append("T")
                }

            case "f":
                result.append("F")

            case "g":
                if next == "h" {
                    // GH is often silent or F
                    if nextNext != nil && !"aeiou".contains(nextNext!) {
                        i += 1
                    } else {
                        result.append("F")
                        i += 1
                    }
                } else if next == "n" && nextNext == nil {
                    // GN at end is silent
                    break
                } else if next == "i" || next == "e" || next == "y" {
                    result.append("J")
                } else {
                    result.append("K")
                }

            case "h":
                // H is pronounced if followed by vowel and not after vowel
                if let next = next, "aeiou".contains(next) {
                    if prev == nil || !"aeiou".contains(prev!) {
                        result.append("H")
                    }
                }

            case "j":
                result.append("J")

            case "k":
                if prev != "c" {
                    result.append("K")
                }

            case "l":
                result.append("L")

            case "m":
                result.append("M")

            case "n":
                result.append("N")

            case "p":
                if next == "h" {
                    result.append("F")
                    i += 1
                } else {
                    result.append("P")
                }

            case "q":
                result.append("K")

            case "r":
                result.append("R")

            case "s":
                if next == "h" {
                    result.append("X")
                    i += 1
                } else if next == "i" && (nextNext == "o" || nextNext == "a") {
                    result.append("X")
                } else {
                    result.append("S")
                }

            case "t":
                if next == "i" && (nextNext == "o" || nextNext == "a") {
                    result.append("X")
                } else if next == "h" {
                    result.append("0") // TH sound
                    i += 1
                } else if !(next == "c" && nextNext == "h") {
                    result.append("T")
                }

            case "v":
                result.append("F")

            case "w":
                if let next = next, "aeiou".contains(next) {
                    result.append("W")
                }

            case "x":
                result.append("KS")

            case "y":
                if let next = next, "aeiou".contains(next) {
                    result.append("Y")
                }

            case "z":
                result.append("S")

            default:
                break
            }

            i += 1
        }

        return result
    }

    // MARK: - Levenshtein Distance

    /// Calculate Levenshtein distance between two strings
    func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)

        if s1Array.isEmpty { return s2Array.count }
        if s2Array.isEmpty { return s1Array.count }

        var previousRow = Array(0...s2Array.count)
        var currentRow = [Int](repeating: 0, count: s2Array.count + 1)

        for i in 0..<s1Array.count {
            currentRow[0] = i + 1

            for j in 0..<s2Array.count {
                let insertions = previousRow[j + 1] + 1
                let deletions = currentRow[j] + 1
                let substitutions = previousRow[j] + (s1Array[i] == s2Array[j] ? 0 : 1)
                currentRow[j + 1] = min(insertions, deletions, substitutions)
            }

            previousRow = currentRow
        }

        return previousRow[s2Array.count]
    }

    /// Calculate normalized similarity (0-1) based on Levenshtein distance
    func normalizedLevenshteinSimilarity(_ s1: String, _ s2: String) -> Double {
        if s1.isEmpty && s2.isEmpty { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }

        let distance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        return 1.0 - (Double(distance) / Double(maxLength))
    }
}
