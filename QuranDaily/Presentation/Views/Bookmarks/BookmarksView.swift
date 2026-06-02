import SwiftUI

struct BookmarksView: View {
    @Bindable var viewModel: BookmarksViewModel
    let container: AppContainer
    let appSettings: AppSettings
    var audioViewModel: SearchAudioViewModel

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No bookmarks yet",
                        systemImage: "bookmark",
                        description: Text("Tap the bookmark icon on any ayah while reading to save it here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.bookmarks) { bookmark in
                            Button {
                                path.append(SurahReadListenDestination(
                                    surahNumber: bookmark.surahNumber,
                                    ayahNumber: bookmark.ayahNumber,
                                    autoPlay: false
                                ))
                            } label: {
                                BookmarkRowView(
                                    bookmark: bookmark,
                                    arabicFont: appSettings.arabicFont
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            Task { await viewModel.remove(at: offsets) }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Bookmarks")
            .navigationDestination(for: SurahReadListenDestination.self) { destination in
                SurahReadListenView(
                    destination: destination,
                    container: container,
                    audioViewModel: audioViewModel
                )
            }
            .toolbar {
                if !viewModel.bookmarks.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                }
            }
            .onAppear {
                Task { await viewModel.load() }
            }
        }
    }
}

struct BookmarkRowView: View {
    let bookmark: Bookmark
    var arabicFont: ArabicFontChoice = .amiriQuran

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bookmark.displayReference)
                    .font(AppTheme.titleFont(size: 18))
                Spacer()
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(AppTheme.accent)
            }

            if !bookmark.arabicPreview.isEmpty {
                Text(bookmark.arabicPreview)
                    .font(AppTheme.arabicFont(size: 20, choice: arabicFont))
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
