//
//  Juz.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

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
