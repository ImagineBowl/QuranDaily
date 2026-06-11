//
//  Ayah.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

struct Ayah: Codable, Identifiable, Hashable, Sendable {
    let number: Int
    let numberInSurah: Int
    let surahNumber: Int
    let arabicTextUthmani: String
    let arabicTextIndopak: String
    let urduText: String
    let juz: Int
    let page: Int

    var id: Int { number }

    var displayReference: String {
        "\(surahNumber):\(numberInSurah)"
    }

    func arabicText(for script: QuranScriptChoice) -> String {
        switch script {
        case .uthmani:
            return arabicTextUthmani.sanitizedForQuranDisplay
        case .indopak:
            let indopak = arabicTextIndopak.isEmpty ? arabicTextUthmani : arabicTextIndopak
            return indopak.sanitizedForQuranDisplay
        }
    }

    enum CodingKeys: String, CodingKey {
        case number
        case numberInSurah
        case surahNumber
        case arabicTextUthmani
        case arabicTextIndopak
        case arabicText
        case urduText
        case juz
        case page
    }

    init(
        number: Int,
        numberInSurah: Int,
        surahNumber: Int,
        arabicTextUthmani: String,
        arabicTextIndopak: String = "",
        urduText: String,
        juz: Int,
        page: Int
    ) {
        self.number = number
        self.numberInSurah = numberInSurah
        self.surahNumber = surahNumber
        self.arabicTextUthmani = arabicTextUthmani
        self.arabicTextIndopak = arabicTextIndopak
        self.urduText = urduText
        self.juz = juz
        self.page = page
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        numberInSurah = try container.decode(Int.self, forKey: .numberInSurah)
        surahNumber = try container.decode(Int.self, forKey: .surahNumber)
        urduText = try container.decode(String.self, forKey: .urduText)
        juz = try container.decode(Int.self, forKey: .juz)
        page = try container.decode(Int.self, forKey: .page)

        if let uthmani = try container.decodeIfPresent(String.self, forKey: .arabicTextUthmani) {
            arabicTextUthmani = uthmani
        } else {
            arabicTextUthmani = try container.decode(String.self, forKey: .arabicText)
        }

        arabicTextIndopak = try container.decodeIfPresent(String.self, forKey: .arabicTextIndopak) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(number, forKey: .number)
        try container.encode(numberInSurah, forKey: .numberInSurah)
        try container.encode(surahNumber, forKey: .surahNumber)
        try container.encode(arabicTextUthmani, forKey: .arabicTextUthmani)
        try container.encode(arabicTextIndopak, forKey: .arabicTextIndopak)
        try container.encode(urduText, forKey: .urduText)
        try container.encode(juz, forKey: .juz)
        try container.encode(page, forKey: .page)
    }
}

struct ReadingPosition: Codable, Hashable, Sendable {
    let surahNumber: Int
    let ayahNumber: Int
    let scrollAnchor: String?

    /// No saved reading history yet (first launch or never opened the reader).
    static let `default` = ReadingPosition(surahNumber: 0, ayahNumber: 0, scrollAnchor: nil)

    var hasSavedPosition: Bool { surahNumber > 0 }
}
