//
//  Surah.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

struct Surah: Codable, Identifiable, Hashable, Sendable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let revelationType: String
    let numberOfAyahs: Int

    var id: Int { number }
}

struct SurahWithAyahs: Codable, Identifiable, Hashable, Sendable {
    let surah: Surah
    let ayahs: [Ayah]

    var id: Int { surah.number }
}
