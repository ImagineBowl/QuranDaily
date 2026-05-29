import Foundation

@MainActor
@Observable
final class SettingsViewModel {
    private let settingsRepository: SettingsRepositoryProtocol
    private let storageInfoUseCase: StorageInfoUseCase
    private let clearCacheUseCase: ClearCacheUseCase

    var settings: AppSettings = .default
    var storageInfo = StorageInfo(quranDataBytes: 0, audioBytes: 0)
    var isLoading = false
    var statusMessage: String?

    init(
        settingsRepository: SettingsRepositoryProtocol,
        storageInfoUseCase: StorageInfoUseCase,
        clearCacheUseCase: ClearCacheUseCase
    ) {
        self.settingsRepository = settingsRepository
        self.storageInfoUseCase = storageInfoUseCase
        self.clearCacheUseCase = clearCacheUseCase
    }

    func load() async {
        isLoading = true
        settings = await settingsRepository.fetchSettings()
        storageInfo = await storageInfoUseCase.execute()
        isLoading = false
    }

    func updateFontSize(_ size: Double) async {
        settings.fontSize = size
        await settingsRepository.saveSettings(settings)
    }

    func updateTheme(_ theme: AppThemeMode) async {
        settings.theme = theme
        await settingsRepository.saveSettings(settings)
    }

    func clearQuranCache() async {
        do {
            try await clearCacheUseCase.execute(clearQuran: true, clearAudio: false)
            storageInfo = await storageInfoUseCase.execute()
            statusMessage = "Quran cache cleared."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func clearAudioCache() async {
        do {
            try await clearCacheUseCase.execute(clearQuran: false, clearAudio: true)
            storageInfo = await storageInfoUseCase.execute()
            statusMessage = "Audio cache cleared."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func clearAllCache() async {
        do {
            try await clearCacheUseCase.execute(clearQuran: true, clearAudio: true)
            storageInfo = await storageInfoUseCase.execute()
            statusMessage = "All cache cleared."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
