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
                .sheet(isPresented: .init(
                    get: { coordinator.showingAddItemSheet },
                    set: { newValue in
                        coordinator.showingAddItemSheet = newValue
                        if !newValue {
                            // Clear parameters when sheet is dismissed
                            coordinator.addItemParameters = nil
                        }
                    }
                )) {
                    // NavigationStack {
                        if let parameters = coordinator.addItemParameters {
                            AddSavedItemView(
                                initialTitle: parameters.title ?? "",
                                initialURL: parameters.url ?? "",
                                initialNotes: parameters.notes ?? ""
                            )
                        } else {
                            AddSavedItemView()
                        }
                    // }
                }
                .sheet(isPresented: .init(
                    get: { coordinator.showingEditItemSheet },
                    set: { newValue in
                        coordinator.showingEditItemSheet = newValue
                        if !newValue {
                            coordinator.editItemParameters = nil
                        }
                    }
                )) {
                    if let item = coordinator.editItemParameters {
                        EditSavedItemView(item: item)
                    }
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
