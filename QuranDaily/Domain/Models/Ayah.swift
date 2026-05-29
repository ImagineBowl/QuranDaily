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

    static let `default` = ReadingPosition(surahNumber: 1, ayahNumber: 1, scrollAnchor: nil)
}
