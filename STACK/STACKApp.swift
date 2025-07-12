//
//  STACKApp.swift
//  STACK
//
//  Created by James Swent on 7/9/25.
//

import SwiftUI
import SwiftData

@main
struct STACKApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedItem.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
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
