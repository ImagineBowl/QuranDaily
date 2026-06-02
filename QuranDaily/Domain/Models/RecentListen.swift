import Foundation

struct RecentListen: Codable, Identifiable, Equatable, Sendable {
    var id: Int { surahNumber }
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    let listenedAt: Date

    init(
        surahNumber: Int,
        surahName: String,
        ayahNumber: Int,
        listenedAt: Date = Date()
    ) {
        self.surahNumber = surahNumber
        self.surahName = surahName
        self.ayahNumber = ayahNumber
        self.listenedAt = listenedAt
    }
}
