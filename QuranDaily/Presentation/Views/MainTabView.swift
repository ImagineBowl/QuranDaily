//
//  MainTabView.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import SwiftUI

struct MainTabView: View {
    let container: AppContainer

    @State private var quranViewModel: QuranViewModel
    @State private var searchViewModel: SearchAudioViewModel
    @State private var bookmarksViewModel: BookmarksViewModel
    @State private var settingsViewModel: SettingsViewModel
    @State private var appSettings: AppSettings = .default

    init(container: AppContainer) {
        self.container = container
        _quranViewModel = State(initialValue: QuranViewModel(
            fetchQuranUseCase: container.fetchQuranUseCase,
            readingPositionRepository: container.readingPositionRepository
        ))
        _searchViewModel = State(initialValue: SearchAudioViewModel(
            searchQuranUseCase: container.searchQuranUseCase,
            fetchQuranUseCase: container.fetchQuranUseCase,
            audioRepository: container.audioRepository,
            audioPlayer: container.audioPlayer,
            recentListenRepository: container.recentListenRepository
        ))
        _bookmarksViewModel = State(initialValue: BookmarksViewModel(
            bookmarkRepository: container.bookmarkRepository
        ))
        _settingsViewModel = State(initialValue: SettingsViewModel(
            settingsRepository: container.settingsRepository,
            storageInfoUseCase: container.storageInfoUseCase,
            clearCacheUseCase: container.clearCacheUseCase,
            tipJarService: container.tipJarService
        ))
    }

    var body: some View {
        TabView {
            SurahListView(
                viewModel: quranViewModel,
                container: container,
                appSettings: appSettings,
                audioViewModel: searchViewModel
            )
            .tabItem {
                Label("Read", systemImage: "book.fill")
            }

            SearchAudioView(
                viewModel: searchViewModel,
                container: container,
                appSettings: appSettings
            )
                .tabItem {
                    Label("Listen", systemImage: "headphones")
                }

            BookmarksView(
                viewModel: bookmarksViewModel,
                container: container,
                appSettings: appSettings,
                audioViewModel: searchViewModel
            )
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark.fill")
                }

            SettingsView(viewModel: settingsViewModel, appSettings: $appSettings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(appSettings.theme.colorScheme)
        .task {
            appSettings = await container.settingsRepository.fetchSettings()
        }
        .onChange(of: settingsViewModel.settings) { _, newValue in
            appSettings = newValue
        }
    }
}

struct RootView: View {
    let container: AppContainer

    @State private var downloadViewModel: DownloadViewModel
    @State private var isReady = false

    init(container: AppContainer) {
        self.container = container
        _downloadViewModel = State(initialValue: DownloadViewModel(
            downloadQuranUseCase: container.downloadQuranUseCase,
            fetchQuranUseCase: container.fetchQuranUseCase
        ))
    }

    var body: some View {
        Group {
            if isReady || downloadViewModel.isDownloaded {
                MainTabView(container: container)
            } else {
                DownloadView(viewModel: downloadViewModel)
            }
        }
        .task {
            await downloadViewModel.checkDownloadStatus()
            isReady = downloadViewModel.isDownloaded
        }
        .onChange(of: downloadViewModel.isDownloaded) { _, downloaded in
            isReady = downloaded
        }
    }
}
