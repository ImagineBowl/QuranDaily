import Foundation

final class RecentListenRepository: RecentListenRepositoryProtocol, @unchecked Sendable {
    private let storage: StorageServiceProtocol
    private let maxItems = 10

    init(storage: StorageServiceProtocol) {
        self.storage = storage
    }

    func fetchRecent() async -> [RecentListen] {
        let items: [RecentListen]? = try? await storage.load(
            [RecentListen].self,
            from: StoragePaths.recentListens
        )
        return (items ?? []).sorted { $0.listenedAt > $1.listenedAt }
    }

    func record(surahNumber: Int, surahName: String, ayahNumber: Int) async -> [RecentListen] {
        var items = await fetchRecent()
        items.removeAll { $0.surahNumber == surahNumber }
        items.insert(
            RecentListen(
                surahNumber: surahNumber,
                surahName: surahName,
                ayahNumber: ayahNumber
            ),
            at: 0
        )
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        try? await storage.save(items, to: StoragePaths.recentListens)
        return items
    }
}
