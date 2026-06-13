//
//  AppInfo.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 04/06/2026.
//

import Foundation

enum AppInfo {
    static let displayName = "QuranDaily"

    /// Publish at this URL before App Store submission (GitHub Pages, Notion, etc.).
    static let privacyPolicyURL = URL(string: "https://imaginebowl.github.io/QuranDaily/privacy")!

    /// Remote config for soft App Store update prompts. Bump `latestVersion` on each release.
    static let appConfigURL = URL(string: "https://imaginebowl.github.io/QuranDaily/app-config.json")!

    static let supportEmail = "ahsan.minhas.official@gmail.com"

    static let supportURL = URL(string: "mailto:\(supportEmail)")!

    static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    static var versionDisplay: String {
        "\(marketingVersion) (\(buildNumber))"
    }
}
