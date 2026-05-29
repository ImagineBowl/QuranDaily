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

                Section("App Info") {
                    LabeledContent("App") {
                        Text("QuranDaily")
                    }
                    LabeledContent("Version") {
                        Text("1.0.0")
                    }
                    LabeledContent("Data Source") {
                        Text("AlQuran Cloud")
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
                appSettings = viewModel.settings
            }
            .onChange(of: viewModel.settings) { _, newValue in
                appSettings = newValue
            }
        }
    }
}
