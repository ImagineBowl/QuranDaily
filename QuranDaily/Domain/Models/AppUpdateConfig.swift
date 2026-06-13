//
//  AppUpdateConfig.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 05/06/2026.
//

import Foundation

struct AppUpdateConfig: Decodable, Sendable {
    let latestVersion: String
    let minimumRequiredVersion: String?
    let updateMessage: String?
    let appStoreURL: String

    var resolvedAppStoreURL: URL? {
        URL(string: appStoreURL.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

struct AppUpdatePrompt: Equatable, Sendable {
    let latestVersion: String
    let message: String
    let appStoreURL: URL
}
