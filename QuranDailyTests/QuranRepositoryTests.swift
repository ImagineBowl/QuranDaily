//
//  QuranRepositoryTests.swift
//  QuranDailyTests
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import XCTest
#if SWIFT_PACKAGE
@testable import QuranDailyCore
#else
@testable import QuranDaily
#endif

final class QuranRepositoryTests: XCTestCase {
    private var storage: MockStorageService!
    private var repository: QuranRepository!

    override func setUp() async throws {
        storage = MockStorageService()
        repository = QuranRepository(storage: storage)
    }

    func testIsQuranDownloadedReturnsFalseWhenMissing() async {
        let downloaded = await repository.isQuranDownloaded()
        XCTAssertFalse(downloaded)
    }

    func testSaveAndFetchSurahs() async throws {
        let bundle = TestFixtures.makeBundle()
        try await repository.saveQuranData(
            surahs: bundle.surahs,
            ayahsBySurah: bundle.ayahsBySurah,
            juzs: bundle.juzs
        )

        let downloaded = await repository.isQuranDownloaded()
        XCTAssertTrue(downloaded)

        let surahs = try await repository.fetchSurahs()
        XCTAssertEqual(surahs.count, 1)
        XCTAssertEqual(surahs.first?.englishName, "Al-Faatiha")
    }

    func testFetchAyahsForSurah() async throws {
        let bundle = TestFixtures.makeBundle()
        try await repository.saveQuranData(
            surahs: bundle.surahs,
            ayahsBySurah: bundle.ayahsBySurah,
            juzs: bundle.juzs
        )

        let ayahs = try await repository.fetchAyahs(forSurah: 1)
        XCTAssertEqual(ayahs.count, 2)
        XCTAssertEqual(ayahs.first?.arabicText, TestFixtures.ayah1.arabicText)
    }

    func testFetchAyahsThrowsWhenSurahMissing() async throws {
        let bundle = TestFixtures.makeBundle()
        try await repository.saveQuranData(
            surahs: bundle.surahs,
            ayahsBySurah: bundle.ayahsBySurah,
            juzs: bundle.juzs
        )

        do {
            _ = try await repository.fetchAyahs(forSurah: 99)
            XCTFail("Expected surahNotFound error")
        } catch QuranError.surahNotFound(let number) {
            XCTAssertEqual(number, 99)
        }
    }

    func testClearQuranCache() async throws {
        let bundle = TestFixtures.makeBundle()
        try await repository.saveQuranData(
            surahs: bundle.surahs,
            ayahsBySurah: bundle.ayahsBySurah,
            juzs: bundle.juzs
        )

        try await repository.clearQuranCache()
        let downloaded = await repository.isQuranDownloaded()
        XCTAssertFalse(downloaded)
    }
}
