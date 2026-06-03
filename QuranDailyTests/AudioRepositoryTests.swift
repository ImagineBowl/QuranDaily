//
//  AudioRepositoryTests.swift
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

final class AudioRepositoryTests: XCTestCase {
    private var storage: MockStorageService!
    private var downloadService: MockDownloadService!
    private var apiClient: MockAPIClient!
    private var repository: AudioRepository!

    override func setUp() async throws {
        storage = MockStorageService()
        downloadService = MockDownloadService()
        apiClient = MockAPIClient()
        let quranRepository = QuranRepository(storage: storage)
        repository = AudioRepository(
            storage: storage,
            downloadService: downloadService,
            apiClient: apiClient,
            quranRepository: quranRepository
        )
    }

    func testDownloadSurahAudioStoresLocalFile() async throws {
        let url = try await repository.downloadSurahAudio(1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.lastPathComponent.contains("001.mp3"))

        let downloaded = await repository.isSurahDownloaded(1)
        XCTAssertTrue(downloaded)
    }

    func testDownloadSurahAudioUsesCacheWhenExists() async throws {
        _ = try await repository.downloadSurahAudio(1)
        downloadService.shouldThrow = true

        let url = try await repository.downloadSurahAudio(1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testPlaybackURLUsesLocalFileWhenDownloaded() async throws {
        let localURL = try await repository.downloadSurahAudio(1)
        let playbackURL = await repository.playbackURL(forSurah: 1)
        XCTAssertEqual(playbackURL, localURL)
    }

    func testPlaybackURLUsesStreamingWhenNotDownloaded() async throws {
        let playbackURL = await repository.playbackURL(forSurah: 36)
        XCTAssertEqual(playbackURL, apiClient.surahAudioURL(for: 36))
    }

    func testAyahStreamingURLUsesAbsoluteAyahNumber() async throws {
        let quranRepository = QuranRepository(storage: storage)
        try await quranRepository.saveQuranData(
            surahs: TestFixtures.makeBundle().surahs,
            ayahsBySurah: TestFixtures.makeBundle().ayahsBySurah,
            juzs: TestFixtures.makeBundle().juzs
        )

        let url = try await repository.ayahStreamingURL(surahNumber: 1, ayahInSurah: 2)
        XCTAssertEqual(url, apiClient.ayahAudioURL(forAbsoluteNumber: 2))
    }
}

final class BookmarkRepositoryTests: XCTestCase {
    private var storage: MockStorageService!
    private var repository: BookmarkRepository!

    override func setUp() async throws {
        storage = MockStorageService()
        repository = BookmarkRepository(storage: storage)
    }

    func testAddAndFetchBookmark() async throws {
        let bookmark = Bookmark(
            surahNumber: 1,
            ayahNumber: 1,
            surahName: "Al-Faatiha",
            arabicPreview: "بِسْمِ"
        )

        try await repository.addBookmark(bookmark)
        let bookmarks = try await repository.fetchBookmarks()

        XCTAssertEqual(bookmarks.count, 1)
        XCTAssertEqual(bookmarks.first?.surahNumber, 1)
    }

    func testIsBookmarked() async throws {
        let bookmark = Bookmark(
            surahNumber: 2,
            ayahNumber: 5,
            surahName: "Al-Baqara",
            arabicPreview: "preview"
        )
        try await repository.addBookmark(bookmark)

        let bookmarked = try await repository.isBookmarked(surahNumber: 2, ayahNumber: 5)
        XCTAssertTrue(bookmarked)
    }

    func testRemoveBookmark() async throws {
        let bookmark = Bookmark(
            surahNumber: 1,
            ayahNumber: 2,
            surahName: "Al-Faatiha",
            arabicPreview: "preview"
        )
        try await repository.addBookmark(bookmark)
        try await repository.removeBookmark(id: bookmark.id)

        let bookmarks = try await repository.fetchBookmarks()
        XCTAssertTrue(bookmarks.isEmpty)
    }
}

final class StorageServiceTests: XCTestCase {
    func testSaveLoadAndDeleteFile() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let storage = StorageService(rootDirectory: tempDirectory)

        try await storage.save(["hello": "world"], to: "test.json")
        let exists = await storage.fileExists("test.json")
        XCTAssertTrue(exists)

        let loaded: [String: String]? = try await storage.load([String: String].self, from: "test.json")
        XCTAssertEqual(loaded?["hello"], "world")

        try await storage.deleteFile("test.json")
        let existsAfterDelete = await storage.fileExists("test.json")
        XCTAssertFalse(existsAfterDelete)
    }
}
