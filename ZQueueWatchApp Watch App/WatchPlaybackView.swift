//
//  WatchPlaybackView.swift
//  ZQueue Watch App
//
//  Created by Ben Shiller on 3/13/26.
//

import SwiftUI

struct WatchPlaybackView: View {
    @Bindable var connectivityManager: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            if let title = connectivityManager.currentTrackTitle {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else {
                Text("Not Playing")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Spacer()

                Button {
                    if connectivityManager.controlMode == "podcast" {
                        connectivityManager.sendCommand(.skipBack15)
                    } else {
                        connectivityManager.sendCommand(.skipBackward)
                    }
                } label: {
                    Image(systemName: connectivityManager.controlMode == "podcast" ? "gobackward.15" : "backward.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)

                Spacer()

                Button {
                    connectivityManager.sendCommand(.togglePlayPause)
                } label: {
                    Image(systemName: connectivityManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }
                .buttonStyle(.borderless)

                Spacer()

                Button {
                    if connectivityManager.controlMode == "podcast" {
                        connectivityManager.sendCommand(.skipForward15)
                    } else {
                        connectivityManager.sendCommand(.skipForward)
                    }
                } label: {
                    Image(systemName: connectivityManager.controlMode == "podcast" ? "goforward.15" : "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)

                Spacer()
            }

            Spacer()
        }
        .padding()
    }
}
