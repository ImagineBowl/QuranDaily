import Foundation
import SwiftUI

enum AppThemeMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct AppSettings: Codable, Hashable, Sendable {
    var fontSize: Double
    var theme: AppThemeMode
    var showEnglishTranslation: Bool

    static let `default` = AppSettings(
        fontSize: 22,
        theme: .dark,
        showEnglishTranslation: false
    )
}

enum DownloadProgress: Equatable, Sendable {
    case idle
    case downloading(message: String, fraction: Double)
    case completed
    case failed(message: String)
}

struct StorageInfo: Equatable, Sendable {
    let quranDataBytes: Int64
    let audioBytes: Int64

    var totalBytes: Int64 { quranDataBytes + audioBytes }

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    var formattedQuranData: String {
        ByteCountFormatter.string(fromByteCount: quranDataBytes, countStyle: .file)
    }

    var formattedAudio: String {
        ByteCountFormatter.string(fromByteCount: audioBytes, countStyle: .file)
    }
}

struct SearchResult: Identifiable, Hashable, Sendable {
    let id: String
    let surahNumber: Int
    let ayahNumber: Int
    let surahName: String
    let arabicText: String
    let urduText: String
    let matchType: MatchType
    let absoluteAyahNumber: Int?

    init(
        id: String,
        surahNumber: Int,
        ayahNumber: Int,
        surahName: String,
        arabicText: String,
        urduText: String,
        matchType: MatchType,
        absoluteAyahNumber: Int? = nil
    ) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.surahName = surahName
        self.arabicText = arabicText
        self.urduText = urduText
        self.matchType = matchType
        self.absoluteAyahNumber = absoluteAyahNumber
    }

    enum MatchType: String, Sendable {
        case surahName
        case surahNumber
        case juz
        case text
        case ayahReference
    }

    var displayReference: String {
        "\(surahNumber):\(ayahNumber)"
    }
}
