//
//  AppSettings.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

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

enum QuranScriptChoice: String, Codable, CaseIterable, Sendable {
    case uthmani
    case indopak

    var displayName: String {
        switch self {
        case .uthmani: "Uthmani (Madina)"
        case .indopak: "Indo-Pak"
        }
    }

    var preferredArabicFont: ArabicFontChoice {
        switch self {
        case .uthmani: .amiriQuran
        case .indopak: .notoNaskhArabic
        }
    }
}

enum ArabicFontChoice: String, Codable, CaseIterable, Sendable {
    case amiriQuran
    case notoNaskhArabic
    case systemSerif

    var displayName: String {
        switch self {
        case .amiriQuran: "Amiri Quran"
        case .notoNaskhArabic: "Noto Naskh Arabic"
        case .systemSerif: "System Serif"
        }
    }

    var postScriptName: String? {
        switch self {
        case .amiriQuran: "AmiriQuran-Regular"
        case .notoNaskhArabic: "NotoNaskhArabic-Regular"
        case .systemSerif: nil
        }
    }
}

enum UrduFontChoice: String, Codable, CaseIterable, Sendable {
    case notoNastaliq
    case system

    var displayName: String {
        switch self {
        case .notoNastaliq: "Noto Nastaliq Urdu"
        case .system: "System"
        }
    }

    var postScriptName: String? {
        switch self {
        case .notoNastaliq: "NotoNastaliqUrdu-Regular"
        case .system: nil
        }
    }
}

struct AppSettings: Codable, Hashable, Sendable {
    var fontSize: Double
    var theme: AppThemeMode
    var showEnglishTranslation: Bool
    var quranScript: QuranScriptChoice
    var arabicFont: ArabicFontChoice
    var urduFont: UrduFontChoice

    static let `default` = AppSettings(
        fontSize: 22,
        theme: .dark,
        showEnglishTranslation: false,
        quranScript: .indopak,
        arabicFont: .notoNaskhArabic,
        urduFont: .notoNastaliq
    )

    init(
        fontSize: Double,
        theme: AppThemeMode,
        showEnglishTranslation: Bool,
        quranScript: QuranScriptChoice = .indopak,
        arabicFont: ArabicFontChoice = .notoNaskhArabic,
        urduFont: UrduFontChoice = .notoNastaliq
    ) {
        self.fontSize = fontSize
        self.theme = theme
        self.showEnglishTranslation = showEnglishTranslation
        self.quranScript = quranScript
        self.arabicFont = arabicFont
        self.urduFont = urduFont
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fontSize = try container.decode(Double.self, forKey: .fontSize)
        theme = try container.decode(AppThemeMode.self, forKey: .theme)
        showEnglishTranslation = try container.decodeIfPresent(Bool.self, forKey: .showEnglishTranslation) ?? false
        quranScript = try container.decodeIfPresent(QuranScriptChoice.self, forKey: .quranScript) ?? .indopak
        arabicFont = try container.decodeIfPresent(ArabicFontChoice.self, forKey: .arabicFont) ?? .notoNaskhArabic
        urduFont = try container.decodeIfPresent(UrduFontChoice.self, forKey: .urduFont) ?? .notoNastaliq
    }
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
