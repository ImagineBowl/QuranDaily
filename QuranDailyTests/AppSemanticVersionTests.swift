//
//  AppSemanticVersionTests.swift
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

final class AppSemanticVersionTests: XCTestCase {
    func testComparesSemanticVersions() {
        XCTAssertTrue(AppSemanticVersion("1.0.0") < AppSemanticVersion("1.0.1"))
        XCTAssertTrue(AppSemanticVersion("1.0") < AppSemanticVersion("1.1.0"))
        XCTAssertFalse(AppSemanticVersion("1.0.1") < AppSemanticVersion("1.0.0"))
        XCTAssertEqual(AppSemanticVersion("1.0.0"), AppSemanticVersion("1.0"))
    }
}
