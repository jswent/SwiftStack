//
//  Coordinator.swift
//  SwiftUISampleApp
//
//  Created by James Swent on 7/23/25.
//

import About
import Core
import Foundation
import Home
import OSLog
import SavedItem
import SwiftUI
import SwiftData

@Observable @MainActor
final class Coordinator {
    var path = NavigationPath()
    private var currentScreen: Screen = .home
    var showingAddItemSheet = false
    var addItemParameters: URLRoute.AddItemParameters?
    var showingEditItemSheet = false
    var editItemParameters: SavedItem?

    private let container: Container
    private let urlCoordinator: URLCoordinator

    init(container: Container, urlCoordinator: URLCoordinator) {
        self.container = container
        self.urlCoordinator = urlCoordinator

        Logger.appFlow.debug("Starting the coordinator")

        // Check if this is first launch or restore last screen
        if let lastScreenId = container.navigationPersistence.get() {
            Logger.appFlow.info("Restoring last screen: \(lastScreenId)")
            restoreLastScreen(screenId: lastScreenId)
        } else {
            Logger.appFlow.info("First launch, showing home")
        }
    }

    private func push(screen: Screen) {
        path.append(screen)
        currentScreen = screen
        // Persist the current screen
        container.navigationPersistence.set(screen.id)
    }

    private func pop() {
        path.removeLast()
        // For simplicity, after popping we assume we're back to the previous screen
        // In a more complex implementation, you'd track a screen stack
        currentScreen = path.isEmpty ? .home : currentScreen
        container.navigationPersistence.set(currentScreen.id)
    }

    private func restoreLastScreen(screenId: String) {
        switch screenId {
        case "savedItems":
            showSavedItems()
        case "about":
            showAbout()
        case "libraries":
            showAbout()
            showLibraries()
        default:
            // Check if it's a specific saved item UUID
            if UUID(uuidString: screenId) != nil {
                // It's a saved item UUID, navigate to saved items list
                // The specific item will be handled by deep linking if needed
                showSavedItems()
            } else {
                Logger.appFlow.info("Unknown screen ID: \(screenId), defaulting to home")
            }
        }
    }
    
    // MARK: - Deep Linking Support
    
    /// Navigate directly to a specific SavedItem by UUID
    func navigateToSavedItem(uuid: UUID) {
        Logger.appFlow.info("Deep linking to saved item: \(uuid)")
        // Navigate to saved items list first
        showSavedItems()
        // The list view will handle selecting the specific item by UUID
        // This is a simplified approach - in a full implementation,
        // you might want to store the target UUID and highlight it
    }
    
    /// Navigate directly to a specific SavedItem instance
    func navigateToSavedItem(item: SavedItem) {
        Logger.appFlow.info("Navigating to saved item: \(item.title)")
        
        // First ensure we're on the saved items screen
        if currentScreen != .savedItems {
            showSavedItems()
        }
        
        // Then navigate to the specific item
        showSavedItem(item: item)
    }
    
    /// Show add item sheet with pre-filled parameters
    func showAddSavedItem(with parameters: URLRoute.AddItemParameters) {
//        Logger.appFlow.info("Showing add item with parameters: \(parameters)")
        
        // First ensure we're on the saved items screen
        if currentScreen != .savedItems {
            showSavedItems()
        }
        
        // Store the parameters for the add item sheet
        addItemParameters = parameters
        showingAddItemSheet = true
    }
    
    // MARK: - URL Handling
    
    /// Handle incoming URLs
    func handleURL(_ url: URL) async {
        Logger.appFlow.info("Handling URL: \(url.absoluteString)")
        let result = await urlCoordinator.handle(url)
        
        switch result {
        case .handled:
            Logger.appFlow.info("URL handled successfully")
        case .notHandled:
            Logger.appFlow.warning("URL not handled")
        case .error(let error):
            Logger.appFlow.error("URL handling failed: \(error.localizedDescription)")
        }
    }

    private func showSavedItems() {
        Logger.appFlow.debug("Showing saved items")
        push(screen: .savedItems)
    }

    private func showSavedItem(item: SavedItem) {
        Logger.appFlow.debug("Showing saved item detail [title: \(item.title)]")
        push(screen: .savedItem(item))
    }

    private func showAddSavedItem() {
        Logger.appFlow.debug("Showing add saved item sheet")
        showingAddItemSheet = true
    }

    private func showEditSavedItem(item: SavedItem) {
        Logger.appFlow.debug("Showing edit saved item sheet [title: \(item.title)]")
        editItemParameters = item
        showingEditItemSheet = true
    }

    private func showAbout() {
        Logger.appFlow.debug("Showing about")
        push(screen: .about)
    }

    private func showLibraries() {
        Logger.appFlow.debug("Showing used libraries")
        push(screen: .libraries)
    }

    @ViewBuilder
    func build(screen: Screen) -> some View {
        switch screen {
        case .home:
            HomeView { [unowned self] target in
                switch target {
                case .items:
                    showSavedItems()
                case .about:
                    showAbout()
                }
            }
        case .savedItems:
            SavedItemListView { [unowned self] target in
                switch target {
                case let .item(item):
                    showSavedItem(item: item)
                case .addItem:
                    showAddSavedItem()
                case let .editItem(item):
                    showEditSavedItem(item: item)
                }
            }
        case let .savedItem(item):
            SavedItemDetailView(item: item) { [unowned self] target in
                switch target {
                case let .editItem(item):
                    showEditSavedItem(item: item)
                }
            }
        case .about:
            AboutView { [unowned self] target in
                switch target {
                case .libraries:
                    showLibraries()
                }
            }
        case .libraries:
            LibrariesView()
        }
    }
}
