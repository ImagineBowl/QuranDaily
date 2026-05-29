import XCTest
#if SWIFT_PACKAGE
@testable import QuranDailyCore
#else
@testable import QuranDaily
#endif

final class AyahReferenceParserTests: XCTestCase {
    private let yaseen = Surah(
        number: 36,
        name: "سُورَةُ يس",
        englishName: "Ya-Sin",
        englishNameTranslation: "Yaseen",
        revelationType: "Meccan",
        numberOfAyahs: 83
    )

    func testParsesSurahAyahWithColon() {
        let reference = AyahReferenceParser.parse("2:255")
        XCTAssertEqual(reference, .surahAyah(surah: 2, ayah: 255))
    }

    func testParsesSurahAyahWithDash() {
        let reference = AyahReferenceParser.parse("2-255")
        XCTAssertEqual(reference, .surahAyah(surah: 2, ayah: 255))
    }

    func testParsesAbsoluteAyahNumber() {
        let reference = AyahReferenceParser.parse("262")
        XCTAssertEqual(reference, .absoluteNumber(262))
    }

    func testParsesNamedSurahReference() {
        let reference = AyahReferenceParser.parse("Yaseen:35", surahs: [yaseen])
        XCTAssertEqual(reference, .surahAyah(surah: 36, ayah: 35))
    }

    func testParsesNamedSurahReferenceWithSpaces() {
        let reference = AyahReferenceParser.parse("Ya-Sin 35", surahs: [yaseen])
        XCTAssertEqual(reference, .surahAyah(surah: 36, ayah: 35))
    }

    func testParsesYasinSpelling() {
        let reference = AyahReferenceParser.parse("Yasin:35", surahs: [yaseen])
        XCTAssertEqual(reference, .surahAyah(surah: 36, ayah: 35))
    }

    func testRejectsInvalidReference() {
        XCTAssertNil(AyahReferenceParser.parse("abc"))
        XCTAssertNil(AyahReferenceParser.parse("999:999"))
        XCTAssertNil(AyahReferenceParser.parse("Yaseen:35", surahs: []))
    }
}
