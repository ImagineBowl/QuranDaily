import SwiftUI

struct SurahListView: View {
    @Bindable var viewModel: QuranViewModel
    let container: AppContainer
    let appSettings: AppSettings
    var audioViewModel: SearchAudioViewModel

    @State private var path = NavigationPath()
    @State private var showJuzPicker = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading Quran...")
                        .font(AppTheme.bodyFont(size: 20))
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Unable to load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    List {
                        if let resumeSurah {
                            Section {
                                Button {
                                    openReader(
                                        surahNumber: resumeSurah.number,
                                        ayahNumber: viewModel.readingPosition.ayahNumber
                                    )
                                } label: {
                                    ContinueReadingCard(
                                        surah: resumeSurah,
                                        ayahNumber: viewModel.readingPosition.ayahNumber
                                    )
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                            }
                        }

                        Section("All Surahs") {
                            ForEach(viewModel.surahs) { surah in
                                NavigationLink(value: SurahReadListenDestination(
                                    surahNumber: surah.number,
                                    ayahNumber: 1,
                                    autoPlay: false
                                )) {
                                    SurahRowView(
                                        surah: surah,
                                        arabicFont: appSettings.arabicFont
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("QuranDaily")
            .navigationDestination(for: SurahReadListenDestination.self) { destination in
                SurahReadListenView(
                    destination: destination,
                    container: container,
                    audioViewModel: audioViewModel
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Jump to Juz") {
                            showJuzPicker = true
                        }
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showJuzPicker) {
                JuzPickerView(juzs: viewModel.juzs, surahs: viewModel.surahs) { juz in
                    showJuzPicker = false
                    openReader(surahNumber: juz.startSurah, ayahNumber: juz.startAyah)
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private var resumeSurah: Surah? {
        guard viewModel.readingPosition.surahNumber > 0 else { return nil }
        return viewModel.surahs.first { $0.number == viewModel.readingPosition.surahNumber }
    }

    private func openReader(surahNumber: Int, ayahNumber: Int) {
        path.append(
            SurahReadListenDestination(
                surahNumber: surahNumber,
                ayahNumber: ayahNumber,
                autoPlay: false
            )
        )
    }
}

struct ContinueReadingCard: View {
    let surah: Surah
    let ayahNumber: Int

    private var progress: Double {
        guard surah.numberOfAyahs > 0 else { return 0 }
        return min(Double(ayahNumber) / Double(surah.numberOfAyahs), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Continue Reading", systemImage: "book.fill")
                    .font(AppTheme.bodyFont(size: 14))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text(surah.name)
                    .font(AppTheme.arabicFont(size: 18))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(surah.englishName)
                    .font(AppTheme.titleFont(size: 26))
                    .foregroundStyle(.white)
                Text("Ayah \(ayahNumber) of \(surah.numberOfAyahs)")
                    .font(AppTheme.bodyFont(size: 15))
                    .foregroundStyle(.white.opacity(0.9))
            }

            ProgressView(value: progress)
                .tint(.white)

            HStack {
                Spacer()
                Label("Resume", systemImage: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [AppTheme.accent, AppTheme.accent.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}

struct SurahRowView: View {
    let surah: Surah
    var arabicFont: ArabicFontChoice = .amiriQuran

    var body: some View {
        HStack(spacing: 16) {
            Text("\(surah.number)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(width: 44, height: 44)
                .background(AppTheme.accent.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(surah.englishName)
                    .font(AppTheme.titleFont(size: 22))
                Text("\(surah.englishNameTranslation) • \(surah.numberOfAyahs) ayahs")
                    .font(AppTheme.bodyFont(size: 16))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(surah.name)
                .font(AppTheme.arabicFont(size: 22, choice: arabicFont))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
    }
}

struct JuzPickerView: View {
    let juzs: [Juz]
    let surahs: [Surah]
    let onSelect: (Juz) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(juzs) { juz in
                Button {
                    onSelect(juz)
                    dismiss()
                } label: {
                    HStack {
                        Text(juz.displayName)
                            .font(AppTheme.titleFont(size: 22))
                        Spacer()
                        if let surah = surahs.first(where: { $0.number == juz.startSurah }) {
                            Text("\(surah.englishName) \(juz.startAyah)")
                                .font(AppTheme.bodyFont(size: 18))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(minHeight: AppTheme.minimumTapSize)
                }
            }
            .navigationTitle("Select Juz")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
