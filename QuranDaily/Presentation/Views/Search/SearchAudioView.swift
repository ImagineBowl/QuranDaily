import SwiftUI

struct SearchAudioView: View {
    @Bindable var viewModel: SearchAudioViewModel
    let container: AppContainer
    let appSettings: AppSettings

    @Environment(\.dismissSearch) private var dismissSearch
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
                .padding(.bottom, 6)
                .onChange(of: viewModel.searchMode) { _, newMode in
                    if newMode == .ayah {
                        viewModel.query = ""
                        viewModel.results = []
                        viewModel.searchErrorMessage = nil
                        viewModel.isSearching = false
                    } else {
                        viewModel.scheduleSearch()
                    }
                }

                resultsSection
            }
            .conditionalSearchable(
                isEnabled: viewModel.searchMode.usesTextSearchBar,
                text: $viewModel.query,
                prompt: viewModel.searchMode.searchPrompt
            )
            .onChange(of: viewModel.query) { _, _ in
                guard viewModel.searchMode.usesTextSearchBar else { return }
                viewModel.scheduleSearch()
            }
            .onSubmit {
                guard viewModel.searchMode.usesTextSearchBar else { return }
                Task { await viewModel.search() }
            }
                .navigationTitle("Search & Audio")
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
        if viewModel.searchMode == .ayah {
            AyahReferencePickerView(
                surahs: viewModel.surahs,
                appSettings: appSettings,
                onReadAndListen: openReadAndListen
            )
        } else if viewModel.isSearching {
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
                            SurahSearchResultRow(
                                surah: surah,
                                arabicFont: appSettings.arabicFont
                            ) {
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
                            AyahSearchResultRow(
                                result: result,
                                arabicFont: appSettings.arabicFont,
                                urduFont: appSettings.urduFont
                            ) {
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
                                SearchResultRowView(
                                    result: result,
                                    arabicFont: appSettings.arabicFont,
                                    urduFont: appSettings.urduFont
                                )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    private func openReadAndListen(surahNumber: Int, ayahNumber: Int) {
        dismissSearch()
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
            "Choose a different surah or ayah number."
        case .text:
            "Try a different Arabic or Urdu phrase."
        }
    }
}

private struct ConditionalSearchableModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var text: String
    let prompt: String

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $text, prompt: Text(prompt))
        } else {
            content
        }
    }
}

private extension View {
    func conditionalSearchable(isEnabled: Bool, text: Binding<String>, prompt: String) -> some View {
        modifier(ConditionalSearchableModifier(isEnabled: isEnabled, text: text, prompt: prompt))
    }
}

struct AyahReferencePickerView: View {
    let surahs: [Surah]
    let appSettings: AppSettings
    let onReadAndListen: (Int, Int) -> Void

    @State private var selectedSurahNumber = 1
    @State private var selectedAyahNumber = 1
    @State private var showSurahBrowser = false

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
                            Picker("Surah", selection: $selectedSurahNumber) {
                                ForEach(surahs) { surah in
                                    Text("\(surah.number) · \(surah.englishName)")
                                        .tag(surah.number)
                                }
                            }
                            .onChange(of: selectedSurahNumber) { _, newValue in
                                clampAyah(for: newValue)
                            }

                            Picker("Ayah", selection: $selectedAyahNumber) {
                                ForEach(1...selectedSurah.numberOfAyahs, id: \.self) { ayah in
                                    Text("\(ayah)").tag(ayah)
                                }
                            }
                        }
                    } footer: {
                        if let selectedSurah {
                            Text("\(selectedSurah.englishNameTranslation) · \(selectedSurah.numberOfAyahs) ayahs")
                        }
                    }

                    Section {
                        Button {
                            showSurahBrowser = true
                        } label: {
                            Label("Browse all surahs", systemImage: "list.bullet")
                                .font(AppTheme.bodyFont(size: 18))
                        }
                    }

                    Section {
                        Button {
                            onReadAndListen(selectedSurahNumber, selectedAyahNumber)
                        } label: {
                            Label("Read & Listen", systemImage: "book.and.waveform.fill")
                                .font(AppTheme.bodyFont(size: 18))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(LargeButtonStyle())
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
                .sheet(isPresented: $showSurahBrowser) {
                    AyahSurahBrowserSheet(
                        surahs: surahs,
                        appSettings: appSettings,
                        selectedSurahNumber: $selectedSurahNumber,
                        onSelect: { surahNumber in
                            clampAyah(for: surahNumber)
                            showSurahBrowser = false
                        }
                    )
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

struct SurahSearchResultRow: View {
    let surah: Surah
    var arabicFont: ArabicFontChoice = .amiriQuran
    let onReadAndListen: () -> Void

    var body: some View {
        Button(action: onReadAndListen) {
            VStack(alignment: .leading, spacing: 12) {
                SurahRowView(surah: surah, arabicFont: arabicFont)

                readAndListenLabel
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var readAndListenLabel: some View {
        Label("Read & Listen", systemImage: "book.and.waveform.fill")
            .font(AppTheme.bodyFont(size: 18))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(AppTheme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}

struct AyahSearchResultRow: View {
    let result: SearchResult
    var arabicFont: ArabicFontChoice = .amiriQuran
    var urduFont: UrduFontChoice = .notoNastaliq
    let onReadAndListen: () -> Void

    var body: some View {
        Button(action: onReadAndListen) {
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
                        .font(AppTheme.arabicFont(size: 22, choice: arabicFont))
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    if !result.urduText.isEmpty {
                        Text(result.urduText)
                            .font(AppTheme.urduFont(size: 18, choice: urduFont))
                            .foregroundStyle(.secondary)
                    }
                }

                Label("Read & Listen", systemImage: "book.and.waveform.fill")
                    .font(AppTheme.bodyFont(size: 18))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(AppTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

struct SearchResultRowView: View {
    let result: SearchResult
    var arabicFont: ArabicFontChoice = .amiriQuran
    var urduFont: UrduFontChoice = .notoNastaliq

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
                .font(AppTheme.arabicFont(size: 20, choice: arabicFont))
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if !result.urduText.isEmpty {
                Text(result.urduText)
                    .font(AppTheme.urduFont(size: 18, choice: urduFont))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}
