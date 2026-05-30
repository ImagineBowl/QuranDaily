import SwiftUI

struct SurahDetailView: View {
    @Bindable var viewModel: SurahDetailViewModel
    var highlightedAyahInSurah: Int?
    var onAyahTap: ((Int) -> Void)?
    @State private var visibleAyah: Int = 1
    @State private var didScrollToInitialAyah = false

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
                                    visibleAyah = ayah.numberInSurah
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.ayahs.count) { _, count in
                        guard count > 0 else { return }
                        scrollToInitialAyah(using: proxy)
                    }
                    .onChange(of: highlightedAyahInSurah) { _, ayahNumber in
                        guard let ayahNumber else { return }
                        scrollToAyah(ayahNumber, using: proxy, animated: true)
                    }
                    .onDisappear {
                        Task {
                            await viewModel.saveReadingPosition(ayahNumber: visibleAyah)
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
