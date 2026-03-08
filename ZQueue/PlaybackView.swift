//
//  PlaybackView.swift
//  ZQueue
//
//  Created by Ben Shiller on 3/7/26.
//

import SwiftUI
import SwiftData

struct PlaybackView: View {
    @Bindable var playerManager: AudioPlayerManager
    var items: [AudioItem]
    @State private var showingQueue = false


    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Current track info
            VStack(spacing: 12) {
                Image(systemName: "music.note.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse, isActive: playerManager.isPlaying)

                Text(playerManager.currentItem?.title ?? "No Track Selected")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(playerManager.currentItem?.fileName ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            // Progress bar
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { playerManager.currentTime },
                        set: { playerManager.seek(to: $0) }
                    ),
                    in: 0...max(playerManager.duration, 1)
                )
                HStack {
                    Text(formatTime(playerManager.currentTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Spacer()
                    Text(formatTime(playerManager.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)

            // Playback controls
            HStack(spacing: 40) {
                Button {
                    playerManager.skipBackward()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title)
                }
                .disabled(!playerManager.hasPrevious && playerManager.currentTime <= 3)

                Button {
                    playerManager.togglePlayPause()
                } label: {
                    Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }

                Button {
                    playerManager.skipForward()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title)
                }
                .disabled(!playerManager.hasNext)
            }
            .padding(.bottom, 32)

            #if os(iOS)
            // Queue reorder dropdown (iPhone only)
            VStack(spacing: 0) {
                Button {
                    withAnimation {
                        showingQueue.toggle()
                    }
                } label: {
                    HStack {
                        Text("Up Next")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(showingQueue ? 90 : 0))
                            .animation(.easeInOut(duration: 0.2), value: showingQueue)
                    }
                    .contentShape(Rectangle())
                }
                .tint(.primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)

                if showingQueue {
                    List {
                        ForEach(items) { item in
                            Button {
                                if let index = items.firstIndex(where: { $0.id == item.id }) {
                                    playerManager.loadQueue(items)
                                    playerManager.playItem(at: index)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: item.id == playerManager.currentItem?.id ? "speaker.wave.2.fill" : "music.note")
                                        .foregroundColor(item.id == playerManager.currentItem?.id ? .accentColor : .secondary)
                                        .frame(width: 24)
                                    Text(item.title)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if item.id == playerManager.currentItem?.id {
                                        Text("Playing")
                                            .font(.caption)
                                            .foregroundStyle(.tint)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .tint(.primary)
                        }
                        .onMove(perform: moveQueueItems)
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, .constant(.active))
                    .frame(maxHeight: 240)
                }
            }
            .padding(.bottom, 16)
            #endif
        }
        .navigationTitle("Now Playing")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if playerManager.currentItem == nil, !items.isEmpty {
                playerManager.loadQueue(items)
                playerManager.play()
            }
        }
    }

    private func moveQueueItems(from source: IndexSet, to destination: Int) {
        var mutableItems = items
        mutableItems.move(fromOffsets: source, toOffset: destination)
        for (index, item) in mutableItems.enumerated() {
            item.order = index
        }
        playerManager.loadQueue(mutableItems)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
