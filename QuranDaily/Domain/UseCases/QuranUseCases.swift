//
//  QuranUseCases.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

struct FetchQuranUseCase: Sendable {
    private let quranRepository: QuranRepositoryProtocol

    init(quranRepository: QuranRepositoryProtocol) {
        self.quranRepository = quranRepository
    }

    func executeSurahs() async throws -> [Surah] {
        try await quranRepository.fetchSurahs()
    }

    func executeAyahs(forSurah surahNumber: Int) async throws -> [Ayah] {
        try await quranRepository.fetchAyahs(forSurah: surahNumber)
    }

    func executeAyah(surahNumber: Int, ayahInSurah: Int) async throws -> Ayah? {
        try await quranRepository.fetchAyah(surahNumber: surahNumber, ayahInSurah: ayahInSurah)
    }

    func executeJuzList() async throws -> [Juz] {
        try await quranRepository.fetchJuzList()
    }

    func isDownloaded() async -> Bool {
        await quranRepository.isQuranDownloaded()
    }
}

struct DownloadQuranUseCase: Sendable {
    private let apiClient: APIClientProtocol
    private let quranRepository: QuranRepositoryProtocol

    init(
        apiClient: APIClientProtocol,
        quranRepository: QuranRepositoryProtocol
    ) {
        self.apiClient = apiClient
        self.quranRepository = quranRepository
    }

    func execute(
        progressHandler: @Sendable (DownloadProgress) -> Void
    ) async throws {
        if await quranRepository.isQuranDownloaded() {
            progressHandler(.completed)
            return
        }

        progressHandler(.downloading(message: "Fetching Arabic Quran...", fraction: 0.1))
        let arabic = try await apiClient.fetchArabicQuran()

        progressHandler(.downloading(message: "Fetching Urdu translation...", fraction: 0.4))
        let urdu = try await apiClient.fetchUrduTranslation()

        progressHandler(.downloading(message: "Fetching metadata...", fraction: 0.7))
        let meta = try await apiClient.fetchMeta()

        let merged = mergeQuranData(arabic: arabic, urdu: urdu, meta: meta)

        progressHandler(.downloading(message: "Saving locally...", fraction: 0.9))
        try await quranRepository.saveQuranData(
            surahs: merged.surahs,
            ayahsBySurah: merged.ayahsBySurah,
            juzs: merged.juzs
        )

        progressHandler(.completed)
    }

    private func mergeQuranData(
        arabic: QuranEditionResponse,
        urdu: QuranEditionResponse,
        meta: MetaResponse
    ) -> StoredQuranBundle {
        let urduAyahsBySurah = Dictionary(
            uniqueKeysWithValues: urdu.data.surahs.map { surah in
                (surah.number, Dictionary(uniqueKeysWithValues: surah.ayahs.map { ($0.numberInSurah, $0.text) }))
            }
        )

        var ayahsBySurah: [Int: [Ayah]] = [:]
        var surahs: [Surah] = []

        for apiSurah in arabic.data.surahs {
            let metaSurah = meta.data.surahs.references.first { $0.number == apiSurah.number }
            let surah = Surah(
                number: apiSurah.number,
                name: apiSurah.name,
                englishName: apiSurah.englishName,
                englishNameTranslation: apiSurah.englishNameTranslation,
                revelationType: apiSurah.revelationType,
                numberOfAyahs: metaSurah?.numberOfAyahs ?? apiSurah.ayahs.count
            )
            surahs.append(surah)

            let urduMap = urduAyahsBySurah[apiSurah.number] ?? [:]
            let ayahs = apiSurah.ayahs.map { apiAyah in
                Ayah(
                    number: apiAyah.number,
                    numberInSurah: apiAyah.numberInSurah,
                    surahNumber: apiSurah.number,
                    arabicText: apiAyah.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    urduText: urduMap[apiAyah.numberInSurah] ?? "",
                    juz: apiAyah.juz,
                    page: apiAyah.page
                )
            }
            ayahsBySurah[apiSurah.number] = ayahs
        }

        let juzs = meta.data.juzs.references.enumerated().map { index, reference in
            Juz(number: index + 1, startSurah: reference.surah, startAyah: reference.ayah)
        }

        return StoredQuranBundle(
            surahs: surahs.sorted { $0.number < $1.number },
            ayahsBySurah: ayahsBySurah,
            juzs: juzs
        )
    }
}

struct SearchQuranUseCase: Sendable {
    private let quranRepository: QuranRepositoryProtocol

    init(quranRepository: QuranRepositoryProtocol) {
        self.quranRepository = quranRepository
    }

    func execute(query: String, mode: SearchMode = .surah) async throws -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        switch mode {
        case .surah:
            return try await searchSurahs(query: trimmed)
        case .ayah:
            return try await searchAyahReference(query: trimmed)
        case .text:
            return try await searchText(query: trimmed)
        }
    }

    private func searchSurahs(query: String) async throws -> [SearchResult] {
        let surahs = try await quranRepository.fetchSurahs()
        var results: [SearchResult] = []

        if let surahNumber = Int(query),
           let surah = surahs.first(where: { $0.number == surahNumber }) {
            results.append(
                SearchResult(
                    id: "surah-number-\(surah.number)",
                    surahNumber: surah.number,
                    ayahNumber: 1,
                    surahName: surah.englishName,
                    arabicText: surah.name,
                    urduText: surah.englishNameTranslation,
                    matchType: .surahNumber
                )
            )
        }

        if let juzNumber = Int(query), (1...30).contains(juzNumber) {
            let juzs = try await quranRepository.fetchJuzList()
            if let juz = juzs.first(where: { $0.number == juzNumber }) {
                let surah = surahs.first { $0.number == juz.startSurah }
                results.append(
                    SearchResult(
                        id: "juz-\(juz.number)",
                        surahNumber: juz.startSurah,
                        ayahNumber: juz.startAyah,
                        surahName: surah?.englishName ?? "Surah \(juz.startSurah)",
                        arabicText: "Juz \(juz.number)",
                        urduText: "Starts at \(juz.startSurah):\(juz.startAyah)",
                        matchType: .juz
                    )
                )
            }
        }

        let normalizedQuery = query.lowercased()
        for surah in surahs {
            let matchesName =
                surah.englishName.lowercased().contains(normalizedQuery) ||
                surah.englishNameTranslation.lowercased().contains(normalizedQuery) ||
                surah.name.contains(query)

            if matchesName {
                results.append(
                    SearchResult(
                        id: "surah-name-\(surah.number)",
                        surahNumber: surah.number,
                        ayahNumber: 1,
                        surahName: surah.englishName,
                        arabicText: surah.name,
                        urduText: surah.englishNameTranslation,
                        matchType: .surahName
                    )
                )
            }
        }

        return deduplicated(results)
    }

    private func searchAyahReference(query: String) async throws -> [SearchResult] {
        let surahs = try await quranRepository.fetchSurahs()
        guard let reference = AyahReferenceParser.parse(query, surahs: surahs) else { return [] }

        let ayah: Ayah?
        switch reference {
        case .surahAyah(let surahNumber, let ayahNumber):
            ayah = try await quranRepository.fetchAyah(surahNumber: surahNumber, ayahInSurah: ayahNumber)
        case .absoluteNumber(let number):
            ayah = try await quranRepository.fetchAyah(byAbsoluteNumber: number)
        }

        guard let ayah else { return [] }

        let surah = surahs.first { $0.number == ayah.surahNumber }

        return [
            SearchResult(
                id: "ayah-ref-\(ayah.number)",
                surahNumber: ayah.surahNumber,
                ayahNumber: ayah.numberInSurah,
                surahName: surah?.englishName ?? "Surah \(ayah.surahNumber)",
                arabicText: ayah.arabicText,
                urduText: ayah.urduText,
                matchType: .ayahReference,
                absoluteAyahNumber: ayah.number
            )
        ]
    }

    private func searchText(query: String) async throws -> [SearchResult] {
        let surahs = try await quranRepository.fetchSurahs()
        let normalizedQuery = query.lowercased()
        var results: [SearchResult] = []

        for surah in surahs {
            let ayahs = try await quranRepository.fetchAyahs(forSurah: surah.number)
            for ayah in ayahs where matchesText(ayah, query: normalizedQuery) {
                results.append(
                    SearchResult(
                        id: "text-\(ayah.number)",
                        surahNumber: ayah.surahNumber,
                        ayahNumber: ayah.numberInSurah,
                        surahName: surah.englishName,
                        arabicText: ayah.arabicText,
                        urduText: ayah.urduText,
                        matchType: .text,
                        absoluteAyahNumber: ayah.number
                    )
                )
            }
        }

        return deduplicated(results)
    }

    private func matchesText(_ ayah: Ayah, query: String) -> Bool {
        ayah.arabicText.contains(query) ||
        ayah.urduText.lowercased().contains(query)
    }

    private func deduplicated(_ results: [SearchResult]) -> [SearchResult] {
        var seen = Set<String>()
        return results.filter { result in
            let key = "\(result.surahNumber)-\(result.ayahNumber)-\(result.matchType.rawValue)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }
}

struct StorageInfoUseCase: Sendable {
    private let storage: StorageServiceProtocol

    init(storage: StorageServiceProtocol) {
        self.storage = storage
    }

    func execute() async -> StorageInfo {
        let quranBytes = await storage.directorySize(at: StoragePaths.quranBundle)
        let audioBytes = await storage.directorySize(at: StoragePaths.audioDirectory)
        return StorageInfo(quranDataBytes: quranBytes, audioBytes: audioBytes)
    }
}

struct ClearCacheUseCase: Sendable {
    private let quranRepository: QuranRepositoryProtocol
    private let audioRepository: AudioRepositoryProtocol

    init(
        quranRepository: QuranRepositoryProtocol,
        audioRepository: AudioRepositoryProtocol
    ) {
        self.quranRepository = quranRepository
        self.audioRepository = audioRepository
    }

    func execute(clearQuran: Bool, clearAudio: Bool) async throws {
        if clearQuran {
            try await quranRepository.clearQuranCache()
        }
        if clearAudio {
            try await audioRepository.clearAudioCache()
        }
    }
}
