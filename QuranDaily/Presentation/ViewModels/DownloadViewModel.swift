//
//  DownloadViewModel.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation

@MainActor
@Observable
final class DownloadViewModel {
    private let downloadQuranUseCase: DownloadQuranUseCase
    private let fetchQuranUseCase: FetchQuranUseCase

    var progress: DownloadProgress = .idle
    var isDownloaded = false

    init(
        downloadQuranUseCase: DownloadQuranUseCase,
        fetchQuranUseCase: FetchQuranUseCase
    ) {
        self.downloadQuranUseCase = downloadQuranUseCase
        self.fetchQuranUseCase = fetchQuranUseCase
    }

    func checkDownloadStatus() async {
        isDownloaded = await fetchQuranUseCase.isDownloaded()
    }

    func startDownload() async {
        progress = .downloading(message: "Preparing download...", fraction: 0.05)

        do {
            try await downloadQuranUseCase.execute { [weak self] update in
                Task { @MainActor in
                    self?.progress = update
                    if case .completed = update {
                        self?.isDownloaded = true
                    }
                }
            }
        } catch {
            progress = .failed(message: error.localizedDescription)
        }
    }
}
