//
//  AppSemanticVersion.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 05/06/2026.
//

import Foundation

struct AppSemanticVersion: Comparable, Equatable, Sendable {
    private let components: [Int]

    init(_ string: String) {
        components = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ".", omittingEmptySubsequences: false)
            .map { Int($0) ?? 0 }
    }

    static func < (lhs: AppSemanticVersion, rhs: AppSemanticVersion) -> Bool {
        compare(lhs, rhs) == .orderedAscending
    }

    static func == (lhs: AppSemanticVersion, rhs: AppSemanticVersion) -> Bool {
        compare(lhs, rhs) == .orderedSame
    }

    private static func compare(_ lhs: AppSemanticVersion, _ rhs: AppSemanticVersion) -> ComparisonResult {
        let maxCount = max(lhs.components.count, rhs.components.count)
        for index in 0..<maxCount {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right {
                return left < right ? .orderedAscending : .orderedDescending
            }
        }
        return .orderedSame
    }
}
