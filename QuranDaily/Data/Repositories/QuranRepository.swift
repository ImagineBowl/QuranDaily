//
//  QuranRepository.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

final class QuranRepository: QuranRepositoryProtocol, @unchecked Sendable {
    private let storage: StorageServiceProtocol

    init(storage: StorageServiceProtocol) {
        self.storage = storage
    }

    func isQuranDownloaded() async -> Bool {
        guard await storage.fileExists(StoragePaths.quranBundle),
              let bundle = try? await loadBundle() else {
            return false
        }
        return bundle.hasIndopakText
    }

    func fetchSurahs() async throws -> [Surah] {
        let bundle = try await loadBundle()
        return bundle.surahs.sorted { $0.number < $1.number }
    }

    func fetchAyahs(forSurah surahNumber: Int) async throws -> [Ayah] {
        let bundle = try await loadBundle()
        guard let ayahs = bundle.ayahsBySurah[surahNumber] else {
            throw QuranError.surahNotFound(surahNumber)
        }
        return ayahs.sorted { $0.numberInSurah < $1.numberInSurah }
    }

    func fetchAyah(surahNumber: Int, ayahInSurah: Int) async throws -> Ayah? {
        let ayahs = try await fetchAyahs(forSurah: surahNumber)
        return ayahs.first { $0.numberInSurah == ayahInSurah }
    }

    func fetchAyah(byAbsoluteNumber number: Int) async throws -> Ayah? {
        let bundle = try await loadBundle()
        for ayahs in bundle.ayahsBySurah.values {
            if let ayah = ayahs.first(where: { $0.number == number }) {
                return ayah
            }
        }
        return nil
    }

    func fetchJuzList() async throws -> [Juz] {
        let bundle = try await loadBundle()
        return bundle.juzs.sorted { $0.number < $1.number }
    }

    func saveQuranData(
        surahs: [Surah],
        ayahsBySurah: [Int: [Ayah]],
        juzs: [Juz]
    ) async throws {
        let bundle = StoredQuranBundle(
            surahs: surahs,
            ayahsBySurah: ayahsBySurah,
            juzs: juzs
        )
        try await storage.save(bundle, to: StoragePaths.quranBundle)
    }

    func clearQuranCache() async throws {
        try await storage.deleteFile(StoragePaths.quranBundle)
    }

    private func loadBundle() async throws -> StoredQuranBundle {
        guard let bundle: StoredQuranBundle = try await storage.load(
            StoredQuranBundle.self,
            from: StoragePaths.quranBundle
        ) else {
            throw QuranError.notDownloaded
        }
        return bundle
    }
}
