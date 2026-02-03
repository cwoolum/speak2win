import Foundation

/// A single entry in the personal dictionary
struct DictionaryEntry: Codable, Identifiable, Hashable {
    let id: UUID
    var word: String
    var pronunciation: String?
    var language: SupportedLanguage
    var aliases: [String]
    var category: EntryCategory
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        word: String,
        pronunciation: String? = nil,
        language: SupportedLanguage = .english,
        aliases: [String] = [],
        category: EntryCategory = .custom,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.word = word
        self.pronunciation = pronunciation
        self.language = language
        self.aliases = aliases
        self.category = category
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Categories for organizing dictionary entries
enum EntryCategory: String, Codable, CaseIterable {
    case name
    case technical
    case brand
    case medical
    case legal
    case custom

    var displayName: String {
        switch self {
        case .name: return "Names"
        case .technical: return "Technical Terms"
        case .brand: return "Brands & Products"
        case .medical: return "Medical"
        case .legal: return "Legal"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .name: return "person.fill"
        case .technical: return "wrench.and.screwdriver.fill"
        case .brand: return "building.2.fill"
        case .medical: return "cross.case.fill"
        case .legal: return "doc.text.fill"
        case .custom: return "star.fill"
        }
    }
}

/// All languages supported by Parakeet v3 (25 languages)
enum SupportedLanguage: String, Codable, CaseIterable {
    case english = "en"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    case portuguese = "pt"
    case dutch = "nl"
    case polish = "pl"
    case romanian = "ro"
    case czech = "cs"
    case hungarian = "hu"
    case greek = "el"
    case bulgarian = "bg"
    case slovak = "sk"
    case danish = "da"
    case finnish = "fi"
    case swedish = "sv"
    case norwegian = "no"
    case croatian = "hr"
    case slovenian = "sl"
    case estonian = "et"
    case latvian = "lv"
    case lithuanian = "lt"
    case maltese = "mt"
    case irish = "ga"

    var displayName: String {
        Locale.current.localizedString(forLanguageCode: rawValue) ?? rawValue.uppercased()
    }

    static var defaultLanguage: SupportedLanguage { .english }
}
