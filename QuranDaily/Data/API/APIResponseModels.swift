import Foundation

struct QuranEditionResponse: Decodable, Sendable {
    let code: Int
    let status: String
    let data: QuranEditionData
}

struct QuranEditionData: Decodable, Sendable {
    let surahs: [APISurah]
}

struct APISurah: Decodable, Sendable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let revelationType: String
    let ayahs: [APIAyah]
}

struct APIAyah: Decodable, Sendable {
    let number: Int
    let text: String
    let numberInSurah: Int
    let juz: Int
    let page: Int
}

struct MetaResponse: Decodable, Sendable {
    let code: Int
    let status: String
    let data: MetaData
}

struct MetaData: Decodable, Sendable {
    let surahs: MetaSurahs
    let juzs: MetaJuzs
}

struct MetaSurahs: Decodable, Sendable {
    let references: [MetaSurahReference]
}

struct MetaSurahReference: Decodable, Sendable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String
}

struct MetaJuzs: Decodable, Sendable {
    let references: [MetaJuzReference]
}

struct MetaJuzReference: Decodable, Sendable {
    let surah: Int
    let ayah: Int
}

struct StoredQuranBundle: Codable, Sendable {
    let surahs: [Surah]
    let ayahsBySurah: [Int: [Ayah]]
    let juzs: [Juz]
}

enum StoragePaths {
    static let quranBundle = "quran_bundle.json"
    static let bookmarks = "bookmarks.json"
    static let settings = "settings.json"
    static let readingPosition = "reading_position.json"
    static let audioDirectory = "Audio"
}

enum QuranError: LocalizedError, Equatable {
    case notDownloaded
    case invalidResponse
    case surahNotFound(Int)
    case ayahNotFound
    case audioNotAvailable
    case audioNotDownloaded
    case downloadFailed(String)
    case storageFailed(String)

    var errorDescription: String? {
        switch self {
        case .notDownloaded:
            "Quran data is not downloaded yet."
        case .invalidResponse:
            "Received an invalid response from the server."
        case .surahNotFound(let number):
            "Surah \(number) was not found."
        case .ayahNotFound:
            "Ayah was not found."
        case .audioNotAvailable:
            "Audio is not available for this surah."
        case .audioNotDownloaded:
            "Audio is not downloaded. Tap Download to save this surah for offline listening."
        case .downloadFailed(let message):
            "Download failed: \(message)"
        case .storageFailed(let message):
            "Storage error: \(message)"
        }
    }
}
