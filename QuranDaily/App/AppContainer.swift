//
//  AppContainer.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let storageService: StorageServiceProtocol
    let apiClient: APIClientProtocol
    let downloadService: DownloadServiceProtocol
    let tipJarService: TipJarServiceProtocol

    let quranRepository: QuranRepositoryProtocol
    let audioRepository: AudioRepositoryProtocol
    let bookmarkRepository: BookmarkRepositoryProtocol
    let readingPositionRepository: ReadingPositionRepositoryProtocol
    let settingsRepository: SettingsRepositoryProtocol
    let recentListenRepository: RecentListenRepositoryProtocol

    let fetchQuranUseCase: FetchQuranUseCase
    let downloadQuranUseCase: DownloadQuranUseCase
    let searchQuranUseCase: SearchQuranUseCase
    let storageInfoUseCase: StorageInfoUseCase
    let clearCacheUseCase: ClearCacheUseCase

    let audioPlayer: AudioPlayerService

    init(
        storageService: StorageServiceProtocol? = nil,
        apiClient: APIClientProtocol? = nil,
        downloadService: DownloadServiceProtocol? = nil,
        tipJarService: TipJarServiceProtocol? = nil
    ) {
        let storage = storageService ?? StorageService()
        let api = apiClient ?? AlQuranAPIClient()
        let downloader = downloadService ?? DownloadService()

        self.storageService = storage
        self.apiClient = api
        self.downloadService = downloader
        self.tipJarService = tipJarService ?? TipJarService()

        let quranRepo = QuranRepository(storage: storage)
        let audioRepo = AudioRepository(
            storage: storage,
            downloadService: downloader,
            apiClient: api,
            quranRepository: quranRepo
        )

        self.quranRepository = quranRepo
        self.audioRepository = audioRepo
        self.bookmarkRepository = BookmarkRepository(storage: storage)
        self.readingPositionRepository = ReadingPositionRepository(storage: storage)
        self.settingsRepository = SettingsRepository(storage: storage)
        self.recentListenRepository = RecentListenRepository(storage: storage)

        self.fetchQuranUseCase = FetchQuranUseCase(quranRepository: quranRepo)
        self.downloadQuranUseCase = DownloadQuranUseCase(
            apiClient: api,
            quranRepository: quranRepo
        )
        self.searchQuranUseCase = SearchQuranUseCase(quranRepository: quranRepo)
        self.storageInfoUseCase = StorageInfoUseCase(storage: storage)
        self.clearCacheUseCase = ClearCacheUseCase(
            quranRepository: quranRepo,
            audioRepository: audioRepo
        )

        self.audioPlayer = AudioPlayerService(audioRepository: audioRepo)
    }
}
