//
//  SettingsView.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Binding var appSettings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Font Size: \(Int(viewModel.settings.fontSize))")
                            .font(AppTheme.bodyFont(size: 20))

                        Slider(
                            value: Binding(
                                get: { viewModel.settings.fontSize },
                                set: { newValue in
                                    Task { await viewModel.updateFontSize(newValue) }
                                }
                            ),
                            in: 16...36,
                            step: 1
                        )
                        .tint(AppTheme.accent)
                    }
                    .padding(.vertical, 8)

                    Picker("Arabic Script", selection: Binding(
                        get: { viewModel.settings.quranScript },
                        set: { newValue in
                            Task { await viewModel.updateQuranScript(newValue) }
                        }
                    )) {
                        ForEach(QuranScriptChoice.allCases, id: \.self) { script in
                            Text(script.displayName).tag(script)
                        }
                    }

                    Picker("Arabic Font", selection: Binding(
                        get: { viewModel.settings.arabicFont },
                        set: { newValue in
                            Task { await viewModel.updateArabicFont(newValue) }
                        }
                    )) {
                        ForEach(ArabicFontChoice.allCases, id: \.self) { font in
                            Text(font.displayName).tag(font)
                        }
                    }

                    Picker("Urdu Font", selection: Binding(
                        get: { viewModel.settings.urduFont },
                        set: { newValue in
                            Task { await viewModel.updateUrduFont(newValue) }
                        }
                    )) {
                        ForEach(UrduFontChoice.allCases, id: \.self) { font in
                            Text(font.displayName).tag(font)
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { viewModel.settings.theme },
                        set: { newTheme in
                            Task { await viewModel.updateTheme(newTheme) }
                        }
                    )) {
                        ForEach(AppThemeMode.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .font(AppTheme.bodyFont(size: 20))
                }

                Section("Storage") {
                    LabeledContent("Quran Data") {
                        Text(viewModel.storageInfo.formattedQuranData)
                    }
                    LabeledContent("Audio") {
                        Text(viewModel.storageInfo.formattedAudio)
                    }
                    LabeledContent("Total") {
                        Text(viewModel.storageInfo.formattedTotal)
                            .fontWeight(.semibold)
                    }

                    Button("Clear Quran Cache", role: .destructive) {
                        Task { await viewModel.clearQuranCache() }
                    }

                    Button("Clear Audio Cache", role: .destructive) {
                        Task { await viewModel.clearAudioCache() }
                    }

                    Button("Clear All Cache", role: .destructive) {
                        Task { await viewModel.clearAllCache() }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Help keep QuranDaily free")
                            .font(AppTheme.titleFont(size: 20))

                        Text(
                            "QuranDaily is free with no account required. If it helps your daily reading, you can optionally leave a tip to support its development."
                        )
                        .font(AppTheme.bodyFont(size: 15))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    if viewModel.tipOptions.isEmpty {
                        Text("Tip options are unavailable right now.")
                            .font(AppTheme.bodyFont(size: 15))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.tipOptions) { option in
                            Button {
                                Task { await viewModel.tip(option) }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(AppTheme.accent)
                                    Text(option.displayName)
                                        .font(AppTheme.bodyFont(size: 17))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(option.displayPrice)
                                        .font(.system(size: 15, weight: .semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .foregroundStyle(AppTheme.accent)
                                        .background(AppTheme.accent.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isPurchasing)
                        }
                    }
                } header: {
                    Text("Support")
                } footer: {
                    Text("Completely optional. No features are locked behind support.")
                }

                Section("App Info") {
                    LabeledContent("App") {
                        Text(AppInfo.displayName)
                    }
                    LabeledContent("Version") {
                        Text(AppInfo.versionDisplay)
                    }
                    LabeledContent("Data Source") {
                        Text("AlQuran Cloud, islamic.app")
                    }

                    Link(destination: AppInfo.privacyPolicyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: AppInfo.supportURL) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }

                if let status = viewModel.statusMessage {
                    Section {
                        Text(status)
                            .font(AppTheme.bodyFont(size: 18))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await viewModel.load()
                await viewModel.loadTips()
                appSettings = viewModel.settings
            }
            .onChange(of: viewModel.settings) { _, newValue in
                appSettings = newValue
            }
        }
    }
}
