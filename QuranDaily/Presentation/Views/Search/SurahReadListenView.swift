import SwiftUI

struct SurahReadListenDestination: Hashable {
    let surahNumber: Int
    let ayahNumber: Int
    let autoPlay: Bool
}

struct SurahReadListenView: View {
    let destination: SurahReadListenDestination
    let container: AppContainer
    var audioViewModel: SearchAudioViewModel

    @State private var detailViewModel: SurahDetailViewModel?
    @State private var errorMessage: String?
    @State private var showAudioSheet = false
    @State private var showSurahPicker = false

    var body: some View {
        surahContent
            .background(AppTheme.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AudioMiniPlayerBar(viewModel: audioViewModel) {
                    showAudioSheet = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PlaybackToolbarButton(viewModel: audioViewModel)
                }
            }
            .sheet(isPresented: $showAudioSheet) {
                AudioPlayerSheet(
                    viewModel: audioViewModel,
                    showSurahPicker: $showSurahPicker
                )
            }
            .sheet(isPresented: $showSurahPicker) {
                SurahAudioPickerView(surahs: audioViewModel.surahs) { surah in
                    audioViewModel.selectedSurahNumber = surah.number
                    showSurahPicker = false
                }
            }
            .task {
                await loadSurahAndPlayIfNeeded()
            }
    }

    @ViewBuilder
    private var surahContent: some View {
        if let detailViewModel {
            SurahDetailView(
                viewModel: detailViewModel,
                highlightedAyahInSurah: playbackHighlightedAyah,
                onAyahTap: { ayahNumber in
                    Task {
                        await audioViewModel.playSurah(
                            destination.surahNumber,
                            fromAyah: ayahNumber
                        )
                    }
                }
            )
        } else if let errorMessage {
            ContentUnavailableView(
                "Unable to open",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )
        } else {
            ProgressView("Loading surah...")
        }
    }

    private func loadSurahAndPlayIfNeeded() async {
        guard detailViewModel == nil else { return }

        do {
            let surahs = try await container.fetchQuranUseCase.executeSurahs()
            guard let surah = surahs.first(where: { $0.number == destination.surahNumber }) else {
                errorMessage = "Surah not found."
                return
            }

            detailViewModel = SurahDetailViewModel(
                surah: surah,
                fetchQuranUseCase: container.fetchQuranUseCase,
                bookmarkRepository: container.bookmarkRepository,
                readingPositionRepository: container.readingPositionRepository,
                settingsRepository: container.settingsRepository,
                initialAyah: destination.ayahNumber
            )
            audioViewModel.selectedSurahNumber = destination.surahNumber

            if destination.autoPlay {
                let startAyah = destination.ayahNumber > 1 ? destination.ayahNumber : nil
                await audioViewModel.playSurah(
                    surah.number,
                    fromAyah: startAyah
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var playbackHighlightedAyah: Int? {
        guard audioViewModel.currentSurahNumber == destination.surahNumber else { return nil }
        return audioViewModel.currentAyahInSurah
    }
}

struct PlaybackToolbarButton: View {
    var viewModel: SearchAudioViewModel

    var body: some View {
        Button {
            Task { await viewModel.togglePlayback() }
        } label: {
            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.title2)
        }
        .accessibilityLabel(viewModel.isPlaying ? "Pause recitation" : "Play recitation")
        .disabled(viewModel.isLoadingAudio)
    }
}

struct AudioMiniPlayerBar: View {
    var viewModel: SearchAudioViewModel
    let onExpand: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.duration > 0 {
                SmoothPlaybackProgressView(
                    currentTime: viewModel.currentTime,
                    duration: viewModel.duration,
                    isPlaying: viewModel.isPlaying,
                    trackID: viewModel.playbackTrackID
                )
                .padding(.horizontal)
            }

            Divider()

            HStack(spacing: 20) {
                Button(action: onExpand) {
                    VStack(alignment: .leading, spacing: 2) {
                        if viewModel.isLoadingAudio {
                            Text("Loading audio...")
                                .font(AppTheme.bodyFont(size: 16))
                        } else {
                            Text("Surah \(viewModel.currentSurahNumber ?? viewModel.selectedSurahNumber)")
                                .font(AppTheme.titleFont(size: 16))
                            HStack(spacing: 6) {
                                Text(viewModel.currentSurahDisplayName)
                                Text("•")
                                Text(viewModel.playbackStatusLabel)
                            }
                            .font(AppTheme.bodyFont(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Button {
                    Task { await viewModel.playPrevious() }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoadingAudio)

                Button {
                    Task { await viewModel.togglePlayback() }
                } label: {
                    Group {
                        if viewModel.isLoadingAudio {
                            ProgressView()
                        } else {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                        }
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoadingAudio)

                Button {
                    Task { await viewModel.playNext() }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoadingAudio)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }
}
