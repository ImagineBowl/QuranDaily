import XCTest
#if SWIFT_PACKAGE
@testable import QuranDailyCore
#else
@testable import QuranDaily
#endif

final class ProgressBox: @unchecked Sendable {
    var value: DownloadProgress = .idle
    var values: [DownloadProgress] = []

    func append(_ progress: DownloadProgress) {
        values.append(progress)
    }
}

final class DownloadQuranUseCaseTests: XCTestCase {
    private var storage: MockStorageService!
    private var apiClient: MockAPIClient!
    private var repository: QuranRepository!
    private var useCase: DownloadQuranUseCase!

    override func setUp() async throws {
        storage = MockStorageService()
        apiClient = MockAPIClient()
        apiClient.arabicResponse = TestFixtures.makeArabicResponse()
        apiClient.urduResponse = TestFixtures.makeUrduResponse()
        apiClient.metaResponse = TestFixtures.makeMetaResponse()
        repository = QuranRepository(storage: storage)
        useCase = DownloadQuranUseCase(apiClient: apiClient, quranRepository: repository)
    }

    func testExecuteDownloadsAndStoresMergedQuran() async throws {
        let progressBox = ProgressBox()

        try await useCase.execute { progress in
            progressBox.value = progress
        }

        if case .completed = progressBox.value {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected completed progress")
        }

        let surahs = try await repository.fetchSurahs()
        XCTAssertEqual(surahs.count, 1)

        let ayahs = try await repository.fetchAyahs(forSurah: 1)
        XCTAssertEqual(ayahs.first?.urduText, TestFixtures.ayah1.urduText)
    }

    func testExecuteSkipsDownloadWhenAlreadyStored() async throws {
        let bundle = TestFixtures.makeBundle()
        try await repository.saveQuranData(
            surahs: bundle.surahs,
            ayahsBySurah: bundle.ayahsBySurah,
            juzs: bundle.juzs
        )

        let progressBox = ProgressBox()
        try await useCase.execute { progress in
            progressBox.append(progress)
        }

        XCTAssertEqual(progressBox.values.count, 1)
        if case .completed = progressBox.values.first {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected immediate completion")
        }
    }

    func testExecuteThrowsWhenAPIFails() async {
        apiClient.shouldThrow = true

        do {
            try await useCase.execute { _ in }
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? QuranError, .invalidResponse)
        }
    }
}
