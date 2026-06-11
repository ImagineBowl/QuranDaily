//
//  AudioPlayerService.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import AVFoundation
import Foundation
import UIKit

@MainActor
final class AudioPlayerService: NSObject, AudioPlayerProtocol {
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var timeObserver: Any?
    private var interruptionObserver: NSObjectProtocol?
    private var becameActiveObserver: NSObjectProtocol?
    private var remoteCommandsConfigured = false
    private var lastNowPlayingUpdate: TimeInterval = 0
    private(set) var currentSurahNumber: Int?
    private(set) var currentAyahInSurah: Int?
    private var ayahSequenceEnd: Int?
    private var stopsAtSurahEnd = false
    private let audioRepository: AudioRepositoryProtocol
    var onPlaybackUpdate: (@MainActor () -> Void)?

    var isPlaying: Bool {
        (player?.rate ?? 0) > 0
    }

    var currentTime: TimeInterval {
        let time = player?.currentTime() ?? .zero
        guard time.isNumeric else { return 0 }
        return time.seconds
    }

    var duration: TimeInterval {
        let duration = player?.currentItem?.duration ?? .zero
        guard duration.isNumeric else { return 0 }
        return duration.seconds
    }

    init(audioRepository: AudioRepositoryProtocol) {
        self.audioRepository = audioRepository
        super.init()
        configureAudioSession()
        setupRemoteCommands()
        setupLifecycleObservers()
    }

    func pause() {
        player?.pause()
        notifyPlaybackUpdate()
    }

    func resume() {
        guard let player else { return }
        configureAudioSession()
        player.play()
        notifyPlaybackUpdate()
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        updateNowPlaying()
    }

    func stop() {
        teardownPlayer()
        currentSurahNumber = nil
        currentAyahInSurah = nil
        ayahSequenceEnd = nil
        stopsAtSurahEnd = false
        NowPlayingManager.shared.clear()
        notifyPlaybackUpdate()
    }

    func playFullSurah(_ surahNumber: Int, stopsAtSurahEnd: Bool = false) async throws {
        self.stopsAtSurahEnd = stopsAtSurahEnd
        let url = await audioRepository.playbackURL(forSurah: surahNumber)
        try await startPlayback(
            url: url,
            surahNumber: surahNumber,
            ayahInSurah: nil,
            sequenceEnd: nil
        )
    }

    func playSurah(
        _ surahNumber: Int,
        fromAyah ayahInSurah: Int,
        totalAyahs: Int,
        stopsAtSurahEnd: Bool = false
    ) async throws {
        self.stopsAtSurahEnd = stopsAtSurahEnd
        let url = try await audioRepository.ayahStreamingURL(
            surahNumber: surahNumber,
            ayahInSurah: ayahInSurah
        )
        try await startPlayback(
            url: url,
            surahNumber: surahNumber,
            ayahInSurah: ayahInSurah,
            sequenceEnd: totalAyahs
        )
    }

    func playNext() async throws {
        if let end = ayahSequenceEnd,
           let surah = currentSurahNumber,
           let ayah = currentAyahInSurah,
           ayah < end {
            try await playSurah(surah, fromAyah: ayah + 1, totalAyahs: end)
            return
        }

        guard let current = currentSurahNumber else { return }
        let next = min(current + 1, 114)
        try await playFullSurah(next)
    }

    func playPrevious() async throws {
        if let end = ayahSequenceEnd,
           let surah = currentSurahNumber,
           let ayah = currentAyahInSurah,
           ayah > 1 {
            try await playSurah(surah, fromAyah: ayah - 1, totalAyahs: end)
            return
        }

        guard let current = currentSurahNumber else { return }
        let previous = max(current - 1, 1)
        try await playFullSurah(previous)
    }

    private func startPlayback(
        url: URL,
        surahNumber: Int,
        ayahInSurah: Int?,
        sequenceEnd: Int?
    ) async throws {
        teardownPlayer()
        configureAudioSession()

        if url.isFileURL {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw QuranError.audioNotAvailable
            }
        }

        currentSurahNumber = surahNumber
        currentAyahInSurah = ayahInSurah
        ayahSequenceEnd = sequenceEnd

        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        avPlayer.automaticallyWaitsToMinimizeStalling = false
        player = avPlayer
        observeEnd(of: item)
        addPeriodicTimeObserver(to: avPlayer)
        avPlayer.play()
        notifyPlaybackUpdate()
    }

    private func teardownPlayer() {
        player?.pause()
        removeTimeObserver()
        player = nil
        removeEndObserver()
    }

    private func addPeriodicTimeObserver(to player: AVPlayer) {
        removeTimeObserver()
        let interval = CMTime(seconds: 0.3, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.notifyPlaybackUpdate()
            }
        }
    }

    private func removeTimeObserver() {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    private func observeEnd(of item: AVPlayerItem) {
        removeEndObserver()
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleCurrentItemEnded()
            }
        }
    }

    private func handleCurrentItemEnded() async {
        if let end = ayahSequenceEnd,
           let surah = currentSurahNumber,
           let ayah = currentAyahInSurah,
           ayah < end {
            try? await playSurah(
                surah,
                fromAyah: ayah + 1,
                totalAyahs: end,
                stopsAtSurahEnd: stopsAtSurahEnd
            )
            return
        }

        if stopsAtSurahEnd {
            finishCurrentSurahPlayback()
            return
        }

        try? await playNext()
    }

    private func finishCurrentSurahPlayback() {
        player?.pause()
        removeTimeObserver()
        player = nil
        removeEndObserver()
        notifyPlaybackUpdate()
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    private func setupRemoteCommands() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true

        NowPlayingManager.shared.configureRemoteCommands(
            play: { [weak self] in
                Task { @MainActor in self?.resume() }
            },
            pause: { [weak self] in
                Task { @MainActor in self?.pause() }
            },
            togglePlayPause: { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    if self.isPlaying {
                        self.pause()
                    } else {
                        self.resume()
                    }
                }
            },
            playNext: { [weak self] in
                Task { @MainActor in
                    try? await self?.playNext()
                }
            },
            playPrevious: { [weak self] in
                Task { @MainActor in
                    try? await self?.playPrevious()
                }
            },
            changePlaybackPosition: { [weak self] time in
                Task { @MainActor in self?.seek(to: time) }
            }
        )
    }

    private func setupLifecycleObservers() {
        #if os(iOS)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor in
                self?.handleAudioInterruption(typeValue: typeValue, optionsValue: optionsValue)
            }
        }

        becameActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isPlaying else { return }
                self.configureAudioSession()
            }
        }
        #endif
    }

    private func handleAudioInterruption(typeValue: UInt?, optionsValue: UInt?) {
        #if os(iOS)
        guard let typeValue, let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            break
        case .ended:
            guard let optionsValue else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                configureAudioSession()
                player?.play()
                notifyPlaybackUpdate()
            }
        @unknown default:
            break
        }
        #endif
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true, options: [])
        } catch {
            // Session setup failed; playback may still work on some devices.
        }
        #endif
    }

    private func notifyPlaybackUpdate() {
        updateNowPlayingIfNeeded()
        onPlaybackUpdate?()
    }

    private func updateNowPlayingIfNeeded() {
        let now = Date().timeIntervalSinceReferenceDate
        guard now - lastNowPlayingUpdate >= 0.5 else { return }
        lastNowPlayingUpdate = now
        updateNowPlaying()
    }

    private func updateNowPlaying() {
        guard let surah = currentSurahNumber else {
            NowPlayingManager.shared.clear()
            return
        }

        var title = "Surah \(surah)"
        if let ayah = currentAyahInSurah {
            title += " · Ayah \(ayah)"
        }

        NowPlayingManager.shared.updateNowPlaying(
            title: title,
            artist: "Mishari Alafasy",
            duration: duration,
            elapsed: currentTime,
            isPlaying: isPlaying
        )
    }
}
