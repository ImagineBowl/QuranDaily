//
//  BookmarksViewModel.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

@MainActor
@Observable
final class BookmarksViewModel {
    private let bookmarkRepository: BookmarkRepositoryProtocol

    var bookmarks: [Bookmark] = []
    var isLoading = false

    init(bookmarkRepository: BookmarkRepositoryProtocol) {
        self.bookmarkRepository = bookmarkRepository
    }

    func load() async {
        isLoading = true
        bookmarks = (try? await bookmarkRepository.fetchBookmarks()) ?? []
        isLoading = false
    }

    func remove(at offsets: IndexSet) async {
        let removed = offsets.map { bookmarks[$0] }
        for index in offsets.sorted(by: >) {
            bookmarks.remove(at: index)
        }
        for bookmark in removed {
            try? await bookmarkRepository.removeBookmark(id: bookmark.id)
        }
    }
}
