//
//  AudioPlayerManager.swift
//  ZQueue
//
//  Created by Ben Shiller on 3/7/26.
//

import Foundation
import AVFoundation
import SwiftData
import Observation
#if os(iOS)
import MediaPlayer
#endif

@Observable
final class AudioPlayerManager {
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var currentItem: AudioItem?
    var hasNext: Bool { currentIndex < queue.count - 1 }
    var hasPrevious: Bool { currentIndex > 0 }

    private var audioPlayer: AVAudioPlayer?
    private var queue: [AudioItem] = []
    private var currentIndex: Int = 0
    private var displayLink: Timer?
    private var delegate: PlayerDelegate?
    #if os(iOS)
    private var remoteCommandsConfigured = false
    #endif

    func loadQueue(_ items: [AudioItem]) {
        queue = items.sorted { $0.order < $1.order }
    }

    func play() {
        guard !queue.isEmpty else { return }
        if audioPlayer != nil {
            audioPlayer?.play()
            isPlaying = true
            startProgressTimer()
            #if os(iOS)
            updateNowPlayingPlaybackInfo()
            #endif
        } else {
            playItem(at: currentIndex)
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
        #if os(iOS)
        updateNowPlayingPlaybackInfo()
        #endif
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func skipForward() {
        guard hasNext else { return }
        currentIndex += 1
        playItem(at: currentIndex)
    }

    func skipBackward() {
        // If more than 3 seconds in, restart current track
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        guard hasPrevious else {
            seek(to: 0)
            return
        }
        currentIndex -= 1
        playItem(at: currentIndex)
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
        #if os(iOS)
        updateNowPlayingPlaybackInfo()
        #endif
    }

    func playItem(at index: Int) {
        guard index >= 0, index < queue.count else { return }
        currentIndex = index
        let item = queue[index]
        currentItem = item

        guard let url = item.resolveURL() else { return }

        let accessing = url.startAccessingSecurityScopedResource()

        do {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
            #endif

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            let playerDelegate = PlayerDelegate { [weak self] in
                self?.handlePlaybackFinished()
            }
            delegate = playerDelegate
            audioPlayer?.delegate = playerDelegate
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            audioPlayer?.play()
            isPlaying = true
            startProgressTimer()

            #if os(iOS)
            configureRemoteCommands()
            updateNowPlayingInfo()
            #endif
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }

        if accessing {
            url.stopAccessingSecurityScopedResource()
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        currentItem = nil
        stopProgressTimer()
        #if os(iOS)
        clearNowPlayingInfo()
        #endif
    }

    private func handlePlaybackFinished() {
        if hasNext {
            skipForward()
        } else {
            stop()
        }
    }

    private func startProgressTimer() {
        stopProgressTimer()
        displayLink = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }

    private func stopProgressTimer() {
        displayLink?.invalidate()
        displayLink = nil
    }

    // MARK: - Now Playing & Remote Commands

    #if os(iOS)
    private func configureRemoteCommands() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true

        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self, self.hasNext else { return .commandFailed }
            self.skipForward()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: positionEvent.positionTime)
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = currentItem?.title ?? ""
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackInfo() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            updateNowPlayingInfo()
            return
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer?.currentTime ?? currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    #endif
}

// MARK: - AVAudioPlayerDelegate wrapper

private final class PlayerDelegate: NSObject, AVAudioPlayerDelegate, Sendable {
    private let onFinish: @Sendable () -> Void

    init(onFinish: @escaping @Sendable () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            onFinish()
        }
    }
}
