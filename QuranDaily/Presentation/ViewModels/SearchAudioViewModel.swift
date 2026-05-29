import Foundation

@MainActor
@Observable
final class SearchAudioViewModel {
    private let searchQuranUseCase: SearchQuranUseCase
    private let fetchQuranUseCase: FetchQuranUseCase
    private let audioRepository: AudioRepositoryProtocol
    private let audioPlayer: AudioPlayerService

    var query = ""
    var searchMode: SearchMode = .surah
    var results: [SearchResult] = []
    var surahs: [Surah] = []
    var selectedSurahNumber = 1
    var downloadedSurahs: Set<Int> = []
    var isSearching = false
    var isDownloadingAudio = false
    var isLoadingAudio = false
    var searchErrorMessage: String?
    var audioErrorMessage: String?
    var currentSurahNumber: Int?
    var currentAyahInSurah: Int?
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0

    private var progressTimer: Timer?
    private var searchTask: Task<Void, Never>?

    init(
        searchQuranUseCase: SearchQuranUseCase,
        fetchQuranUseCase: FetchQuranUseCase,
        audioRepository: AudioRepositoryProtocol,
        audioPlayer: AudioPlayerService
    ) {
        self.searchQuranUseCase = searchQuranUseCase
        self.fetchQuranUseCase = fetchQuranUseCase
        self.audioRepository = audioRepository
        self.audioPlayer = audioPlayer
        audioPlayer.onPlaybackUpdate = { [weak self] in
            self?.syncPlaybackState()
        }
    }

    var selectedSurahName: String {
        surahs.first { $0.number == selectedSurahNumber }?.englishName ?? "Surah \(selectedSurahNumber)"
    }

    var isSelectedSurahDownloaded: Bool {
        downloadedSurahs.contains(selectedSurahNumber)
    }

    func isSurahDownloaded(_ surahNumber: Int) -> Bool {
        downloadedSurahs.contains(surahNumber)
    }

    var canPlaySelectedSurah: Bool {
        true
    }

    var isStreamingSelectedSurah: Bool {
        !isSelectedSurahDownloaded &&
        (isPlaying || isLoadingAudio || currentSurahNumber == selectedSurahNumber)
    }

    var playbackStatusLabel: String {
        if isSelectedSurahDownloaded, currentAyahInSurah == nil {
            "Downloaded"
        } else if isPlaying || isLoadingAudio {
            if let ayah = currentAyahInSurah {
                "Ayah \(ayah)"
            } else {
                "Streaming"
            }
        } else {
            "Stream online"
        }
    }

    var showMiniPlayer: Bool {
        currentSurahNumber != nil || isLoadingAudio
    }

    var currentSurahDisplayName: String {
        let number = currentSurahNumber ?? selectedSurahNumber
        return surahs.first { $0.number == number }?.englishName ?? "Surah \(number)"
    }

    var textSearchResults: [SearchResult] {
        results.filter { $0.matchType == .text }
    }

    var ayahReferenceResults: [SearchResult] {
        results.filter { $0.matchType == .ayahReference }
    }

    var matchingSurahs: [Surah] {
        guard searchMode == .surah else { return [] }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let normalized = trimmed.lowercased()
        return surahs.filter { surah in
            String(surah.number) == trimmed ||
            surah.englishName.lowercased().contains(normalized) ||
            surah.englishNameTranslation.lowercased().contains(normalized) ||
            surah.name.contains(trimmed)
        }
    }

    var hasResults: Bool {
        !matchingSurahs.isEmpty || !ayahReferenceResults.isEmpty || !textSearchResults.isEmpty
    }

    func load() async {
        do {
            surahs = try await fetchQuranUseCase.executeSurahs()
            if let first = surahs.first, selectedSurahNumber == 1 {
                selectedSurahNumber = first.number
            }
        } catch {
            audioErrorMessage = error.localizedDescription
        }

        let downloaded = await audioRepository.downloadedSurahNumbers()
        downloadedSurahs = Set(downloaded)
        syncPlaybackState()
    }

    func scheduleSearch() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            results = []
            searchErrorMessage = nil
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await search()
        }
    }

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            searchErrorMessage = nil
            isSearching = false
            return
        }

        isSearching = true
        searchErrorMessage = nil

        do {
            results = try await searchQuranUseCase.execute(query: trimmed, mode: searchMode)
        } catch {
            searchErrorMessage = error.localizedDescription
            results = []
        }

        isSearching = false
    }

    func downloadSelectedSurah(playAfterDownload: Bool = false) async {
        await downloadAudio(for: selectedSurahNumber, playAfterDownload: playAfterDownload)
    }

    func playSelectedSurah() async {
        selectedSurahNumber = min(max(selectedSurahNumber, 1), 114)
        await playSurah(selectedSurahNumber)
    }

    func downloadAudio(for surahNumber: Int, playAfterDownload: Bool = false) async {
        isDownloadingAudio = true
        audioErrorMessage = nil
        selectedSurahNumber = surahNumber

        do {
            _ = try await audioRepository.downloadSurahAudio(surahNumber)
            downloadedSurahs.insert(surahNumber)
        } catch {
            audioErrorMessage = error.localizedDescription
            isDownloadingAudio = false
            return
        }

        isDownloadingAudio = false

        if playAfterDownload {
            await playSurah(surahNumber)
        }
    }

    func playSurah(_ surahNumber: Int, fromAyah: Int? = nil) async {
        isLoadingAudio = true
        audioErrorMessage = nil
        selectedSurahNumber = surahNumber

        do {
            if let fromAyah {
                let totalAyahs = surahs.first { $0.number == surahNumber }?.numberOfAyahs ?? 286
                try await audioPlayer.playSurah(
                    surahNumber,
                    fromAyah: fromAyah,
                    totalAyahs: totalAyahs
                )
            } else {
                try await audioPlayer.playFullSurah(surahNumber)
            }
            startProgressTimer()
            syncPlaybackState()
        } catch {
            audioErrorMessage = error.localizedDescription
            syncPlaybackState()
        }

        isLoadingAudio = false
    }

    func togglePlayback() async {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else if audioPlayer.currentSurahNumber != nil {
            audioPlayer.resume()
        } else {
            await playSelectedSurah()
        }
        syncPlaybackState()
    }

    func seek(to progress: Double) {
        let time = progress * audioPlayer.duration
        audioPlayer.seek(to: time)
        syncPlaybackState()
    }

    func playNext() async {
        do {
            try await audioPlayer.playNext()
            syncPlaybackState()
        } catch {
            audioErrorMessage = error.localizedDescription
        }
    }

    func playPrevious() async {
        do {
            try await audioPlayer.playPrevious()
            syncPlaybackState()
        } catch {
            audioErrorMessage = error.localizedDescription
        }
    }

    func stopPlayback() {
        audioPlayer.stop()
        stopProgressTimer()
        syncPlaybackState()
    }

    private func syncPlaybackState() {
        currentSurahNumber = audioPlayer.currentSurahNumber
        currentAyahInSurah = audioPlayer.currentAyahInSurah
        isPlaying = audioPlayer.isPlaying
        currentTime = audioPlayer.currentTime
        duration = audioPlayer.duration

        if let currentSurahNumber {
            selectedSurahNumber = currentSurahNumber
        }
    }

    private func startProgressTimer() {
        stopProgressTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncPlaybackState()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        progressTimer = timer
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}
