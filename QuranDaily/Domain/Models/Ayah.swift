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
    let arabicText: String
    let urduText: String
    let juz: Int
    let page: Int

    var id: Int { number }

    var displayReference: String {
        "\(surahNumber):\(numberInSurah)"
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
