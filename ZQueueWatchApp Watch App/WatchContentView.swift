//
//  WatchContentView.swift
//  ZQueue Watch App
//
//  Created by Ben Shiller on 3/7/26.
//

import SwiftUI

struct WatchContentView: View {
    @Bindable var connectivityManager: WatchConnectivityManager
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                WatchQueueView(connectivityManager: connectivityManager, selectedTab: $selectedTab)
            }
            .tag(0)

            WatchPlaybackView(connectivityManager: connectivityManager)
                .tag(1)
        }
    }
}
