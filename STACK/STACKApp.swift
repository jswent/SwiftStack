//
//  STACKApp.swift
//  STACK
//
//  Created by James Swent on 7/9/25.
//

import App
import SavedItem
import SwiftData
import SwiftUI

@main
struct SwiftUISampleAppApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try createSharedModelContainer()
            setupDarwinNotificationObserver()
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            CoordinatorView(container: .live)
                .modelContainer(modelContainer)
                .onOpenURL { url in
                    // Handle URLs from share extension
                    Task {
                        await handleIncomingURL(url)
                    }
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) async {
        // This will be handled by the existing URL routing system
        // The share extension sends "saveditem://items" to navigate to items list
        print("Received URL from share extension: \(url)")
    }
}

// MARK: - Shared Model Container

private func createSharedModelContainer() throws -> ModelContainer {
    let schema = Schema([SavedItem.self])
    let configuration = ModelConfiguration(
        schema: schema,
        allowsSave: true,
        groupContainer: .identifier("group.com.jswent.STACK"),
    )
    
    return try ModelContainer(for: schema, configurations: [configuration])
}

private func setupDarwinNotificationObserver() {
    let notificationName = "com.jswent.STACK.shareDidSave"
    
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        nil,
        { _, _, _, _, _ in
            print("DEBUG: Received Darwin notification from share extension")
            // The @Query in SavedItemListView should automatically pick up changes
            // This notification provides additional reliability if needed
        },
        notificationName as CFString,
        nil,
        .deliverImmediately
    )
    
    print("DEBUG: Registered Darwin notification observer for: \(notificationName)")
}

