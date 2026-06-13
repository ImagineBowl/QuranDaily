//
//  AppUpdateViewModel.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 05/06/2026.
//

import Foundation
import UIKit

@MainActor
@Observable
final class AppUpdateViewModel {
    private let appUpdateService: AppUpdateServiceProtocol

    var pendingPrompt: AppUpdatePrompt?
    var isChecking = false
    var checkStatusMessage: String?

    init(appUpdateService: AppUpdateServiceProtocol) {
        self.appUpdateService = appUpdateService
    }

    func checkOnLaunch() async {
        await evaluateUpdate(force: false)
    }

    func checkForUpdates() async {
        checkStatusMessage = nil
        await evaluateUpdate(force: true)
        if pendingPrompt == nil {
            checkStatusMessage = "You're on the latest version."
        }
    }

    func dismissPendingUpdate() {
        guard let pendingPrompt else { return }
        appUpdateService.markSoftUpdateDismissed(for: pendingPrompt.latestVersion)
        self.pendingPrompt = nil
    }

    func openAppStore() {
        guard let url = pendingPrompt?.appStoreURL else { return }
        UIApplication.shared.open(url)
    }

    private func evaluateUpdate(force: Bool) async {
        isChecking = true
        defer { isChecking = false }

        if let prompt = await appUpdateService.checkForSoftUpdate(force: force) {
            pendingPrompt = prompt
        } else if force {
            pendingPrompt = nil
        }
    }
}
