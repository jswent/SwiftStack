//
//  CoordinatorView.swift
//  SwiftUISampleApp
//
//  Created by James Swent on 7/23/25.
//

import Core
import Foundation
import SavedItem
import SwiftData
import SwiftUI

public struct CoordinatorView: View {
    @State private var coordinator: Coordinator?
    @Environment(\.modelContext) private var modelContext
    private let container: Container

    public init(container: Container) {
        self.container = container
    }

    public var body: some View {
        Group {
            if let coordinator = coordinator {
                NavigationStack(path: .init(
                    get: { coordinator.path },
                    set: { coordinator.path = $0 }
                )) {
                    coordinator.build(screen: .home)
                        .navigationDestination(for: Screen.self) { screen in
                            coordinator.build(screen: screen)
                        }
                }
                .sheet(item: .init(
                    get: { coordinator.presentedSheet },
                    set: { coordinator.presentedSheet = $0 }
                )) { sheetType in
                    coordinator.buildSheet(for: sheetType)
                }
                .onOpenURL { url in
                    Task {
                        await coordinator.handleURL(url)
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .task {
            if coordinator == nil {
                await setupCoordinator()
            }
        }
    }
    
    private func setupCoordinator() async {
        // Create URL coordinator and handlers
        let urlCoordinator = URLCoordinator()
        let newCoordinator = Coordinator(container: container, urlCoordinator: urlCoordinator)
        
        // Register handlers after coordinator is created
        let handlers = SavedItemURLHandlerFactory.createHandlers(
            coordinator: newCoordinator,
            modelContext: modelContext
        )
        urlCoordinator.register(handlers: handlers)
        
        coordinator = newCoordinator
    }
}
