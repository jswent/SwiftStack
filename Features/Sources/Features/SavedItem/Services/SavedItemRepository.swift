//
//  SavedItemRepository.swift
//  Features
//
//  Created by James Swent on 8/1/25.
//

import SwiftData
import Foundation

public enum RepositoryError: Error {
    case fetchFailed(Error)
    case saveFailed(Error)
    case invalidInput
}

public protocol SavedItemRepositoryProtocol {
    func fetchAll() throws -> [SavedItem]
    func fetchByType(_ type: SavedItemType) throws -> [SavedItem]
    func fetchRecent(limit: Int) throws -> [SavedItem]
    func fetchCreated(from startDate: Date, to endDate: Date) throws -> [SavedItem]
    func fetchWithPhotos() throws -> [SavedItem]
    func fetchWithUrls() throws -> [SavedItem]
    
    // Task-specific queries
    func fetchTasks(withStatus status: TaskStatus) throws -> [SavedItem]
    func fetchActiveTasks() throws -> [SavedItem]
    func fetchOverdueTasks() throws -> [SavedItem]
    func fetchTasksForProject(_ projectId: UUID) throws -> [SavedItem]
    
    // Project-specific queries
    func fetchProjects(withStatus status: ProjectStatus) throws -> [SavedItem]
    func fetchActiveProjects() throws -> [SavedItem]
    func fetchOverdueProjects() throws -> [SavedItem]
    
    func save() throws
}


public final class SavedItemRepository: SavedItemRepositoryProtocol {
    internal let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    public func fetchAll() throws -> [SavedItem] {
        let descriptor = FetchDescriptor<SavedItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchByType(_ type: SavedItemType) throws -> [SavedItem] {
        // Use raw value to avoid SwiftData enum comparison issues
        let typeRawValue = type.rawValue
        let predicate = #Predicate<SavedItem> { item in
            item.type.rawValue == typeRawValue
        }
        
        let descriptor = FetchDescriptor<SavedItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchRecent(limit: Int = 10) throws -> [SavedItem] {
        guard limit > 0 else {
            throw RepositoryError.invalidInput
        }
        
        var descriptor = FetchDescriptor<SavedItem>(
            sortBy: [SortDescriptor(\.lastEdited, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchCreated(from startDate: Date, to endDate: Date) throws -> [SavedItem] {
        guard startDate <= endDate else {
            throw RepositoryError.invalidInput
        }
        
        let predicate = #Predicate<SavedItem> { item in
            item.createdAt >= startDate && item.createdAt <= endDate
        }
        
        let descriptor = FetchDescriptor<SavedItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchWithPhotos() throws -> [SavedItem] {
        let predicate = #Predicate<SavedItem> { item in
            !item.photos.isEmpty
        }
        
        let descriptor = FetchDescriptor<SavedItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastEdited, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchWithUrls() throws -> [SavedItem] {
        let predicate = #Predicate<SavedItem> { item in
            item.url != nil
        }
        
        let descriptor = FetchDescriptor<SavedItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastEdited, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func save() throws {
        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }
}