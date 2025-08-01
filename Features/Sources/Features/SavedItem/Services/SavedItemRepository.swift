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
    func fetchBaseSavedItemsOnly() throws -> [SavedItem]
    func fetchRecent(limit: Int) throws -> [SavedItem]
    func fetchCreated(from startDate: Date, to endDate: Date) throws -> [SavedItem]
    func fetchWithPhotos() throws -> [SavedItem]
    func fetchWithUrls() throws -> [SavedItem]
    func save() throws
}

public final class SavedItemRepository: SavedItemRepositoryProtocol {
    private let modelContext: ModelContext
    
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
    
    public func fetchBaseSavedItemsOnly() throws -> [SavedItem] {
        let allItems = try fetchAll()
        return allItems.filter { type(of: $0) == SavedItem.self }
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