//
//  AppUpdateService.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 05/06/2026.
//

import Foundation

protocol AppUpdateServiceProtocol: Sendable {
    func checkForSoftUpdate(force: Bool) async -> AppUpdatePrompt?
    func markSoftUpdateDismissed(for version: String)
}

final class AppUpdateService: AppUpdateServiceProtocol, @unchecked Sendable {
    private let fetchConfig: @Sendable () async throws -> AppUpdateConfig
    private let installedVersion: String
    private let userDefaults: UserDefaults
    private let checkInterval: TimeInterval

    private enum Keys {
        static let dismissedSoftUpdateVersion = "dismissedSoftUpdateVersion"
        static let lastUpdateCheckDate = "lastAppUpdateCheckDate"
    }

    init(
        fetchConfig: @escaping @Sendable () async throws -> AppUpdateConfig = AppUpdateService.fetchRemoteConfig,
        installedVersion: String = AppInfo.marketingVersion,
        userDefaults: UserDefaults = .standard,
        checkInterval: TimeInterval = 24 * 60 * 60
    ) {
        self.fetchConfig = fetchConfig
        self.installedVersion = installedVersion
        self.userDefaults = userDefaults
        self.checkInterval = checkInterval
    }

    func checkForSoftUpdate(force: Bool) async -> AppUpdatePrompt? {
        if !force && shouldSkipDueToRecentCheck() {
            return nil
        }

        guard let config = try? await fetchConfig() else {
            return nil
        }

        userDefaults.set(Date().timeIntervalSince1970, forKey: Keys.lastUpdateCheckDate)

        guard let appStoreURL = config.resolvedAppStoreURL else {
            return nil
        }

        let current = AppSemanticVersion(installedVersion)
        let latest = AppSemanticVersion(config.latestVersion)

        guard current < latest else {
            return nil
        }

        if !force {
            let dismissed = userDefaults.string(forKey: Keys.dismissedSoftUpdateVersion)
            if dismissed == config.latestVersion {
                return nil
            }
        }

        let message = config.updateMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedMessage = (message?.isEmpty == false)
            ? message!
            : "A new version of QuranDaily is available with improvements and fixes."

        return AppUpdatePrompt(
            latestVersion: config.latestVersion,
            message: resolvedMessage,
            appStoreURL: appStoreURL
        )
    }

    func markSoftUpdateDismissed(for version: String) {
        userDefaults.set(version, forKey: Keys.dismissedSoftUpdateVersion)
    }

    private func shouldSkipDueToRecentCheck() -> Bool {
        let lastCheck = userDefaults.double(forKey: Keys.lastUpdateCheckDate)
        guard lastCheck > 0 else { return false }
        return Date().timeIntervalSince1970 - lastCheck < checkInterval
    }

    private static func fetchRemoteConfig() async throws -> AppUpdateConfig {
        let (data, response) = try await URLSession.shared.data(from: AppInfo.appConfigURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw QuranError.invalidResponse
        }
        return try JSONDecoder().decode(AppUpdateConfig.self, from: data)
    }
}
