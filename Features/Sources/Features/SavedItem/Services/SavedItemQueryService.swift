//
//  SavedItemQueryService.swift
//  Features
//
//  Created by James Swent on 7/30/25.
//

import SwiftData
import Foundation

// MARK: - Comprehensive Query Service
class SavedItemQueryService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 1. Polymorphic Queries (All Items at Once)
    
    /// Get ALL items regardless of type - this is the magic of inheritance!
    func getAllItems() -> [SavedItem] {
        let descriptor = FetchDescriptor<SavedItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Get all items with type information preserved
    func getAllItemsWithTypes() -> (items: [SavedItem], tasks: [TaskItem]) {
        let allItems = getAllItems()
        let tasks = allItems.compactMap { $0 as? TaskItem }
        return (allItems, tasks)
    }
    
    /// Get all items grouped by type
    func getAllItemsGroupedByType() -> [String: [SavedItem]] {
        let allItems = getAllItems()
        return Dictionary(grouping: allItems) { item in
            switch item {
            case is TaskItem: return "Tasks"
            default: return "Items"
            }
        }
    }
    
    // MARK: - 2. Type-Specific Queries
    
    /// Get only base SavedItems (not tasks or projects)
    func getBaseSavedItemsOnly() -> [SavedItem] {
        let allItems = getAllItems()
        return allItems.filter { item in
            type(of: item) == SavedItem.self // Exact type match
        }
    }
    
    /// Get only tasks
    func getAllTasks() -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [
                SortDescriptor<TaskItem>(\.status.sortOrder),
                SortDescriptor<TaskItem>(\.priority.sortOrder, order: .reverse),
                SortDescriptor<TaskItem>(\.dueDate)
            ]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    
    // MARK: - 3. Advanced Filtering Across Types
    
    /// Search across all items by title
    func searchAllItems(containing searchText: String) -> [SavedItem] {
        let predicate = #Predicate<SavedItem> { item in
            item.title.localizedStandardContains(searchText) ||
            (item.notes?.localizedStandardContains(searchText) ?? false)
        }
        
        let descriptor = FetchDescriptor<SavedItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastEdited, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Get recent items across all types
    func getRecentItems(limit: Int = 10) -> [SavedItem] {
        var descriptor = FetchDescriptor<SavedItem>(
            sortBy: [SortDescriptor(\.lastEdited, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Get items created in date range (all types)
    func getItemsCreated(from startDate: Date, to endDate: Date) -> [SavedItem] {
        let predicate = #Predicate<SavedItem> { item in
            item.createdAt >= startDate && item.createdAt <= endDate
        }
        
        let descriptor = FetchDescriptor<SavedItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - 4. Complex Relationship Queries
    
    /// Get all items that have photos
    func getItemsWithPhotos() -> [SavedItem] {
        let predicate = #Predicate<SavedItem> { item in
            !item.photos.isEmpty
        }
        
        let descriptor = FetchDescriptor<SavedItem>(predicate: predicate)
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// Get all items with URLs
    func getItemsWithUrls() -> [SavedItem] {
        let predicate = #Predicate<SavedItem> { item in
            item.url != nil
        }
        
        let descriptor = FetchDescriptor<SavedItem>(predicate: predicate)
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - 5. Task-Specific Queries That Work on Base Class
    
    /// Get overdue items (works because we check if it's a task)
    func getOverdueItems() -> [SavedItem] {
        let allItems = getAllItems()
        return allItems.filter { item in
            if let task = item as? TaskItem {
                return task.isOverdue
            }
            return false
        }
    }
    
    /// Get active work items (tasks in progress + active projects)
    func getActiveWorkItems() -> [SavedItem] {
        let allItems = getAllItems()
        return allItems.filter { item in
            switch item {
            case let task as TaskItem:
                return task.isActive
            default:
                return false
            }
        }
    }
}

