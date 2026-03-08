//
//  PhoneConnectivityManager.swift
//  ZQueue
//
//  Created by Ben Shiller on 3/7/26.
//

#if os(iOS)
import Foundation
import WatchConnectivity
import Observation

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
        }
    }

    func sendQueueState(items: [AudioItem], currentTrack: String?, isPlaying: Bool) {
        guard let session, session.activationState == .activated else { return }
        let context: [String: Any] = [
            "queueItems": items.sorted { $0.order < $1.order }.map(\.title),
            "currentTrack": currentTrack ?? "",
            "isPlaying": isPlaying
        ]
        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Failed to update application context: \(error.localizedDescription)")
        }
    }

    func sendNowPlayingUpdate(currentTrack: String?, isPlaying: Bool) {
        guard let session, session.isReachable else { return }
        var message: [String: Any] = ["isPlaying": isPlaying]
        if let currentTrack {
            message["currentTrack"] = currentTrack
        }
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message: \(error.localizedDescription)")
        }
    }
}

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let commandString = message["command"] as? String else { return }
        Task { @MainActor in
            switch commandString {
            case "togglePlayPause":
                self.playerManager?.togglePlayPause()
            case "skipForward":
                self.playerManager?.skipForward()
            case "skipBackward":
                self.playerManager?.skipBackward()
            default:
                break
            }
        }
    }
}
#endif
