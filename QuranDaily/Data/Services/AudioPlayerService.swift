//
//  AudioPlayerService.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import AVFoundation
import Foundation

@MainActor
final class AudioPlayerService: NSObject, AudioPlayerProtocol {
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var timeObserver: Any?
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
    }

    func stop() {
        teardownPlayer()
        currentSurahNumber = nil
        currentAyahInSurah = nil
        ayahSequenceEnd = nil
        stopsAtSurahEnd = false
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
        // Frequent updates so the mini-player reflects the new item's duration and
        // position as soon as an ayah transition starts, instead of waiting on the
        // slower drift-sync timer.
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

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
        } catch {
            // Session setup failed; playback may still work on some devices.
        }
        #endif
    }

    private func notifyPlaybackUpdate() {
        onPlaybackUpdate?()
    }
}
