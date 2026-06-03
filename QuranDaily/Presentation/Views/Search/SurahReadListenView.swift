//
//  SurahReadListenView.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

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
    var tracksReadingPosition = true
    /// When true, playback is attributed to the Listen tab's Recent section.
    var tracksRecentListens = false

    @State private var detailViewModel: SurahDetailViewModel?
    @State private var errorMessage: String?
    @State private var showAudioSheet = false
    @State private var showSurahPicker = false

    var body: some View {
        surahContent
            .background(AppTheme.background)
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if audioViewModel.showMiniPlayer {
                    AudioMiniPlayerBar(viewModel: audioViewModel) {
                        showAudioSheet = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PlaybackToolbarButton(viewModel: audioViewModel) {
                        await togglePlaybackForThisSurah()
                    }
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
                isAudioPlaying: audioViewModel.isPlaying,
                onAyahTap: { ayahNumber in
                    Task {
                        await audioViewModel.playSurah(
                            destination.surahNumber,
                            fromAyah: ayahNumber,
                            recordRecentListen: tracksRecentListens
                        )
                    }
                },
                tracksReadingPosition: tracksReadingPosition
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
                // Always start ayah-by-ayah (including ayah 1) so the recitation
                // tracks `currentAyahInSurah` and the matching ayah highlights.
                await audioViewModel.playSurah(
                    surah.number,
                    fromAyah: destination.ayahNumber,
                    recordRecentListen: tracksRecentListens
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func togglePlaybackForThisSurah() async {
        if audioViewModel.currentSurahNumber == destination.surahNumber {
            // Already this surah (playing or paused) — pause/resume in place.
            await audioViewModel.togglePlayback()
        } else {
            // Fresh start for this surah — begin at the ayah we opened to so the
            // resumed ayah highlights and audio plays from there.
            await audioViewModel.playSurah(
                destination.surahNumber,
                fromAyah: destination.ayahNumber,
                recordRecentListen: tracksRecentListens
            )
        }
    }

    private var playbackHighlightedAyah: Int? {
        guard audioViewModel.currentSurahNumber == destination.surahNumber else { return nil }
        return audioViewModel.currentAyahInSurah
    }
}

struct PlaybackToolbarButton: View {
    var viewModel: SearchAudioViewModel
    var onToggle: (() async -> Void)?

    var body: some View {
        Button {
            Task {
                if let onToggle {
                    await onToggle()
                } else {
                    await viewModel.togglePlayback()
                }
            }
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
                .padding(.top, 8)
                .contentShape(Rectangle())
                .onTapGesture(perform: onExpand)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Expand player")
            }

            Divider()

            HStack(spacing: 12) {
                miniPlayerLabels
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onExpand)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Expand player")
                    .accessibilityHint("Opens the full Now Playing screen")

                miniPlayerTransportControls
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    private var miniPlayerLabels: some View {
        VStack(alignment: .leading, spacing: 2) {
            if viewModel.isLoadingAudio {
                Text("Loading audio...")
                    .font(AppTheme.bodyFont(size: 16))
            } else {
                Text(viewModel.currentSurahDisplayName)
                    .font(AppTheme.titleFont(size: 16))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(viewModel.currentAyahDisplayLine)
                    .font(AppTheme.bodyFont(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var miniPlayerTransportControls: some View {
        HStack(spacing: 4) {
            Button {
                Task { await viewModel.playPrevious() }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingAudio)
            .accessibilityLabel("Previous ayah")

            Button {
                Task { await viewModel.togglePlayback() }
            } label: {
                Group {
                    if viewModel.isLoadingAudio {
                        ProgressView()
                            .tint(AppTheme.accent)
                    } else {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingAudio)
            .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")

            Button {
                Task { await viewModel.playNext() }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingAudio)
            .accessibilityLabel("Next ayah")
        }
    }
}
