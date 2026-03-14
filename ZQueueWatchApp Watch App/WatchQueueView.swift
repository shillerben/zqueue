//
//  WatchQueueView.swift
//  ZQueue Watch App
//
//  Created by Ben Shiller on 3/13/26.
//

import SwiftUI

struct WatchQueueView: View {
    @Bindable var connectivityManager: WatchConnectivityManager
    @Binding var selectedTab: Int

    var body: some View {
        if connectivityManager.queueItems.isEmpty {
            ContentUnavailableView {
                Label("No Queue", systemImage: "music.note.list")
            } description: {
                Text("Add audio files on your iPhone.")
            }
        } else {
            List {
                ForEach(Array(connectivityManager.queueItems.enumerated()), id: \.offset) { index, title in
                    Button {
                        connectivityManager.sendCommand(.playItemAtIndex(index))
                        selectedTab = 1
                    } label: {
                        HStack {
                            Image(systemName: title == connectivityManager.currentTrackTitle ? "speaker.wave.2.fill" : "music.note")
                                .foregroundColor(title == connectivityManager.currentTrackTitle ? .accentColor : .secondary)
                                .frame(width: 20)
                            Text(title)
                                .font(.body)
                                .lineLimit(2)
                        }
                    }
                    .tint(.primary)
                }
                .onMove(perform: moveItems)
            }
            .navigationTitle("ZQueue")
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        connectivityManager.queueItems.move(fromOffsets: source, toOffset: destination)
        connectivityManager.sendCommand(.reorderQueue(connectivityManager.queueItems))
    }
}
