//
//  NowPlayingManager.swift
//  QuranDaily
//

import Foundation
import MediaPlayer
import UIKit

@MainActor
final class NowPlayingManager {
    static let shared = NowPlayingManager()

    private init() {}

    func configureRemoteCommands(
        play: @escaping () -> Void,
        pause: @escaping () -> Void,
        togglePlayPause: @escaping () -> Void,
        playNext: @escaping () -> Void,
        playPrevious: @escaping () -> Void,
        changePlaybackPosition: @escaping (TimeInterval) -> Void
    ) {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true

        center.playCommand.addTarget { _ in
            play()
            return .success
        }
        center.pauseCommand.addTarget { _ in
            pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { _ in
            togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { _ in
            playNext()
            return .success
        }
        center.previousTrackCommand.addTarget { _ in
            playPrevious()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            changePlaybackPosition(event.positionTime)
            return .success
        }
    }

    func updateNowPlaying(
        title: String,
        artist: String,
        duration: TimeInterval,
        elapsed: TimeInterval,
        isPlaying: Bool
    ) {
        let info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}
