import SwiftUI

enum AppTheme {
    static let minimumTapSize: CGFloat = 48
    static let cardCornerRadius: CGFloat = 16
    static let sectionSpacing: CGFloat = 20

    static func arabicFont(size: Double, choice: ArabicFontChoice = .amiriQuran) -> Font {
        let resolvedSize = size + 6
        if let postScriptName = choice.postScriptName {
            return .custom(postScriptName, size: resolvedSize)
        }
        return .system(size: resolvedSize, weight: .regular, design: .serif)
    }

    static func urduFont(size: Double, choice: UrduFontChoice = .notoNastaliq) -> Font {
        if let postScriptName = choice.postScriptName {
            return .custom(postScriptName, size: size)
        }
        return .system(size: size, weight: .regular)
    }

    static func bodyFont(size: Double) -> Font {
        .system(size: size, weight: .regular)
    }

    static func titleFont(size: Double) -> Font {
        .system(size: size + 4, weight: .semibold)
    }

    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let accent = Color(red: 0.12, green: 0.45, blue: 0.35)

    /// How often to re-sync the UI clock with AVPlayer while playing (drift correction).
    static let playbackDriftSyncInterval: TimeInterval = 2
}

struct PlaybackProgressModel {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    let trackID: String

    func progress(at date: Date, referenceDate: Date, referenceTime: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        let elapsed = isPlaying ? referenceTime + date.timeIntervalSince(referenceDate) : currentTime
        let clamped = min(max(elapsed, 0), duration)
        return clamped / duration
    }

    func elapsedTime(at date: Date, referenceDate: Date, referenceTime: TimeInterval) -> TimeInterval {
        guard duration > 0 else { return 0 }
        let elapsed = isPlaying ? referenceTime + date.timeIntervalSince(referenceDate) : currentTime
        return min(max(elapsed, 0), duration)
    }
}

struct SmoothPlaybackProgressView: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    let trackID: String

    @State private var referenceDate = Date()
    @State private var referenceTime: TimeInterval = 0

    private var model: PlaybackProgressModel {
        PlaybackProgressModel(
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying,
            trackID: trackID
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying || duration <= 0)) { context in
            let progress = isPlaying
                ? model.progress(at: context.date, referenceDate: referenceDate, referenceTime: referenceTime)
                : min(max(currentTime / max(duration, 1), 0), 1)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.25))

                    Capsule()
                        .fill(AppTheme.accent)
                        .frame(width: max(geometry.size.width * progress, 0))
                }
            }
            .frame(height: 4)
        }
        .onAppear { resyncReference(to: currentTime) }
        .onChange(of: trackID) { _, _ in resyncReference(to: currentTime) }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                resyncReference(to: currentTime)
            } else {
                referenceTime = currentTime
            }
        }
        .onChange(of: currentTime) { oldValue, newValue in
            guard isPlaying else {
                referenceTime = newValue
                return
            }

            // Large jumps mean seek or track change — re-anchor to the player.
            if abs(newValue - oldValue) > 0.75 {
                resyncReference(to: newValue)
            }
        }
    }

    private func resyncReference(to time: TimeInterval) {
        referenceTime = time
        referenceDate = Date()
    }
}

struct SmoothPlaybackSlider: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    let trackID: String
    let onSeek: (Double) -> Void

    @State private var referenceDate = Date()
    @State private var referenceTime: TimeInterval = 0
    @State private var isEditing = false
    @State private var editProgress: Double = 0

    private var model: PlaybackProgressModel {
        PlaybackProgressModel(
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying,
            trackID: trackID
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: (!isPlaying && !isEditing) || duration <= 0)) { context in
            let liveProgress = isPlaying
                ? model.progress(at: context.date, referenceDate: referenceDate, referenceTime: referenceTime)
                : min(max(currentTime / max(duration, 1), 0), 1)
            let displayedProgress = isEditing ? editProgress : liveProgress

            Slider(
                value: Binding(
                    get: { displayedProgress },
                    set: { newValue in
                        isEditing = true
                        editProgress = newValue
                    }
                ),
                in: 0...1,
                onEditingChanged: { editing in
                    isEditing = editing
                    if editing {
                        editProgress = liveProgress
                    } else {
                        onSeek(editProgress)
                        resyncReference(to: editProgress * duration)
                    }
                }
            )
            .tint(AppTheme.accent)
        }
        .onAppear { resyncReference(to: currentTime) }
        .onChange(of: trackID) { _, _ in
            isEditing = false
            resyncReference(to: currentTime)
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                resyncReference(to: currentTime)
            } else if !isEditing {
                referenceTime = currentTime
            }
        }
        .onChange(of: currentTime) { oldValue, newValue in
            guard isPlaying, !isEditing else {
                if !isEditing {
                    referenceTime = newValue
                }
                return
            }

            if abs(newValue - oldValue) > 0.75 {
                resyncReference(to: newValue)
            }
        }
    }

    private func resyncReference(to time: TimeInterval) {
        referenceTime = time
        referenceDate = Date()
    }
}

struct PlaybackElapsedTimeLabel: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    let trackID: String

    @State private var referenceDate = Date()
    @State private var referenceTime: TimeInterval = 0

    private var model: PlaybackProgressModel {
        PlaybackProgressModel(
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying,
            trackID: trackID
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying || duration <= 0)) { context in
            let elapsed = isPlaying
                ? model.elapsedTime(at: context.date, referenceDate: referenceDate, referenceTime: referenceTime)
                : currentTime
            Text(formatTime(elapsed))
        }
        .onAppear { resyncReference(to: currentTime) }
        .onChange(of: trackID) { _, _ in resyncReference(to: currentTime) }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                resyncReference(to: currentTime)
            } else {
                referenceTime = currentTime
            }
        }
        .onChange(of: currentTime) { oldValue, newValue in
            guard isPlaying else {
                referenceTime = newValue
                return
            }
            if abs(newValue - oldValue) > 0.75 {
                resyncReference(to: newValue)
            }
        }
    }

    private func resyncReference(to time: TimeInterval) {
        referenceTime = time
        referenceDate = Date()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(Int(time), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct LargeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTapSize)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: AppTheme.minimumTapSize)
            .background(AppTheme.secondaryBackground.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}
