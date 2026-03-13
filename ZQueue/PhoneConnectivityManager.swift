//
//  PhoneConnectivityManager.swift
//  ZQueue
//
//  Created by Ben Shiller on 3/7/26.
//

import Foundation
import WatchConnectivity
import os
import Observation

private let log = Logger(subsystem: "com.zqueue", category: "PhoneConnectivity")

@Observable
final class PhoneConnectivityManager: NSObject {
    private var session: WCSession?
    private weak var playerManager: AudioPlayerManager?

    func configure(playerManager: AudioPlayerManager) {
        self.playerManager = playerManager
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            log.info("WCSession activated from phone")
        } else {
            log.warning("WCSession is NOT supported on this device")
        }
    }

    func sendQueueState(items: [AudioItem], currentTrack: String?, isPlaying: Bool) {
        guard let session else {
            log.warning("sendQueueState: session is nil")
            return
        }
        guard session.activationState == .activated else {
            log.warning("sendQueueState: session not activated (state=\(session.activationState.rawValue))")
            return
        }
        let titles = items.sorted { $0.order < $1.order }.map(\.title)
        let context: [String: Any] = [
            "queueItems": titles,
            "currentTrack": currentTrack ?? "",
            "isPlaying": isPlaying
        ]
        log.info("sendQueueState: \(titles.count) items, currentTrack=\(currentTrack ?? "nil"), isPlaying=\(isPlaying), isPaired=\(session.isPaired), isWatchAppInstalled=\(session.isWatchAppInstalled), isReachable=\(session.isReachable)")
        do {
            try session.updateApplicationContext(context)
            log.info("sendQueueState: updateApplicationContext succeeded")
        } catch {
            log.error("sendQueueState: updateApplicationContext failed: \(error.localizedDescription)")
        }
    }

    func sendNowPlayingUpdate(currentTrack: String?, isPlaying: Bool) {
        guard let session else {
            log.warning("sendNowPlayingUpdate: session is nil")
            return
        }
        guard session.isReachable else {
            log.warning("sendNowPlayingUpdate: watch not reachable (activationState=\(session.activationState.rawValue), isPaired=\(session.isPaired), isWatchAppInstalled=\(session.isWatchAppInstalled))")
            return
        }
        var message: [String: Any] = ["isPlaying": isPlaying]
        if let currentTrack {
            message["currentTrack"] = currentTrack
        }
        log.info("sendNowPlayingUpdate: currentTrack=\(currentTrack ?? "nil"), isPlaying=\(isPlaying)")
        session.sendMessage(message, replyHandler: nil) { error in
            log.error("sendNowPlayingUpdate: sendMessage failed: \(error.localizedDescription)")
        }
    }
}

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            log.error("WCSession activation failed: \(error.localizedDescription)")
        } else {
            log.info("WCSession activation completed: state=\(activationState.rawValue), isPaired=\(session.isPaired), isWatchAppInstalled=\(session.isWatchAppInstalled), isReachable=\(session.isReachable)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        log.info("WCSession did become inactive")
    }
    func sessionDidDeactivate(_ session: WCSession) {
        log.info("WCSession did deactivate, reactivating")
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        log.info("WCSession reachability changed: isReachable=\(session.isReachable)")
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        log.info("Received message from watch: \(message.keys.joined(separator: ", "))")
        guard let commandString = message["command"] as? String else {
            log.warning("Received message without 'command' key: \(message)")
            return
        }
        log.info("Executing watch command: \(commandString)")
        Task { @MainActor in
            switch commandString {
            case "togglePlayPause":
                self.playerManager?.togglePlayPause()
            case "skipForward":
                self.playerManager?.skipForward()
            case "skipBackward":
                self.playerManager?.skipBackward()
            default:
                log.warning("Unknown watch command: \(commandString)")
            }
        }
    }
}
