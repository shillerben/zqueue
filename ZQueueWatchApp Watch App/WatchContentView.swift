//
//  WatchContentView.swift
//  ZQueue Watch App
//
//  Created by Ben Shiller on 3/7/26.
//

import SwiftUI

struct WatchContentView: View {
    @Bindable var connectivityManager: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            if connectivityManager.queueItems.isEmpty {
                ContentUnavailableView {
                    Label("No Queue", systemImage: "music.note.list")
                } description: {
                    Text("Add audio files on your iPhone.")
                }
            } else {
                List {
                    // Now Playing section
                    if let currentTitle = connectivityManager.currentTrackTitle {
                        Section("Now Playing") {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.accentColor)
                                Text(currentTitle)
                                    .font(.headline)
                                    .lineLimit(2)
                            }
                        }
                    }

                    // Playback controls
                    Section {
                        HStack {
                            Spacer()
                            Button {
                                connectivityManager.sendCommand(.skipBackward)
                            } label: {
                                Image(systemName: "backward.fill")
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
                                connectivityManager.sendCommand(.skipForward)
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderless)

                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }

                    // Queue section
                    Section("Queue") {
                        ForEach(connectivityManager.queueItems, id: \.self) { title in
                            HStack {
                                Image(systemName: title == connectivityManager.currentTrackTitle ? "speaker.wave.2.fill" : "music.note")
                                    .foregroundColor(title == connectivityManager.currentTrackTitle ? .accentColor : .secondary)
                                    .frame(width: 20)
                                Text(title)
                                    .font(.body)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .navigationTitle("ZQueue")
            }
        }
    }
}
