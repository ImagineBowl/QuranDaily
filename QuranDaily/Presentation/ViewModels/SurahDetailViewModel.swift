//
//  SurahDetailViewModel.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

@MainActor
@Observable
final class SurahDetailViewModel {
    private let fetchQuranUseCase: FetchQuranUseCase
    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let readingPositionRepository: ReadingPositionRepositoryProtocol
    private let settingsRepository: SettingsRepositoryProtocol

    let surah: Surah

    var ayahs: [Ayah] = []
    var bookmarks: Set<String> = []
    var settings: AppSettings = .default
    var isLoading = false
    var errorMessage: String?
    var scrollAnchor: String?

    init(
        surah: Surah,
        fetchQuranUseCase: FetchQuranUseCase,
        bookmarkRepository: BookmarkRepositoryProtocol,
        readingPositionRepository: ReadingPositionRepositoryProtocol,
        settingsRepository: SettingsRepositoryProtocol,
        initialAyah: Int? = nil
    ) {
        self.surah = surah
        self.fetchQuranUseCase = fetchQuranUseCase
        self.bookmarkRepository = bookmarkRepository
        self.readingPositionRepository = readingPositionRepository
        self.settingsRepository = settingsRepository

        if let initialAyah {
            scrollAnchor = "ayah-\(initialAyah)"
        }
    }

    func load() async {
        guard ayahs.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            ayahs = try await fetchQuranUseCase.executeAyahs(forSurah: surah.number)
            settings = await settingsRepository.fetchSettings()
            await refreshBookmarks()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleBookmark(for ayah: Ayah) async {
        let key = bookmarkKey(surahNumber: ayah.surahNumber, ayahNumber: ayah.numberInSurah)

        do {
            if bookmarks.contains(key) {
                let allBookmarks = try await bookmarkRepository.fetchBookmarks()
                if let existing = allBookmarks.first(where: {
                    $0.surahNumber == ayah.surahNumber && $0.ayahNumber == ayah.numberInSurah
                }) {
                    try await bookmarkRepository.removeBookmark(id: existing.id)
                }
            } else {
                let bookmark = Bookmark(
                    surahNumber: ayah.surahNumber,
                    ayahNumber: ayah.numberInSurah,
                    surahName: surah.englishName,
                    arabicPreview: String(ayah.arabicText(for: settings.quranScript).prefix(80))
                )
                try await bookmarkRepository.addBookmark(bookmark)
            }
            await refreshBookmarks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveReadingPosition(ayahNumber: Int) async {
        let position = ReadingPosition(
            surahNumber: surah.number,
            ayahNumber: ayahNumber,
            scrollAnchor: "ayah-\(ayahNumber)"
        )
        await readingPositionRepository.savePosition(position)
    }

    func isBookmarked(_ ayah: Ayah) -> Bool {
        bookmarks.contains(bookmarkKey(surahNumber: ayah.surahNumber, ayahNumber: ayah.numberInSurah))
    }

    private func refreshBookmarks() async {
        do {
            let all = try await bookmarkRepository.fetchBookmarks()
            bookmarks = Set(all.map { bookmarkKey(surahNumber: $0.surahNumber, ayahNumber: $0.ayahNumber) })
        } catch {
            bookmarks = []
        }
    }

    private func bookmarkKey(surahNumber: Int, ayahNumber: Int) -> String {
        "\(surahNumber)-\(ayahNumber)"
    }
}
