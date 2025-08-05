//
//  SavedItemService.swift
//  Features
//
//  Created by James Swent on 7/30/25.
//

import SwiftData
import Foundation

public final class SavedItemService {
    internal let repository: SavedItemRepositoryProtocol
    internal let searchService: SearchServiceProtocol
    
    public init(
        repository: SavedItemRepositoryProtocol,
        searchService: SearchServiceProtocol
    ) {
        self.repository = repository
        self.searchService = searchService
    }
    
    // MARK: - Convenience Factory
    
    public static func create(with modelContext: ModelContext) -> SavedItemService {
        let repository = SavedItemRepository(modelContext: modelContext)
        let searchService = SearchService(modelContext: modelContext)
        
        return SavedItemService(
            repository: repository,
            searchService: searchService
        )
    }
    
    // MARK: - SavedItem Operations
    
    public func getAllItems() throws -> [SavedItem] {
        return try repository.fetchAll()
    }
    
    public func getItemsByType(_ type: SavedItemType) throws -> [SavedItem] {
        return try repository.fetchByType(type)
    }
    
    public func getRecentItems(limit: Int = 10) throws -> [SavedItem] {
        return try repository.fetchRecent(limit: limit)
    }
    
    public func getItemsWithPhotos() throws -> [SavedItem] {
        return try repository.fetchWithPhotos()
    }
    
    public func getItemsWithUrls() throws -> [SavedItem] {
        return try repository.fetchWithUrls()
    }
    
    public func save() throws {
        try repository.save()
    }
    
    // MARK: - Task Operations (convenience methods)
    
    public func getAllTasks() throws -> [SavedItem] {
        return try repository.fetchByType(SavedItemType.task)
    }
    
    public func getTasks(withStatus status: TaskStatus) throws -> [SavedItem] {
        return try repository.fetchTasks(withStatus: status)
    }
    
    public func getActiveTasks() throws -> [SavedItem] {
        return try repository.fetchActiveTasks()
    }
    
    public func getOverdueTasks() throws -> [SavedItem] {
        return try repository.fetchOverdueTasks()
    }
    
    public func getTasksForProject(_ projectId: UUID) throws -> [SavedItem] {
        return try repository.fetchTasksForProject(projectId)
    }
    
    // MARK: - Project Operations (convenience methods)
    
    public func getAllProjects() throws -> [SavedItem] {
        return try repository.fetchByType(SavedItemType.project)
    }
    
    public func getProjects(withStatus status: ProjectStatus) throws -> [SavedItem] {
        return try repository.fetchProjects(withStatus: status)
    }
    
    public func getActiveProjects() throws -> [SavedItem] {
        return try repository.fetchActiveProjects()
    }
    
    public func getOverdueProjects() throws -> [SavedItem] {
        return try repository.fetchOverdueProjects()
    }
    
    // MARK: - Search Operations
    
    public func searchItems(containing searchText: String) throws -> [SavedItem] {
        return try searchService.searchItems(containing: searchText)
    }
    
    public func searchItemsGroupedByType(containing searchText: String) throws -> [String: [SavedItem]] {
        return try searchService.searchItemsGroupedByType(containing: searchText)
    }
}
