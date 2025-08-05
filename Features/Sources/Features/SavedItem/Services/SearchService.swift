//
//  SearchService.swift
//  Features
//
//  Created by James Swent on 8/1/25.
//

import SwiftData
import Foundation

public protocol SearchServiceProtocol {
    func searchItems(containing searchText: String) throws -> [SavedItem]
    func searchTasks(containing searchText: String) throws -> [SavedItem]
    func searchProjects(containing searchText: String) throws -> [SavedItem]
    func searchItemsByType(_ type: SavedItemType, containing searchText: String) throws -> [SavedItem]
    func searchItemsGroupedByType(containing searchText: String) throws -> [String: [SavedItem]]
}

public final class SearchService: SearchServiceProtocol {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    public func searchItems(containing searchText: String) throws -> [SavedItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RepositoryError.invalidInput
        }
        
        let predicate = #Predicate<SavedItem> { item in
            item.title.localizedStandardContains(searchText) ||
            (item.notes?.localizedStandardContains(searchText) ?? false)
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
    
    public func searchTasks(containing searchText: String) throws -> [SavedItem] {
        return try searchItemsByType(.task, containing: searchText)
    }
    
    public func searchProjects(containing searchText: String) throws -> [SavedItem] {
        return try searchItemsByType(.project, containing: searchText)
    }
    
    public func searchItemsByType(_ type: SavedItemType, containing searchText: String) throws -> [SavedItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RepositoryError.invalidInput
        }
        
        // Use raw value to avoid SwiftData enum issues
        let typeRawValue = type.rawValue
        let predicate = #Predicate<SavedItem> { item in
            item.type.rawValue == typeRawValue &&
            (item.title.localizedStandardContains(searchText) ||
             (item.notes?.localizedStandardContains(searchText) ?? false))
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
    
    public func searchItemsGroupedByType(containing searchText: String) throws -> [String: [SavedItem]] {
        let items = try searchItems(containing: searchText)
        
        return Dictionary(grouping: items) { item in
            return item.type.pluralDisplayName
        }
    }
}