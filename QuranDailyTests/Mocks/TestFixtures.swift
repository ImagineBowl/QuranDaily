//
//  TestFixtures.swift
//  QuranDailyTests
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation
import StoreKit
#if SWIFT_PACKAGE
@testable import QuranDailyCore
#else
@testable import QuranDaily
#endif

final class MockStorageService: StorageServiceProtocol, @unchecked Sendable {
    var files: [String: Data] = [:]
    var directories: Set<String> = []

    func save<T: Encodable>(_ value: T, to filename: String) async throws {
        let data = try JSONEncoder().encode(value)
        files[filename] = data
    }

    func load<T: Decodable>(_ type: T.Type, from filename: String) async throws -> T? {
        guard let data = files[filename] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }

    func fileExists(_ filename: String) async -> Bool {
        files[filename] != nil
    }

    func deleteFile(_ filename: String) async throws {
        files.removeValue(forKey: filename)
    }

    func directorySize(at relativePath: String) async -> Int64 {
        if let data = files[relativePath] {
            return Int64(data.count)
        }
        return files
            .filter { $0.key.hasPrefix(relativePath) }
            .reduce(0) { $0 + Int64($1.value.count) }
    }

    func ensureDirectory(_ relativePath: String) async throws {
        directories.insert(relativePath)
    }

    func documentsURL(for relativePath: String) async -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(relativePath)
    }
}

final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    var arabicResponse: QuranEditionResponse?
    var urduResponse: QuranEditionResponse?
    var metaResponse: MetaResponse?
    var shouldThrow = false

    func fetchArabicQuran() async throws -> QuranEditionResponse {
        if shouldThrow { throw QuranError.invalidResponse }
        guard let arabicResponse else { throw QuranError.invalidResponse }
        return arabicResponse
    }

    func fetchUrduTranslation() async throws -> QuranEditionResponse {
        if shouldThrow { throw QuranError.invalidResponse }
        guard let urduResponse else { throw QuranError.invalidResponse }
        return urduResponse
    }

    func fetchMeta() async throws -> MetaResponse {
        if shouldThrow { throw QuranError.invalidResponse }
        guard let metaResponse else { throw QuranError.invalidResponse }
        return metaResponse
    }

    func surahAudioURL(for surahNumber: Int) -> URL {
        URL(string: "https://example.com/audio/\(surahNumber).mp3")!
    }

    func ayahAudioURL(forAbsoluteNumber number: Int) -> URL {
        URL(string: "https://example.com/ayah/\(number).mp3")!
    }
}

final class MockDownloadService: DownloadServiceProtocol, @unchecked Sendable {
    var downloadedURLs: [URL] = []
    var shouldThrow = false

    func download(from url: URL, to destination: URL) async throws {
        if shouldThrow { throw QuranError.downloadFailed("Mock failure") }
        downloadedURLs.append(url)
        let data = Data("mock-audio".utf8)
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: destination)
    }
}

final class MockTipJarService: TipJarServiceProtocol, @unchecked Sendable {
    var products: [Product] = []
    var purchaseResult = true
    var shouldThrow = false

    func loadProducts() async throws -> [Product] {
        if shouldThrow { throw QuranError.invalidResponse }
        return products
    }

    func purchase(_ product: Product) async throws -> Bool {
        if shouldThrow { throw QuranError.invalidResponse }
        return purchaseResult
    }
}

enum TestFixtures {
    static let surah1 = Surah(
        number: 1,
        name: "سُورَةُ ٱلْفَاتِحَةِ",
        englishName: "Al-Faatiha",
        englishNameTranslation: "The Opening",
        revelationType: "Meccan",
        numberOfAyahs: 7
    )

    static let ayah1 = Ayah(
        number: 1,
        numberInSurah: 1,
        surahNumber: 1,
        arabicText: "بِسْمِ ٱللَّهِ",
        urduText: "شروع الله کا نام لے کر",
        juz: 1,
        page: 1
    )

    static let ayah2 = Ayah(
        number: 2,
        numberInSurah: 2,
        surahNumber: 1,
        arabicText: "ٱلْحَمْدُ لِلَّهِ",
        urduText: "سب تعریفیں",
        juz: 1,
        page: 1
    )

    static let juz1 = Juz(number: 1, startSurah: 1, startAyah: 1)

    static func makeBundle() -> StoredQuranBundle {
        StoredQuranBundle(
            surahs: [surah1],
            ayahsBySurah: [1: [ayah1, ayah2]],
            juzs: [juz1]
        )
    }

    static func makeArabicResponse() -> QuranEditionResponse {
        QuranEditionResponse(
            code: 200,
            status: "OK",
            data: QuranEditionData(
                surahs: [
                    APISurah(
                        number: 1,
                        name: surah1.name,
                        englishName: surah1.englishName,
                        englishNameTranslation: surah1.englishNameTranslation,
                        revelationType: surah1.revelationType,
                        ayahs: [
                            APIAyah(number: 1, text: ayah1.arabicText, numberInSurah: 1, juz: 1, page: 1),
                            APIAyah(number: 2, text: ayah2.arabicText, numberInSurah: 2, juz: 1, page: 1)
                        ]
                    )
                ]
            )
        )
    }

    static func makeUrduResponse() -> QuranEditionResponse {
        QuranEditionResponse(
            code: 200,
            status: "OK",
            data: QuranEditionData(
                surahs: [
                    APISurah(
                        number: 1,
                        name: surah1.name,
                        englishName: surah1.englishName,
                        englishNameTranslation: surah1.englishNameTranslation,
                        revelationType: surah1.revelationType,
                        ayahs: [
                            APIAyah(number: 1, text: ayah1.urduText, numberInSurah: 1, juz: 1, page: 1),
                            APIAyah(number: 2, text: ayah2.urduText, numberInSurah: 2, juz: 1, page: 1)
                        ]
                    )
                ]
            )
        )
    }

    static func makeMetaResponse() -> MetaResponse {
        MetaResponse(
            code: 200,
            status: "OK",
            data: MetaData(
                surahs: MetaSurahs(
                    references: [
                        MetaSurahReference(
                            number: 1,
                            name: surah1.name,
                            englishName: surah1.englishName,
                            englishNameTranslation: surah1.englishNameTranslation,
                            numberOfAyahs: 7,
                            revelationType: "Meccan"
                        )
                    ]
                ),
                juzs: MetaJuzs(references: [MetaJuzReference(surah: 1, ayah: 1)])
            )
        )
    }
}
