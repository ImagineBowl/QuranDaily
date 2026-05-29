import SwiftUI

struct SearchAudioView: View {
    @Bindable var viewModel: SearchAudioViewModel
    let container: AppContainer

    @State private var navigationPath = NavigationPath()
    @State private var showAudioSheet = false
    @State private var showSurahPicker = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                Picker("Search filter", selection: $viewModel.searchMode) {
                    ForEach(SearchMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .onChange(of: viewModel.searchMode) { _, _ in
                    viewModel.scheduleSearch()
                }

                resultsSection
            }
                .navigationTitle("Search")
                .searchable(
                    text: $viewModel.query,
                    prompt: Text(viewModel.searchMode.searchPrompt)
                )
                .onChange(of: viewModel.query) { _, _ in
                    viewModel.scheduleSearch()
                }
                .onSubmit {
                    Task { await viewModel.search() }
                }
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
                        audioViewModel: viewModel
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

    @ViewBuilder
    private var resultsSection: some View {
        if viewModel.isSearching {
            ProgressView("Searching...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.searchErrorMessage {
            ContentUnavailableView(
                "Search failed",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView(
                "Search the Quran",
                systemImage: "text.magnifyingglass",
                description: Text(viewModel.searchMode.emptyDescription)
            )
        } else if !viewModel.hasResults {
            ContentUnavailableView(
                noResultsTitle,
                systemImage: "magnifyingglass",
                description: Text(noResultsDescription)
            )
        } else {
            List {
                if !viewModel.matchingSurahs.isEmpty {
                    Section {
                        ForEach(viewModel.matchingSurahs) { surah in
                            SurahSearchResultRow(surah: surah) {
                                openReadAndListen(
                                    surahNumber: surah.number,
                                    ayahNumber: 1
                                )
                            }
                        }
                    } header: {
                        Text("Surahs")
                    } footer: {
                        Text("Opens the surah text with recitation playing so you can read and listen together.")
                    }
                }

                if !viewModel.ayahReferenceResults.isEmpty {
                    Section {
                        ForEach(viewModel.ayahReferenceResults) { result in
                            AyahSearchResultRow(result: result) {
                                openReadAndListen(
                                    surahNumber: result.surahNumber,
                                    ayahNumber: result.ayahNumber
                                )
                            }
                        }
                    } header: {
                        Text("Ayah")
                    } footer: {
                        Text("Use a custom reference like Yaseen:35, or numeric forms like 36:35 and 262.")
                    }
                }

                if !viewModel.textSearchResults.isEmpty {
                    Section("Ayah Text Matches") {
                        ForEach(viewModel.textSearchResults) { result in
                            Button {
                                openReadAndListen(
                                    surahNumber: result.surahNumber,
                                    ayahNumber: result.ayahNumber
                                )
                            } label: {
                                SearchResultRowView(result: result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
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

    private var noResultsTitle: String {
        switch viewModel.searchMode {
        case .surah: "No surahs found"
        case .ayah: "Ayah not found"
        case .text: "No text matches"
        }
    }

    private var noResultsDescription: String {
        switch viewModel.searchMode {
        case .surah:
            "Try a different surah name or number."
        case .ayah:
            "Try Yaseen:35, 36:35, or a global ayah number like 262."
        case .text:
            "Try a different Arabic or Urdu phrase."
        }
    }
}

struct SurahSearchResultRow: View {
    let surah: Surah
    let onReadAndListen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SurahRowView(surah: surah)

            Button(action: onReadAndListen) {
                Label("Read & Listen", systemImage: "book.and.waveform.fill")
                    .font(AppTheme.bodyFont(size: 18))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(LargeButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

struct AyahSearchResultRow: View {
    let result: SearchResult
    let onReadAndListen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(result.displayReference)
                        .font(AppTheme.titleFont(size: 22))
                    Text(result.surahName)
                        .font(AppTheme.bodyFont(size: 18))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let absoluteAyahNumber = result.absoluteAyahNumber {
                        Text("#\(absoluteAyahNumber)")
                            .font(AppTheme.bodyFont(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(result.arabicText)
                    .font(AppTheme.arabicFont(size: 22))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if !result.urduText.isEmpty {
                    Text(result.urduText)
                        .font(AppTheme.bodyFont(size: 18))
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: onReadAndListen) {
                Label("Read & Listen", systemImage: "book.and.waveform.fill")
                    .font(AppTheme.bodyFont(size: 18))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(LargeButtonStyle())
        }
        .padding(.vertical, 4)
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
                Slider(
                    value: Binding(
                        get: { viewModel.currentTime / max(viewModel.duration, 1) },
                        set: { viewModel.seek(to: $0) }
                    )
                )
                .tint(AppTheme.accent)

                HStack {
                    Text(formatTime(viewModel.currentTime))
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

struct SearchResultRowView: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(result.surahName) \(result.surahNumber):\(result.ayahNumber)")
                    .font(AppTheme.titleFont(size: 20))
                Spacer()
                Image(systemName: "book.and.waveform.fill")
                    .foregroundStyle(AppTheme.accent)
            }

            Text(result.arabicText)
                .font(AppTheme.arabicFont(size: 20))
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if !result.urduText.isEmpty {
                Text(result.urduText)
                    .font(AppTheme.bodyFont(size: 18))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}
