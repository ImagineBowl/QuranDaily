import SwiftUI

struct DownloadView: View {
    @Bindable var viewModel: DownloadViewModel

    var body: some View {
        VStack(spacing: AppTheme.sectionSpacing) {
            Spacer()

            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.accent)

            Text("Welcome to QuranDaily")
                .font(AppTheme.titleFont(size: 28))
                .multilineTextAlignment(.center)

            Text("Download Quran data once to read offline with Arabic text and Urdu translation.")
                .font(AppTheme.bodyFont(size: 20))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            progressView

            Button("Download Quran Data") {
                Task { await viewModel.startDownload() }
            }
            .buttonStyle(LargeButtonStyle())
            .padding(.horizontal)
            .disabled(isDownloading)

            Spacer()
        }
        .padding()
        .task {
            await viewModel.checkDownloadStatus()
        }
    }

    @ViewBuilder
    private var progressView: some View {
        switch viewModel.progress {
        case .idle:
            EmptyView()
        case .downloading(let message, let fraction):
            VStack(spacing: 12) {
                ProgressView(value: fraction)
                    .tint(AppTheme.accent)
                Text(message)
                    .font(AppTheme.bodyFont(size: 18))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        case .completed:
            Label("Download complete", systemImage: "checkmark.circle.fill")
                .font(AppTheme.bodyFont(size: 20))
                .foregroundStyle(AppTheme.accent)
        case .failed(let message):
            Text(message)
                .font(AppTheme.bodyFont(size: 18))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var isDownloading: Bool {
        if case .downloading = viewModel.progress { return true }
        return false
    }
}
