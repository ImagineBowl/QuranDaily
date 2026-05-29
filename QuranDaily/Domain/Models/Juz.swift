import Foundation

struct Juz: Codable, Identifiable, Hashable, Sendable {
    let number: Int
    let startSurah: Int
    let startAyah: Int

    var id: Int { number }

    var displayName: String {
        "Juz \(number)"
    }
}
