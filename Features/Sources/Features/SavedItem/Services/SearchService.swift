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
    func searchTasks(containing searchText: String) throws -> [TaskItem]
    func searchProjects(containing searchText: String) throws -> [ProjectItem]
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
    
    public func searchTasks(containing searchText: String) throws -> [TaskItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RepositoryError.invalidInput
        }
        
        let predicate = #Predicate<TaskItem> { task in
            task.title.localizedStandardContains(searchText) ||
            (task.notes?.localizedStandardContains(searchText) ?? false)
        }
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.status.sortOrder),
                SortDescriptor(\.priority?.sortOrder, order: .reverse),
                SortDescriptor(\.lastEdited, order: .reverse)
            ]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func searchProjects(containing searchText: String) throws -> [ProjectItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RepositoryError.invalidInput
        }
        
        let predicate = #Predicate<ProjectItem> { project in
            project.title.localizedStandardContains(searchText) ||
            (project.notes?.localizedStandardContains(searchText) ?? false)
        }
        
        let descriptor = FetchDescriptor<ProjectItem>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.status.rawValue),
                SortDescriptor(\.lastEdited, order: .reverse)
            ]
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
            switch item {
            case is TaskItem: return "Tasks"
            case is ProjectItem: return "Projects"
            default: return "Items"
            }
        }
    }
}