import Foundation

enum SearchMode: String, CaseIterable, Identifiable, Sendable {
    case ayah
    case surah
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .surah: "Surah"
        case .ayah: "Ayah"
        case .text: "Text"
        }
    }

    var searchPrompt: String {
        switch self {
        case .surah: "Surah name or number"
        case .ayah: "Filter surahs"
        case .text: "Arabic or Urdu text"
        }
    }

    var emptyDescription: String {
        switch self {
        case .surah:
            "Type a surah name or number, then tap Read & Listen."
        case .ayah:
            "Choose a surah and ayah number below, then tap Read & Listen."
        case .text:
            "Search for matching words or phrases inside ayah text."
        }
    }

    var usesTextSearchBar: Bool {
        switch self {
        case .surah, .text: true
        case .ayah: false
        }
    }
}

enum AyahReferenceParser {
    enum Reference: Equatable {
        case surahAyah(surah: Int, ayah: Int)
        case absoluteNumber(Int)
    }

    static func parse(_ query: String, surahs: [Surah] = []) -> Reference? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let hasSeparator = trimmed.contains { ":./- \t".contains($0) }
        if hasSeparator {
            guard let lastSeparatorIndex = trimmed.lastIndex(where: { ":./- \t".contains($0) }) else {
                return nil
            }

            let surahPart = String(trimmed[..<lastSeparatorIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let ayahPart = String(trimmed[trimmed.index(after: lastSeparatorIndex)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !surahPart.isEmpty, let ayah = Int(ayahPart), ayah >= 1 else {
                return nil
            }

            if let surahNumber = Int(surahPart), (1...114).contains(surahNumber) {
                return .surahAyah(surah: surahNumber, ayah: ayah)
            }

            if let surahNumber = surahNumber(matching: surahPart, in: surahs) {
                return .surahAyah(surah: surahNumber, ayah: ayah)
            }

            return nil
        }

        if let absolute = Int(trimmed), (1...6236).contains(absolute) {
            return .absoluteNumber(absolute)
        }

        return nil
    }

    static func surahNumber(matching name: String, in surahs: [Surah]) -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let number = Int(trimmed), (1...114).contains(number) {
            return number
        }

        let query = foldTransliteration(trimmed)

        for surah in surahs {
            if foldTransliteration(surah.englishName) == query { return surah.number }
            if foldTransliteration(surah.englishNameTranslation) == query { return surah.number }
        }

        for surah in surahs {
            let english = foldTransliteration(surah.englishName)
            let translation = foldTransliteration(surah.englishNameTranslation)

            if english.hasPrefix(query) || query.hasPrefix(english) { return surah.number }
            if translation.hasPrefix(query) || query.hasPrefix(translation) { return surah.number }
            if surah.name.contains(trimmed) { return surah.number }
        }

        return nil
    }

    private static func foldTransliteration(_ value: String) -> String {
        normalizeName(value)
            .replacingOccurrences(of: "ee", with: "i")
            .replacingOccurrences(of: "oo", with: "u")
    }

    private static func normalizeName(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "'", with: "")
    }
}
