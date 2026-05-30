import SwiftUI

struct SurahListView: View {
    @Bindable var viewModel: QuranViewModel
    let container: AppContainer
    let appSettings: AppSettings

    @State private var showJuzPicker = false
    @State private var selectedJuz: Juz?

    var body: some View {
        NavigationStack {
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
                        if viewModel.readingPosition.surahNumber > 0 {
                            Section("Continue Reading") {
                                NavigationLink {
                                    destinationSurah(
                                        surahNumber: viewModel.readingPosition.surahNumber,
                                        ayahNumber: viewModel.readingPosition.ayahNumber
                                    )
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Resume")
                                            .font(AppTheme.titleFont(size: 22))
                                        Text("Surah \(viewModel.readingPosition.surahNumber), Ayah \(viewModel.readingPosition.ayahNumber)")
                                            .font(AppTheme.bodyFont(size: 18))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }

                        Section("All Surahs") {
                            ForEach(viewModel.surahs) { surah in
                                NavigationLink {
                                    destinationSurah(surahNumber: surah.number)
                                } label: {
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
                    selectedJuz = juz
                    showJuzPicker = false
                }
            }
            .navigationDestination(item: $selectedJuz) { juz in
                destinationSurah(surahNumber: juz.startSurah, ayahNumber: juz.startAyah)
            }
            .task {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private func destinationSurah(surahNumber: Int, ayahNumber: Int? = nil) -> some View {
        if let surah = viewModel.surahs.first(where: { $0.number == surahNumber }) {
            SurahDetailView(
                viewModel: SurahDetailViewModel(
                    surah: surah,
                    fetchQuranUseCase: container.fetchQuranUseCase,
                    bookmarkRepository: container.bookmarkRepository,
                    readingPositionRepository: container.readingPositionRepository,
                    settingsRepository: container.settingsRepository,
                    initialAyah: ayahNumber
                )
            )
        } else {
            Text("Surah not found")
        }
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
