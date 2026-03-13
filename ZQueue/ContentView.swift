//
//  ContentView.swift
//  ZQueue
//
//  Created by Ben Shiller on 3/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var playerManager = AudioPlayerManager()
    @State private var connectivityManager = PhoneConnectivityManager()

    var body: some View {
        QueueView(playerManager: playerManager)
            .onAppear {
                connectivityManager.configure(playerManager: playerManager)
                playerManager.configure(connectivityManager: connectivityManager)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AudioItem.self, inMemory: true)
}
