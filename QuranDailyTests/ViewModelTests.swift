//
//  ViewModelTests.swift
//  QuranDailyTests
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import XCTest
@testable import QuranDaily

@MainActor
final class DownloadViewModelTests: XCTestCase {
    func testCheckDownloadStatusReflectsRepositoryState() async throws {
        let storage = MockStorageService()
        let repository = QuranRepository(storage: storage)
        let useCase = DownloadQuranUseCase(
            apiClient: MockAPIClient(),
            quranRepository: repository
        )
        let fetchUseCase = FetchQuranUseCase(quranRepository: repository)
        let viewModel = DownloadViewModel(
            downloadQuranUseCase: useCase,
            fetchQuranUseCase: fetchUseCase
        )

        await viewModel.checkDownloadStatus()
        XCTAssertFalse(viewModel.isDownloaded)

        let bundle = TestFixtures.makeBundle()
        try await repository.saveQuranData(
            surahs: bundle.surahs,
            ayahsBySurah: bundle.ayahsBySurah,
            juzs: bundle.juzs
        )

        await viewModel.checkDownloadStatus()
        XCTAssertTrue(viewModel.isDownloaded)
    }
}

@MainActor
final class SearchAudioViewModelTests: XCTestCase {
    func testTogglePlaybackStartsSelectedSurahWhenIdle() async throws {
        let storage = MockStorageService()
        let downloadService = MockDownloadService()
        let apiClient = MockAPIClient()
        let quranRepository = QuranRepository(storage: storage)
        let audioRepository = AudioRepository(
            storage: storage,
            downloadService: downloadService,
            apiClient: apiClient,
            quranRepository: quranRepository
        )
        let audioPlayer = AudioPlayerService(audioRepository: audioRepository)
        let viewModel = SearchAudioViewModel(
            searchQuranUseCase: SearchQuranUseCase(
                quranRepository: QuranRepository(storage: storage)
            ),
            fetchQuranUseCase: FetchQuranUseCase(
                quranRepository: QuranRepository(storage: storage)
            ),
            audioRepository: audioRepository,
            audioPlayer: audioPlayer,
            recentListenRepository: RecentListenRepository(storage: storage)
        )

        viewModel.selectedSurahNumber = 1
        _ = try await audioRepository.downloadSurahAudio(1)
        await viewModel.load()

        await viewModel.togglePlayback()

        let downloaded = await audioRepository.isSurahDownloaded(1)
        XCTAssertTrue(downloaded)
        XCTAssertTrue(viewModel.canPlaySelectedSurah)
        XCTAssertNotEqual(
            viewModel.audioErrorMessage,
            QuranError.audioNotDownloaded.errorDescription
        )
        XCTAssertEqual(viewModel.selectedSurahNumber, 1)
    }

    func testPlayWithoutDownloadStreamsWithoutSaving() async throws {
        let storage = MockStorageService()
        let downloadService = MockDownloadService()
        let apiClient = MockAPIClient()
        let quranRepository = QuranRepository(storage: storage)
        let audioRepository = AudioRepository(
            storage: storage,
            downloadService: downloadService,
            apiClient: apiClient,
            quranRepository: quranRepository
        )
        let audioPlayer = AudioPlayerService(audioRepository: audioRepository)
        let viewModel = SearchAudioViewModel(
            searchQuranUseCase: SearchQuranUseCase(
                quranRepository: QuranRepository(storage: storage)
            ),
            fetchQuranUseCase: FetchQuranUseCase(
                quranRepository: QuranRepository(storage: storage)
            ),
            audioRepository: audioRepository,
            audioPlayer: audioPlayer,
            recentListenRepository: RecentListenRepository(storage: storage)
        )

        let playbackURL = await audioRepository.playbackURL(forSurah: 1)
        XCTAssertEqual(playbackURL, apiClient.surahAudioURL(for: 1))

        await viewModel.playSurah(1)

        let downloaded = await audioRepository.isSurahDownloaded(1)
        XCTAssertFalse(downloaded)
        XCTAssertTrue(downloadService.downloadedURLs.isEmpty)
        XCTAssertNotEqual(
            viewModel.audioErrorMessage,
            QuranError.audioNotDownloaded.errorDescription
        )
    }
}

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testUpdateFontSizePersistsSettings() async {
        let storage = MockStorageService()
        let settingsRepository = SettingsRepository(storage: storage)
        let viewModel = SettingsViewModel(
            settingsRepository: settingsRepository,
            storageInfoUseCase: StorageInfoUseCase(storage: storage),
            clearCacheUseCase: ClearCacheUseCase(
                quranRepository: QuranRepository(storage: storage),
                audioRepository: AudioRepository(
                    storage: storage,
                    downloadService: MockDownloadService(),
                    apiClient: MockAPIClient(),
                    quranRepository: QuranRepository(storage: storage)
                )
            ),
            tipJarService: MockTipJarService()
        )

        await viewModel.load()
        await viewModel.updateFontSize(28)

        let saved = await settingsRepository.fetchSettings()
        XCTAssertEqual(saved.fontSize, 28)
        XCTAssertEqual(viewModel.settings.fontSize, 28)
    }
}
