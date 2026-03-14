//
//  WatchConnectivityManager.swift
//  ZQueue Watch App
//
//  Created by Ben Shiller on 3/7/26.
//

import Foundation
import WatchConnectivity
import os
import Observation

private let log = Logger(subsystem: "com.zqueue", category: "WatchConnectivity")

enum PlaybackCommand {
    case togglePlayPause
    case skipForward
    case skipBackward
    case skipForward15
    case skipBack15
    case playItemAtIndex(Int)
    case reorderQueue([String])
}

@Observable
final class WatchConnectivityManager: NSObject {
    var queueItems: [String] = []
    var currentTrackTitle: String?
    var isPlaying: Bool = false
    var controlMode: String = "music"

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            log.info("WCSession activated from watch")
        } else {
            log.warning("WCSession is NOT supported on this device")
        }
    }

    func sendCommand(_ command: PlaybackCommand) {
        guard let session else {
            log.warning("sendCommand: session is nil")
            return
        }
        guard session.isReachable else {
            log.warning("sendCommand: phone not reachable (activationState=\(session.activationState.rawValue))")
            return
        }

        var message: [String: Any] = [:]
        switch command {
        case .togglePlayPause:
            message["command"] = "togglePlayPause"
        case .skipForward:
            message["command"] = "skipForward"
        case .skipBackward:
            message["command"] = "skipBackward"
        case .skipForward15:
            message["command"] = "skipForward15"
        case .skipBack15:
            message["command"] = "skipBack15"
        case .playItemAtIndex(let index):
            message["command"] = "playItemAtIndex"
            message["index"] = index
        case .reorderQueue(let newOrder):
            message["command"] = "reorderQueue"
            message["queueItems"] = newOrder
        }

        log.info("sendCommand: \(message["command"] as? String ?? "unknown")")
        session.sendMessage(message, replyHandler: nil) { error in
            log.error("sendCommand failed: \(error.localizedDescription)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            log.error("WCSession activation failed: \(error.localizedDescription)")
        } else {
            log.info("WCSession activation completed: state=\(activationState.rawValue), isReachable=\(session.isReachable)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        log.info("WCSession reachability changed: isReachable=\(session.isReachable)")
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        log.info("Received applicationContext: keys=\(applicationContext.keys.joined(separator: ", "))")
        Task { @MainActor in
            if let items = applicationContext["queueItems"] as? [String] {
                log.info("  queueItems: \(items.count) items — \(items.joined(separator: ", "))")
                self.queueItems = items
            } else {
                log.warning("  queueItems key missing or wrong type")
            }
            if let current = applicationContext["currentTrack"] as? String {
                log.info("  currentTrack: \(current)")
                self.currentTrackTitle = current
            }
            if let playing = applicationContext["isPlaying"] as? Bool {
                log.info("  isPlaying: \(playing)")
                self.isPlaying = playing
            }
            if let mode = applicationContext["controlMode"] as? String {
                log.info("  controlMode: \(mode)")
                self.controlMode = mode
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        log.info("Received message: keys=\(message.keys.joined(separator: ", "))")
        Task { @MainActor in
            if let current = message["currentTrack"] as? String {
                log.info("  currentTrack: \(current)")
                self.currentTrackTitle = current
            }
            if let playing = message["isPlaying"] as? Bool {
                log.info("  isPlaying: \(playing)")
                self.isPlaying = playing
            }
            if let mode = message["controlMode"] as? String {
                log.info("  controlMode: \(mode)")
                self.controlMode = mode
            }
        }
    }
}
