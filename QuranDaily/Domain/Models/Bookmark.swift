//
//  Bookmark.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

struct Bookmark: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let surahNumber: Int
    let ayahNumber: Int
    let surahName: String
    let arabicPreview: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        surahNumber: Int,
        ayahNumber: Int,
        surahName: String,
        arabicPreview: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.surahName = surahName
        self.arabicPreview = arabicPreview
        self.createdAt = createdAt
    }

    var displayReference: String {
        "\(surahName) \(surahNumber):\(ayahNumber)"
    }
}
