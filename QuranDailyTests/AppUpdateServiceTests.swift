//
//  AppUpdateServiceTests.swift
//  QuranDailyTests
//
//  Created by Ahsan Minhas on 05/06/2026.
//

import XCTest
#if SWIFT_PACKAGE
@testable import QuranDailyCore
#else
@testable import QuranDaily
#endif

final class AppUpdateServiceTests: XCTestCase {
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "AppUpdateServiceTests")!
        userDefaults.removePersistentDomain(forName: "AppUpdateServiceTests")
    }

    func testReturnsPromptWhenRemoteVersionIsNewer() async {
        let service = AppUpdateService(
            fetchConfig: { Self.sampleConfig },
            installedVersion: "1.0.0",
            userDefaults: userDefaults,
            checkInterval: 0
        )

        let prompt = await service.checkForSoftUpdate(force: true)

        XCTAssertEqual(prompt?.latestVersion, "1.0.1")
        XCTAssertEqual(prompt?.message, "New fixes are available.")
        XCTAssertEqual(prompt?.appStoreURL.absoluteString, "https://apps.apple.com/app/id1234567890")
    }

    func testReturnsNilWhenAlreadyOnLatestVersion() async {
        let service = AppUpdateService(
            fetchConfig: {
                AppUpdateConfig(
                    latestVersion: "1.0.0",
                    minimumRequiredVersion: nil,
                    updateMessage: nil,
                    appStoreURL: "https://apps.apple.com/app/id1234567890"
                )
            },
            installedVersion: "1.0.0",
            userDefaults: userDefaults,
            checkInterval: 0
        )

        let prompt = await service.checkForSoftUpdate(force: true)
        XCTAssertNil(prompt)
    }

    func testDismissedVersionIsNotPromptedAgainUntilForced() async {
        let service = AppUpdateService(
            fetchConfig: { Self.sampleConfig },
            installedVersion: "1.0.0",
            userDefaults: userDefaults,
            checkInterval: 0
        )

        let firstPrompt = await service.checkForSoftUpdate(force: false)
        XCTAssertNotNil(firstPrompt)

        service.markSoftUpdateDismissed(for: "1.0.1")
        let secondPrompt = await service.checkForSoftUpdate(force: false)
        XCTAssertNil(secondPrompt)

        let forcedPrompt = await service.checkForSoftUpdate(force: true)
        XCTAssertNotNil(forcedPrompt)
    }

    private static var sampleConfig: AppUpdateConfig {
        AppUpdateConfig(
            latestVersion: "1.0.1",
            minimumRequiredVersion: "1.0.0",
            updateMessage: "New fixes are available.",
            appStoreURL: "https://apps.apple.com/app/id1234567890"
        )
    }
}
