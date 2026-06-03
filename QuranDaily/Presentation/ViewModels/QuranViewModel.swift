import Foundation

@MainActor
@Observable
final class QuranViewModel {
    private let fetchQuranUseCase: FetchQuranUseCase
    private let readingPositionRepository: ReadingPositionRepositoryProtocol

    var surahs: [Surah] = []
    var juzs: [Juz] = []
    var readingPosition: ReadingPosition = .default
    var isLoading = false
    var errorMessage: String?

    init(
        fetchQuranUseCase: FetchQuranUseCase,
        readingPositionRepository: ReadingPositionRepositoryProtocol
    ) {
        self.fetchQuranUseCase = fetchQuranUseCase
        self.readingPositionRepository = readingPositionRepository
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            surahs = try await fetchQuranUseCase.executeSurahs()
            juzs = try await fetchQuranUseCase.executeJuzList()
            readingPosition = await readingPositionRepository.fetchPosition()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refreshReadingPosition() async {
        readingPosition = await readingPositionRepository.fetchPosition()
    }

    func updateReadingPosition(surahNumber: Int, ayahNumber: Int) async {
        let position = ReadingPosition(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            scrollAnchor: "ayah-\(ayahNumber)"
        )
        readingPosition = position
        await readingPositionRepository.savePosition(position)
    }
}
