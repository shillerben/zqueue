//
//  WatchConnectivityManager.swift
//  ZQueue Watch App
//
//  Created by Ben Shiller on 3/7/26.
//

import Foundation
import WatchConnectivity
import Observation

enum PlaybackCommand: String {
    case togglePlayPause
    case skipForward
    case skipBackward
}

@Observable
final class WatchConnectivityManager: NSObject {
    var queueItems: [String] = []
    var currentTrackTitle: String?
    var isPlaying: Bool = false

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendCommand(_ command: PlaybackCommand) {
        guard let session, session.isReachable else { return }
        session.sendMessage(["command": command.rawValue], replyHandler: nil) { error in
            print("Error sending command: \(error.localizedDescription)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let items = applicationContext["queueItems"] as? [String] {
                self.queueItems = items
            }
            if let current = applicationContext["currentTrack"] as? String {
                self.currentTrackTitle = current
            }
            if let playing = applicationContext["isPlaying"] as? Bool {
                self.isPlaying = playing
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            if let current = message["currentTrack"] as? String {
                self.currentTrackTitle = current
            }
            if let playing = message["isPlaying"] as? Bool {
                self.isPlaying = playing
            }
        }
    }
}
