//
//  SearchAudioView.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import SwiftUI

struct SearchAudioView: View {
    @Bindable var viewModel: SearchAudioViewModel
    let container: AppContainer
    let appSettings: AppSettings

    @State private var navigationPath = NavigationPath()
    @State private var showAudioSheet = false
    @State private var showSurahPicker = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.surahs.isEmpty {
                    ProgressView("Loading surahs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    AyahReferencePickerView(
                        surahs: viewModel.surahs,
                        appSettings: appSettings,
                        recentListens: viewModel.recentListens,
                        onReadAndListen: openReadAndListen
                    )
                }
            }
            .navigationTitle("Listen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAudioSheet = true
                    } label: {
                        Image(systemName: "headphones")
                    }
                    .accessibilityLabel("Open audio player")
                }
            }
            .navigationDestination(for: SurahReadListenDestination.self) { destination in
                SurahReadListenView(
                    destination: destination,
                    container: container,
                    audioViewModel: viewModel,
                    tracksReadingPosition: false,
                    tracksRecentListens: true
                )
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if navigationPath.isEmpty && viewModel.showMiniPlayer {
                    AudioMiniPlayerBar(viewModel: viewModel) {
                        showAudioSheet = true
                    }
                }
            }
            .sheet(isPresented: $showAudioSheet) {
                AudioPlayerSheet(
                    viewModel: viewModel,
                    showSurahPicker: $showSurahPicker
                )
            }
            .sheet(isPresented: $showSurahPicker) {
                SurahAudioPickerView(surahs: viewModel.surahs) { surah in
                    viewModel.selectedSurahNumber = surah.number
                    showSurahPicker = false
                    showAudioSheet = false
                    navigationPath.append(
                        SurahReadListenDestination(
                            surahNumber: surah.number,
                            ayahNumber: 1,
                            autoPlay: true
                        )
                    )
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private func openReadAndListen(surahNumber: Int, ayahNumber: Int) {
        navigationPath.append(
            SurahReadListenDestination(
                surahNumber: surahNumber,
                ayahNumber: ayahNumber,
                autoPlay: true
            )
        )
    }
}

struct AyahReferencePickerView: View {
    let surahs: [Surah]
    let appSettings: AppSettings
    let recentListens: [RecentListen]
    let onReadAndListen: (Int, Int) -> Void

    @State private var selectedSurahNumber = 1
    @State private var selectedAyahNumber = 1
    @State private var showSurahBrowser = false
    @State private var showAyahPicker = false

    private var selectedSurah: Surah? {
        surahs.first { $0.number == selectedSurahNumber }
    }

    var body: some View {
        Group {
            if surahs.isEmpty {
                ProgressView("Loading surahs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Form {
                    Section {
                        if let selectedSurah {
                            Button {
                                showSurahBrowser = true
                            } label: {
                                selectionRow(
                                    title: "Surah",
                                    value: "\(selectedSurah.number) · \(selectedSurah.englishName)"
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                showAyahPicker = true
                            } label: {
                                selectionRow(title: "Ayah", value: "\(selectedAyahNumber)")
                            }
                            .buttonStyle(.plain)

                            Button {
                                onReadAndListen(selectedSurahNumber, selectedAyahNumber)
                            } label: {
                                Label("Read & Listen", systemImage: "book.and.waveform.fill")
                                    .font(AppTheme.bodyFont(size: 18))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(LargeButtonStyle())
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 12, trailing: 16))
                        }
                    } footer: {
                        if let selectedSurah {
                            Text("\(selectedSurah.englishNameTranslation) · \(selectedSurah.numberOfAyahs) ayahs")
                        }
                    }

                    if !recentListens.isEmpty {
                        Section("Recent") {
                            ForEach(recentListens) { item in
                                Button {
                                    onReadAndListen(item.surahNumber, item.ayahNumber)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.surahName)
                                                .font(AppTheme.bodyFont(size: 17))
                                                .foregroundStyle(.primary)
                                            Text("Ayah \(item.ayahNumber)")
                                                .font(AppTheme.bodyFont(size: 13))
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showSurahBrowser) {
                    AyahSurahBrowserSheet(
                        surahs: surahs,
                        appSettings: appSettings,
                        selectedSurahNumber: $selectedSurahNumber,
                        onSelect: { _ in
                            showSurahBrowser = false
                        }
                    )
                }
                .sheet(isPresented: $showAyahPicker) {
                    if let selectedSurah {
                        AyahNumberPickerSheet(
                            numberOfAyahs: selectedSurah.numberOfAyahs,
                            selectedAyahNumber: $selectedAyahNumber
                        )
                    }
                }
            }
        }
        .onAppear {
            syncDefaultsIfNeeded()
        }
        .onChange(of: surahs) { _, _ in
            syncDefaultsIfNeeded()
        }
        .onChange(of: selectedSurahNumber) { _, _ in
            // Changing the surah should start the ayah selection over.
            selectedAyahNumber = 1
        }
    }

    private func selectionRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.bodyFont(size: 17))
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(AppTheme.bodyFont(size: 17))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private func clampAyah(for surahNumber: Int) {
        guard let surah = surahs.first(where: { $0.number == surahNumber }) else { return }
        selectedAyahNumber = min(max(selectedAyahNumber, 1), surah.numberOfAyahs)
    }

    private func syncDefaultsIfNeeded() {
        guard let first = surahs.first else { return }
        if !surahs.contains(where: { $0.number == selectedSurahNumber }) {
            selectedSurahNumber = first.number
        }
        clampAyah(for: selectedSurahNumber)
    }
}

struct AyahSurahBrowserSheet: View {
    let surahs: [Surah]
    let appSettings: AppSettings
    @Binding var selectedSurahNumber: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var surahFilter = ""

    private var filteredSurahs: [Surah] {
        let trimmed = surahFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return surahs }

        let normalized = trimmed.lowercased()
        return surahs.filter { surah in
            String(surah.number) == trimmed ||
            surah.englishName.lowercased().contains(normalized) ||
            surah.englishNameTranslation.lowercased().contains(normalized) ||
            surah.name.contains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredSurahs) { surah in
                Button {
                    selectedSurahNumber = surah.number
                    onSelect(surah.number)
                    dismiss()
                } label: {
                    SurahPickerSelectionRow(
                        surah: surah,
                        arabicFont: appSettings.arabicFont,
                        isSelected: surah.number == selectedSurahNumber
                    )
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Surah")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $surahFilter, prompt: "Filter surahs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct AyahNumberPickerSheet: View {
    let numberOfAyahs: Int
    @Binding var selectedAyahNumber: Int

    @Environment(\.dismiss) private var dismiss
    @State private var filter = ""

    private var filteredAyahs: [Int] {
        let trimmed = filter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Array(1...numberOfAyahs) }
        return (1...numberOfAyahs).filter { String($0).hasPrefix(trimmed) }
    }

    var body: some View {
        NavigationStack {
            List(filteredAyahs, id: \.self) { ayah in
                Button {
                    selectedAyahNumber = ayah
                    dismiss()
                } label: {
                    HStack {
                        Text("Ayah \(ayah)")
                            .font(AppTheme.bodyFont(size: 17))
                            .foregroundStyle(.primary)
                        Spacer()
                        if ayah == selectedAyahNumber {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Ayah")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $filter, prompt: "Find ayah number")
            .keyboardType(.numberPad)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct SurahPickerSelectionRow: View {
    let surah: Surah
    var arabicFont: ArabicFontChoice = .amiriQuran
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text("\(surah.number)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(width: 36, height: 36)
                .background(isSelected ? AppTheme.accent.opacity(0.2) : AppTheme.secondaryBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(surah.englishName)
                    .font(AppTheme.titleFont(size: 18))
                Text(surah.englishNameTranslation)
                    .font(AppTheme.bodyFont(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(surah.name.sanitizedForQuranDisplay)
                .font(AppTheme.arabicFont(size: 20, choice: arabicFont))
                .multilineTextAlignment(.trailing)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct AudioPlayerSheet: View {
    @Bindable var viewModel: SearchAudioViewModel
    @Binding var showSurahPicker: Bool

    @Environment(\.dismiss) private var dismiss

    private var displayedSurah: Surah? {
        let number = viewModel.currentSurahNumber ?? viewModel.selectedSurahNumber
        return viewModel.surahs.first { $0.number == number }
    }

    var body: some View {
        VStack(spacing: 0) {
            nowPlayingHeader

            Spacer(minLength: 12)

            artworkView
                .padding(.horizontal, 28)

            Spacer(minLength: 12)

            VStack(spacing: 24) {
                trackInfo
                scrubber
                transportControls
                secondaryControls
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient)
        .tint(AppTheme.accent)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [AppTheme.accent.opacity(0.28), AppTheme.background],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
    }

    private var nowPlayingHeader: some View {
        ZStack {
            Text("Now Playing")
                .font(.system(size: 13, weight: .semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: AppTheme.minimumTapSize, height: AppTheme.minimumTapSize)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close player")

                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private var artworkView: some View {
        Button {
            showSurahPicker = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppTheme.accent.opacity(0.35), radius: 24, y: 12)

                VStack(spacing: 18) {
                    Image(systemName: "book.and.waveform.fill")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(.white.opacity(0.85))

                    if let surah = displayedSurah {
                        Text(surah.name.sanitizedForQuranDisplay)
                            .font(AppTheme.arabicFont(size: 40))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 24)

                        Text(surah.englishName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    } else {
                        Text(viewModel.currentSurahDisplayName)
                            .font(AppTheme.titleFont(size: 28))
                            .foregroundStyle(.white)
                    }
                }
                .padding(28)

                VStack {
                    HStack {
                        Spacer()
                        Label("Change", systemImage: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.18), in: Capsule())
                    }
                    Spacer()
                }
                .padding(16)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 360)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change surah")
    }

    private var trackInfo: some View {
        VStack(spacing: 6) {
            Text(displayedSurah?.englishName ?? viewModel.currentSurahDisplayName)
                .font(AppTheme.titleFont(size: 26))
                .foregroundStyle(.primary)
                .lineLimit(1)

            if let surah = displayedSurah {
                Text(surah.englishNameTranslation)
                    .font(AppTheme.bodyFont(size: 16))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let ayahLine = currentAyahLine {
                Text(ayahLine)
                    .font(AppTheme.arabicFont(size: 22))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.top, 4)
            }

            Text(ayahPositionLabel)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.accent)
        }
        .frame(maxWidth: .infinity)
    }

    private var currentAyahLine: String? {
        if let preview = viewModel.currentAyahArabicPreview, !preview.isEmpty {
            return preview
        }
        return nil
    }

    private var ayahPositionLabel: String {
        if let ayah = viewModel.currentAyahInSurah, let surah = displayedSurah {
            return "Ayah \(ayah) of \(surah.numberOfAyahs)"
        }
        return viewModel.playbackStatusLabel
    }

    @ViewBuilder
    private var scrubber: some View {
        if viewModel.duration > 0 {
            VStack(spacing: 4) {
                SmoothPlaybackSlider(
                    currentTime: viewModel.currentTime,
                    duration: viewModel.duration,
                    isPlaying: viewModel.isPlaying,
                    trackID: viewModel.playbackTrackID,
                    onSeek: { viewModel.seek(to: $0) }
                )

                HStack {
                    PlaybackElapsedTimeLabel(
                        currentTime: viewModel.currentTime,
                        duration: viewModel.duration,
                        isPlaying: viewModel.isPlaying,
                        trackID: viewModel.playbackTrackID
                    )
                    Spacer()
                    Text(formatTime(viewModel.duration))
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            }
        } else {
            // Reserve space so controls don't jump once duration is known.
            Color.clear.frame(height: 44)
        }
    }

    private var transportControls: some View {
        HStack(spacing: 44) {
            Button {
                Task { await viewModel.playPrevious() }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: AppTheme.minimumTapSize, height: AppTheme.minimumTapSize)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingAudio)
            .accessibilityLabel("Previous ayah")

            Button {
                Task { await viewModel.togglePlayback() }
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 76, height: 76)
                        .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, y: 6)

                    if viewModel.isLoadingAudio {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingAudio)
            .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")

            Button {
                Task { await viewModel.playNext() }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: AppTheme.minimumTapSize, height: AppTheme.minimumTapSize)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingAudio)
            .accessibilityLabel("Next ayah")
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var secondaryControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isSelectedSurahDownloaded ? "arrow.down.circle.fill" : "dot.radiowaves.up.forward")
                    .foregroundStyle(viewModel.isSelectedSurahDownloaded ? AppTheme.accent : .secondary)

                Text(viewModel.isSelectedSurahDownloaded ? "Available offline" : "Streaming online")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    Task { await viewModel.downloadSelectedSurah() }
                } label: {
                    if viewModel.isDownloadingAudio {
                        ProgressView()
                    } else {
                        Label(
                            viewModel.isSelectedSurahDownloaded ? "Downloaded" : "Download",
                            systemImage: viewModel.isSelectedSurahDownloaded ? "checkmark.circle.fill" : "arrow.down.circle"
                        )
                        .font(.system(size: 14, weight: .semibold))
                    }
                }
                .tint(AppTheme.accent)
                .disabled(viewModel.isSelectedSurahDownloaded || viewModel.isDownloadingAudio)
                .accessibilityLabel(viewModel.isSelectedSurahDownloaded ? "Downloaded" : "Download for offline")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.secondaryBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))

            if let error = viewModel.audioErrorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SurahAudioPickerView: View {
    let surahs: [Surah]
    let onSelect: (Surah) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(surahs) { surah in
                Button {
                    onSelect(surah)
                    dismiss()
                } label: {
                    SurahRowView(surah: surah)
                }
            }
            .navigationTitle("Select Surah")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
