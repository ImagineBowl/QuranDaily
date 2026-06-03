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
                    tracksReadingPosition: false
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

            Text(surah.name)
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    surahSelectionCard
                    actionButtons
                    statusSection
                    playbackControls
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Audio Recitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var surahSelectionCard: some View {
        Button {
            showSurahPicker = true
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Surah \(viewModel.selectedSurahNumber)")
                        .font(AppTheme.titleFont(size: 24))
                    Text(viewModel.selectedSurahName)
                        .font(AppTheme.bodyFont(size: 18))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.isSelectedSurahDownloaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                        .font(.title2)
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        }
        .buttonStyle(.plain)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Text(viewModel.isSelectedSurahDownloaded
                 ? "Playing from downloaded audio."
                 : "Streaming online. Download to listen offline.")
                .font(AppTheme.bodyFont(size: 16))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.playSelectedSurah() }
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .buttonStyle(LargeButtonStyle())
                .disabled(viewModel.isLoadingAudio || viewModel.isDownloadingAudio)

                Button {
                    Task { await viewModel.downloadSelectedSurah() }
                } label: {
                    if viewModel.isDownloadingAudio {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTapSize)
                    } else {
                        Label(
                            viewModel.isSelectedSurahDownloaded ? "Downloaded" : "Download",
                            systemImage: viewModel.isSelectedSurahDownloaded ? "checkmark.circle.fill" : "arrow.down.circle"
                        )
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(viewModel.isSelectedSurahDownloaded || viewModel.isDownloadingAudio)
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if viewModel.isLoadingAudio {
            ProgressView("Loading audio...")
                .font(AppTheme.bodyFont(size: 18))
        }

        if let error = viewModel.audioErrorMessage {
            Text(error)
                .font(AppTheme.bodyFont(size: 18))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }

    private var playbackControls: some View {
        VStack(spacing: 12) {
            if viewModel.duration > 0 {
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
                .font(AppTheme.bodyFont(size: 16))
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.playPrevious() }
                } label: {
                    Image(systemName: "backward.fill")
                        .frame(width: AppTheme.minimumTapSize, height: AppTheme.minimumTapSize)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    Task { await viewModel.togglePlayback() }
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: AppTheme.minimumTapSize, height: AppTheme.minimumTapSize)
                }
                .buttonStyle(LargeButtonStyle())
                .disabled(viewModel.isLoadingAudio)

                Button {
                    Task { await viewModel.playNext() }
                } label: {
                    Image(systemName: "forward.fill")
                        .frame(width: AppTheme.minimumTapSize, height: AppTheme.minimumTapSize)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
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
