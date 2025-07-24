//
//  SavedItemURLHandlers.swift
//  App
//
//  Created by James Swent on 7/22/25.
//

import Core
import Foundation
import OSLog
import SavedItem
import SwiftData

// MARK: - Open Item Handler

/// Handles URLs for opening specific saved items
final class OpenItemHandler: URLRouteHandling {
    private weak var coordinator: Coordinator?
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "URLRouting", category: "OpenItemHandler")
    
    init(coordinator: Coordinator, modelContext: ModelContext) {
        self.coordinator = coordinator
        self.modelContext = modelContext
    }
    
    public func canHandle(_ route: URLRoute) -> Bool {
        if case .openItem = route {
            return true
        }
        return false
    }
    
    public func handle(_ route: URLRoute) async -> Bool {
        guard case .openItem(let uuid) = route else {
            return false
        }
        
        logger.info("Handling open item request for UUID: \(uuid)")
        
        // Query for the item
        let predicate = #Predicate<SavedItem> { item in
            item.id == uuid
        }
        
        let descriptor = FetchDescriptor<SavedItem>(predicate: predicate)
        
        do {
            let items = try modelContext.fetch(descriptor)
            guard let item = items.first else {
                logger.error("No item found with UUID: \(uuid)")
                return false
            }
            
            // Navigate to the item via the coordinator using UUID to avoid data races
            await coordinator?.navigateToSavedItem(uuid: uuid)
            
            logger.info("Successfully navigated to item with UUID: \(uuid)")
            return true
            
        } catch {
            logger.error("Failed to fetch item: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Add Item Handler

/// Handles URLs for adding new items with pre-filled parameters
final class AddItemHandler: URLRouteHandling {
    private weak var coordinator: Coordinator?
    private let logger = Logger(subsystem: "URLRouting", category: "AddItemHandler")
    
    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
    
    public func canHandle(_ route: URLRoute) -> Bool {
        if case .addItem = route {
            return true
        }
        return false
    }
    
    public func handle(_ route: URLRoute) async -> Bool {
        guard case .addItem(let parameters) = route else {
            return false
        }
        
//        logger.info("Handling add item request with parameters: \(parameters)")
        
        // Navigate to the add item screen with pre-filled data
        await coordinator?.showAddSavedItem(with: parameters)
        
        logger.info("Successfully navigated to add item screen")
        return true
    }
}

// MARK: - Factory for Creating Handlers

struct SavedItemURLHandlerFactory {
    /// Create all SavedItem-related URL handlers
    static func createHandlers(
        coordinator: Coordinator,
        modelContext: ModelContext
    ) -> [URLRouteHandling] {
        return [
            OpenItemHandler(coordinator: coordinator, modelContext: modelContext),
            AddItemHandler(coordinator: coordinator)
        ]
    }
}
