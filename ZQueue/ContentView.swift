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
    #if os(iOS)
    @State private var connectivityManager = PhoneConnectivityManager()
    #endif

    var body: some View {
        QueueView(playerManager: playerManager)
        #if os(iOS)
            .onAppear {
                connectivityManager.configure(playerManager: playerManager)
            }
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AudioItem.self, inMemory: true)
}
