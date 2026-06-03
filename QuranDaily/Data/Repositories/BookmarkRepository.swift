//
//  BookmarkRepository.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

final class BookmarkRepository: BookmarkRepositoryProtocol, @unchecked Sendable {
    private let storage: StorageServiceProtocol

    init(storage: StorageServiceProtocol) {
        self.storage = storage
    }

    func fetchBookmarks() async throws -> [Bookmark] {
        let bookmarks: [Bookmark]? = try await storage.load(
            [Bookmark].self,
            from: StoragePaths.bookmarks
        )
        return bookmarks?.sorted { $0.createdAt > $1.createdAt } ?? []
    }

    func addBookmark(_ bookmark: Bookmark) async throws {
        var bookmarks = try await fetchBookmarks()
        bookmarks.removeAll {
            $0.surahNumber == bookmark.surahNumber && $0.ayahNumber == bookmark.ayahNumber
        }
        bookmarks.insert(bookmark, at: 0)
        try await storage.save(bookmarks, to: StoragePaths.bookmarks)
    }

    func removeBookmark(id: UUID) async throws {
        var bookmarks = try await fetchBookmarks()
        bookmarks.removeAll { $0.id == id }
        try await storage.save(bookmarks, to: StoragePaths.bookmarks)
    }

    func isBookmarked(surahNumber: Int, ayahNumber: Int) async throws -> Bool {
        let bookmarks = try await fetchBookmarks()
        return bookmarks.contains {
            $0.surahNumber == surahNumber && $0.ayahNumber == ayahNumber
        }
    }
}

final class ReadingPositionRepository: ReadingPositionRepositoryProtocol, @unchecked Sendable {
    private let storage: StorageServiceProtocol

    init(storage: StorageServiceProtocol) {
        self.storage = storage
    }

    func fetchPosition() async -> ReadingPosition {
        let position: ReadingPosition? = try? await storage.load(
            ReadingPosition.self,
            from: StoragePaths.readingPosition
        )
        return position ?? .default
    }

    func savePosition(_ position: ReadingPosition) async {
        try? await storage.save(position, to: StoragePaths.readingPosition)
    }
}

final class SettingsRepository: SettingsRepositoryProtocol, @unchecked Sendable {
    private let storage: StorageServiceProtocol

    init(storage: StorageServiceProtocol) {
        self.storage = storage
    }

    func fetchSettings() async -> AppSettings {
        let settings: AppSettings? = try? await storage.load(
            AppSettings.self,
            from: StoragePaths.settings
        )
        return settings ?? .default
    }

    func saveSettings(_ settings: AppSettings) async {
        try? await storage.save(settings, to: StoragePaths.settings)
    }
}
