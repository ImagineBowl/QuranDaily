//
//  QuranArabicTextSanitizerTests.swift
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

final class QuranArabicTextSanitizerTests: XCTestCase {
    func testSanitizedForDisplayRemovesPrivateUseAreaGlyphs() {
        let raw = "الٓر\u200b\ue01e تِلۡكَ"
        let sanitized = QuranArabicTextSanitizer.sanitizedForDisplay(raw)

        XCTAssertFalse(sanitized.contains("\u{E01E}"))
        XCTAssertTrue(sanitized.contains("الٓر"))
        XCTAssertTrue(sanitized.contains("تِلۡكَ"))
    }

    func testSanitizedForDisplayRemovesVerseEndMarkerGlyph() {
        let raw = "الۡعٰلَمِيۡنَ\ue022\u200f"
        let sanitized = QuranArabicTextSanitizer.sanitizedForDisplay(raw)

        XCTAssertFalse(sanitized.contains("\u{E022}"))
        XCTAssertTrue(sanitized.hasSuffix("الۡعٰلَمِيۡنَ\u{200F}"))
    }

    func testSanitizedForDisplayRemovesEmojiCharacters() {
        let raw = "بِسْمِ ❤️ ٱللَّهِ"
        let sanitized = QuranArabicTextSanitizer.sanitizedForDisplay(raw)

        XCTAssertFalse(sanitized.contains("❤"))
        XCTAssertTrue(sanitized.contains("بِسْمِ"))
        XCTAssertTrue(sanitized.contains("ٱللَّهِ"))
    }

}
