//
//  ZQueueApp.swift
//  ZQueue
//
//  Created by Ben Shiller on 3/7/26.
//

import SwiftUI
import SwiftData

@main
struct ZQueueApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AudioItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
