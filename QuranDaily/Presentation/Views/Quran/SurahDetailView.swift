import SwiftUI

struct SurahDetailView: View {
    @Bindable var viewModel: SurahDetailViewModel
    var highlightedAyahInSurah: Int?
    var isAudioPlaying = false
    var onAyahTap: ((Int) -> Void)?
    var tracksReadingPosition = true
    @State private var visibleAyahs: Set<Int> = []
    @State private var didScrollToInitialAyah = false
    @State private var saveTask: Task<Void, Never>?

    private var topVisibleAyah: Int? {
        visibleAyahs.min()
    }

    private var showJumpToPlaying: Bool {
        guard isAudioPlaying, let target = highlightedAyahInSurah else { return false }
        return !visibleAyahs.contains(target)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading ayahs...")
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                            ForEach(viewModel.ayahs) { ayah in
                                AyahCardView(
                                    ayah: ayah,
                                    fontSize: viewModel.settings.fontSize,
                                    arabicFont: viewModel.settings.arabicFont,
                                    urduFont: viewModel.settings.urduFont,
                                    isBookmarked: viewModel.isBookmarked(ayah),
                                    isHighlighted: highlightedAyahInSurah == ayah.numberInSurah,
                                    onBookmark: {
                                        Task { await viewModel.toggleBookmark(for: ayah) }
                                    },
                                    onTap: onAyahTap.map { handler in
                                        { handler(ayah.numberInSurah) }
                                    }
                                )
                                .id("ayah-\(ayah.numberInSurah)")
                                .onAppear {
                                    visibleAyahs.insert(ayah.numberInSurah)
                                }
                                .onDisappear {
                                    visibleAyahs.remove(ayah.numberInSurah)
                                }
                            }
                        }
                        .padding()
                    }
                    .overlay(alignment: .bottom) {
                        jumpToPlayingButton(using: proxy)
                    }
                    .animation(.easeInOut(duration: 0.2), value: showJumpToPlaying)
                    .onChange(of: viewModel.ayahs.count) { _, count in
                        guard count > 0 else { return }
                        scrollToInitialAyah(using: proxy)
                    }
                    .onChange(of: highlightedAyahInSurah) { _, ayahNumber in
                        guard let ayahNumber else { return }
                        // Only auto-follow while the user is still viewing the playing
                        // ayah. Once they scroll away it stays put and the jump button
                        // appears, so we don't yank them back mid-read.
                        guard visibleAyahs.contains(ayahNumber) else { return }
                        scrollToAyah(ayahNumber, using: proxy, animated: true)
                    }
                    .onChange(of: topVisibleAyah) { _, _ in
                        scheduleReadingPositionSave()
                    }
                    .onDisappear {
                        saveTask?.cancel()
                        guard tracksReadingPosition, let ayah = topVisibleAyah else { return }
                        Task {
                            await viewModel.saveReadingPosition(ayahNumber: ayah)
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.surah.englishName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func jumpToPlayingButton(using proxy: ScrollViewProxy) -> some View {
        if showJumpToPlaying, let target = highlightedAyahInSurah {
            Button {
                scrollToAyah(target, using: proxy, animated: true)
            } label: {
                Label("Now Playing", systemImage: jumpIcon(for: target))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent, in: Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityLabel("Scroll to currently playing ayah")
        }
    }

    private func jumpIcon(for target: Int) -> String {
        if let top = topVisibleAyah, target < top {
            return "arrow.up"
        }
        return "arrow.down"
    }

    private func scheduleReadingPositionSave() {
        guard tracksReadingPosition, let ayah = topVisibleAyah else { return }
        saveTask?.cancel()
        saveTask = Task {
            // Debounce so rapid scrolling (and the initial programmatic scroll)
            // only persists the settled top-visible ayah.
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await viewModel.saveReadingPosition(ayahNumber: ayah)
        }
    }

    private func scrollToInitialAyah(using proxy: ScrollViewProxy) {
        guard !didScrollToInitialAyah, let anchor = viewModel.scrollAnchor else { return }
        didScrollToInitialAyah = true

        Task { @MainActor in
            // LazyVStack only builds visible rows first; retry until the target ayah exists.
            for _ in 0..<8 {
                proxy.scrollTo(anchor, anchor: .center)
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    private func scrollToAyah(_ ayahNumber: Int, using proxy: ScrollViewProxy, animated: Bool) {
        let anchor = "ayah-\(ayahNumber)"

        Task { @MainActor in
            for attempt in 0..<6 {
                if animated, attempt == 0 {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo(anchor, anchor: .center)
                    }
                } else {
                    proxy.scrollTo(anchor, anchor: .center)
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }
}

struct AyahCardView: View {
    let ayah: Ayah
    let fontSize: Double
    var arabicFont: ArabicFontChoice = .amiriQuran
    var urduFont: UrduFontChoice = .notoNastaliq
    let isBookmarked: Bool
    var isHighlighted = false
    let onBookmark: () -> Void
    var onTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(ayah.surahNumber):\(ayah.numberInSurah)")
                    .font(AppTheme.bodyFont(size: fontSize - 4))
                    .foregroundStyle(isHighlighted ? AppTheme.accent : .secondary)

                Spacer()

                Button(action: onBookmark) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 24))
                        .frame(width: AppTheme.minimumTapSize, height: AppTheme.minimumTapSize)
                }
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark ayah")
            }

            Text(ayah.arabicText)
                .font(AppTheme.arabicFont(size: fontSize + 4, choice: arabicFont))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(10)

            Text(ayah.urduText)
                .font(AppTheme.urduFont(size: fontSize, choice: urduFont))
                .foregroundStyle(.primary)
                .lineSpacing(8)
        }
        .padding()
        .background(isHighlighted ? AppTheme.accent.opacity(0.14) : AppTheme.secondaryBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(isHighlighted ? AppTheme.accent : Color.clear, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .animation(.easeInOut(duration: 0.25), value: isHighlighted)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .onTapGesture {
            onTap?()
        }
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
        .accessibilityHint(onTap != nil ? "Play recitation from this ayah" : "")
    }
}
