//
//  SettingsViewModel.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import Foundation
import StoreKit

struct TipOption: Identifiable, Sendable {
    let id: String
    let displayName: String
    let displayPrice: String
}

@MainActor
@Observable
final class SettingsViewModel {
    private let settingsRepository: SettingsRepositoryProtocol
    private let storageInfoUseCase: StorageInfoUseCase
    private let clearCacheUseCase: ClearCacheUseCase
    private let tipJarService: TipJarServiceProtocol

    var settings: AppSettings = .default
    var storageInfo = StorageInfo(quranDataBytes: 0, audioBytes: 0)
    var isLoading = false
    var statusMessage: String?
    var tipOptions: [TipOption] = []
    var isPurchasing = false

    private var productsByID: [String: Product] = [:]

    init(
        settingsRepository: SettingsRepositoryProtocol,
        storageInfoUseCase: StorageInfoUseCase,
        clearCacheUseCase: ClearCacheUseCase,
        tipJarService: TipJarServiceProtocol
    ) {
        self.settingsRepository = settingsRepository
        self.storageInfoUseCase = storageInfoUseCase
        self.clearCacheUseCase = clearCacheUseCase
        self.tipJarService = tipJarService
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

    func updateArabicFont(_ font: ArabicFontChoice) async {
        settings.arabicFont = font
        await settingsRepository.saveSettings(settings)
    }

    func updateUrduFont(_ font: UrduFontChoice) async {
        settings.urduFont = font
        await settingsRepository.saveSettings(settings)
    }

    func updateTheme(_ theme: AppThemeMode) async {
        settings.theme = theme
        await settingsRepository.saveSettings(settings)
    }

    func loadTips() async {
        guard let products = try? await tipJarService.loadProducts() else { return }
        productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        tipOptions = products.map {
            TipOption(id: $0.id, displayName: $0.displayName, displayPrice: $0.displayPrice)
        }
    }

    func tip(_ option: TipOption) async {
        guard let product = productsByID[option.id] else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            if try await tipJarService.purchase(product) {
                statusMessage = "Thank you for supporting QuranDaily!"
            }
        } catch {
            statusMessage = error.localizedDescription
        }
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
