//
//  AudioRepository.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

final class AudioRepository: AudioRepositoryProtocol, @unchecked Sendable {
    private let storage: StorageServiceProtocol
    private let downloadService: DownloadServiceProtocol
    private let apiClient: APIClientProtocol
    private let quranRepository: QuranRepositoryProtocol

    init(
        storage: StorageServiceProtocol,
        downloadService: DownloadServiceProtocol,
        apiClient: APIClientProtocol,
        quranRepository: QuranRepositoryProtocol
    ) {
        self.storage = storage
        self.downloadService = downloadService
        self.apiClient = apiClient
        self.quranRepository = quranRepository
    }

    func isSurahDownloaded(_ surahNumber: Int) async -> Bool {
        let url = await localFileURL(for: surahNumber)
        return FileManager.default.fileExists(atPath: url.path)
    }

    func localAudioURL(forSurah surahNumber: Int) async -> URL? {
        let url = await localFileURL(for: surahNumber)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    func streamingAudioURL(forSurah surahNumber: Int) -> URL {
        apiClient.surahAudioURL(for: surahNumber)
    }

    func ayahStreamingURL(surahNumber: Int, ayahInSurah: Int) async throws -> URL {
        guard let ayah = try await quranRepository.fetchAyah(surahNumber: surahNumber, ayahInSurah: ayahInSurah) else {
            throw QuranError.ayahNotFound
        }
        return apiClient.ayahAudioURL(forAbsoluteNumber: ayah.number)
    }

    func playbackURL(forSurah surahNumber: Int) async -> URL {
        if let local = await localAudioURL(forSurah: surahNumber) {
            return local
        }
        return streamingAudioURL(forSurah: surahNumber)
    }

    func downloadSurahAudio(_ surahNumber: Int) async throws -> URL {
        let destination = await localFileURL(for: surahNumber)
        if FileManager.default.fileExists(atPath: destination.path) {
            return destination
        }

        try await storage.ensureDirectory(StoragePaths.audioDirectory)
        let remoteURL = apiClient.surahAudioURL(for: surahNumber)

        do {
            try await downloadService.download(from: remoteURL, to: destination)
            return destination
        } catch {
            throw QuranError.downloadFailed(error.localizedDescription)
        }
    }

    func downloadedSurahNumbers() async -> [Int] {
        let directory = await storage.documentsURL(for: StoragePaths.audioDirectory)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return files
            .compactMap { url -> Int? in
                let name = url.deletingPathExtension().lastPathComponent
                return Int(name)
            }
            .sorted()
    }

    func clearAudioCache() async throws {
        let directory = await storage.documentsURL(for: StoragePaths.audioDirectory)
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
    }

    private func localFileURL(for surahNumber: Int) async -> URL {
        let directory = await storage.documentsURL(for: StoragePaths.audioDirectory)
        return directory.appendingPathComponent(String(format: "%03d.mp3", surahNumber))
    }
}
