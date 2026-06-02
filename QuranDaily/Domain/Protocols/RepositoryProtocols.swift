import Foundation

protocol QuranRepositoryProtocol: Sendable {
    func isQuranDownloaded() async -> Bool
    func fetchSurahs() async throws -> [Surah]
    func fetchAyahs(forSurah surahNumber: Int) async throws -> [Ayah]
    func fetchAyah(surahNumber: Int, ayahInSurah: Int) async throws -> Ayah?
    func fetchAyah(byAbsoluteNumber number: Int) async throws -> Ayah?
    func fetchJuzList() async throws -> [Juz]
    func saveQuranData(
        surahs: [Surah],
        ayahsBySurah: [Int: [Ayah]],
        juzs: [Juz]
    ) async throws
    func clearQuranCache() async throws
}

protocol AudioRepositoryProtocol: Sendable {
    func isSurahDownloaded(_ surahNumber: Int) async -> Bool
    func localAudioURL(forSurah surahNumber: Int) async -> URL?
    func streamingAudioURL(forSurah surahNumber: Int) -> URL
    func ayahStreamingURL(surahNumber: Int, ayahInSurah: Int) async throws -> URL
    func playbackURL(forSurah surahNumber: Int) async -> URL
    func downloadSurahAudio(_ surahNumber: Int) async throws -> URL
    func downloadedSurahNumbers() async -> [Int]
    func clearAudioCache() async throws
}

protocol StorageServiceProtocol: Sendable {
    func save<T: Encodable>(_ value: T, to filename: String) async throws
    func load<T: Decodable>(_ type: T.Type, from filename: String) async throws -> T?
    func fileExists(_ filename: String) async -> Bool
    func deleteFile(_ filename: String) async throws
    func directorySize(at relativePath: String) async -> Int64
    func ensureDirectory(_ relativePath: String) async throws
    func documentsURL(for relativePath: String) async -> URL
}

@MainActor
protocol AudioPlayerProtocol: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var currentSurahNumber: Int? { get }
    var currentAyahInSurah: Int? { get }

    func playFullSurah(_ surahNumber: Int, stopsAtSurahEnd: Bool) async throws
    func playSurah(
        _ surahNumber: Int,
        fromAyah ayahInSurah: Int,
        totalAyahs: Int,
        stopsAtSurahEnd: Bool
    ) async throws
    func pause()
    func resume()
    func seek(to time: TimeInterval)
    func stop()
    func playNext() async throws
    func playPrevious() async throws
}

protocol DownloadServiceProtocol: Sendable {
    func download(from url: URL, to destination: URL) async throws
}

protocol BookmarkRepositoryProtocol: Sendable {
    func fetchBookmarks() async throws -> [Bookmark]
    func addBookmark(_ bookmark: Bookmark) async throws
    func removeBookmark(id: UUID) async throws
    func isBookmarked(surahNumber: Int, ayahNumber: Int) async throws -> Bool
}

protocol ReadingPositionRepositoryProtocol: Sendable {
    func fetchPosition() async -> ReadingPosition
    func savePosition(_ position: ReadingPosition) async
}

protocol SettingsRepositoryProtocol: Sendable {
    func fetchSettings() async -> AppSettings
    func saveSettings(_ settings: AppSettings) async
}

protocol RecentListenRepositoryProtocol: Sendable {
    func fetchRecent() async -> [RecentListen]
    func record(surahNumber: Int, surahName: String, ayahNumber: Int) async -> [RecentListen]
}

protocol APIClientProtocol: Sendable {
    func fetchArabicQuran() async throws -> QuranEditionResponse
    func fetchUrduTranslation() async throws -> QuranEditionResponse
    func fetchMeta() async throws -> MetaResponse
    func surahAudioURL(for surahNumber: Int) -> URL
    func ayahAudioURL(forAbsoluteNumber number: Int) -> URL
}
