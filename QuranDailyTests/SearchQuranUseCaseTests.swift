//
//  SearchQuranUseCaseTests.swift
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

final class SearchQuranUseCaseTests: XCTestCase {
    private var storage: MockStorageService!
    private var repository: QuranRepository!
    private var useCase: SearchQuranUseCase!

    override func setUp() async throws {
        storage = MockStorageService()
        repository = QuranRepository(storage: storage)
        useCase = SearchQuranUseCase(quranRepository: repository)

        let bundle = TestFixtures.makeBundle()
        try await repository.saveQuranData(
            surahs: bundle.surahs,
            ayahsBySurah: bundle.ayahsBySurah,
            juzs: bundle.juzs
        )
    }

    func testSearchBySurahNumber() async throws {
        let results = try await useCase.execute(query: "1")
        XCTAssertTrue(results.contains { $0.matchType == .surahNumber })
    }

    func testSearchBySurahName() async throws {
        let results = try await useCase.execute(query: "faatiha")
        XCTAssertTrue(results.contains { $0.matchType == .surahName })
    }

    func testSearchByJuzNumber() async throws {
        let results = try await useCase.execute(query: "1")
        XCTAssertTrue(results.contains { $0.matchType == .juz })
    }

    func testSearchByPartialUrduText() async throws {
        let results = try await useCase.execute(query: "تعریف", mode: .text)
        XCTAssertTrue(results.contains { $0.matchType == .text })
    }

    func testSearchAyahBySurahReference() async throws {
        let results = try await useCase.execute(query: "1:1", mode: .ayah)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.matchType, .ayahReference)
        XCTAssertEqual(results.first?.surahNumber, 1)
        XCTAssertEqual(results.first?.ayahNumber, 1)
    }

    func testSearchAyahByAbsoluteNumber() async throws {
        let results = try await useCase.execute(query: "2", mode: .ayah)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.matchType, .ayahReference)
        XCTAssertEqual(results.first?.surahNumber, 1)
        XCTAssertEqual(results.first?.ayahNumber, 2)
        XCTAssertEqual(results.first?.absoluteAyahNumber, 2)
    }

    func testInvalidAyahReferenceReturnsEmpty() async throws {
        let results = try await useCase.execute(query: "999:999", mode: .ayah)
        XCTAssertTrue(results.isEmpty)
    }

    func testEmptyQueryReturnsNoResults() async throws {
        let results = try await useCase.execute(query: "   ")
        XCTAssertTrue(results.isEmpty)
    }
}
