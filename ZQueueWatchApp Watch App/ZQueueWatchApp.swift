//
//  ZQueueWatchApp.swift
//  ZQueue Watch App
//
//  Created by Ben Shiller on 3/7/26.
//

import SwiftUI

@main
struct ZQueueWatchApp: App {
    @State private var connectivityManager = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            WatchContentView(connectivityManager: connectivityManager)
        }
    }
}
