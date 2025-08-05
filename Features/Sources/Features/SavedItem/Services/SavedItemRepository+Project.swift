//
//  SavedItemRepository+Project.swift
//  Features
//
//  Created by James Swent on 8/4/25.
//

import SwiftData
import Foundation

// MARK: - Project Repository Methods

extension SavedItemRepository {
    
    public func fetchProjects(withStatus status: ProjectStatus) throws -> [SavedItem] {
        // Use raw values to avoid SwiftData enum issues
        let projectTypeRaw = SavedItemType.project.rawValue
        let statusRaw = status.rawValue
        
        let predicate = #Predicate<SavedItem> { item in
            item.type.rawValue == projectTypeRaw && 
            item.projectData?.status.rawValue == statusRaw
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
    
    public func fetchActiveProjects() throws -> [SavedItem] {
        let projectTypeRaw = SavedItemType.project.rawValue
        let notStartedRaw = ProjectStatus.notStarted.rawValue
        let inProgressRaw = ProjectStatus.inProgress.rawValue
        
        let predicate = #Predicate<SavedItem> { item in
            item.type.rawValue == projectTypeRaw &&
            (item.projectData?.status.rawValue == notStartedRaw ||
             item.projectData?.status.rawValue == inProgressRaw)
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
    
    public func fetchOverdueProjects() throws -> [SavedItem] {
        let now = Date()
        let projectTypeRaw = SavedItemType.project.rawValue
        let notStartedRaw = ProjectStatus.notStarted.rawValue
        let inProgressRaw = ProjectStatus.inProgress.rawValue
        
        let predicate = #Predicate<SavedItem> { item in
            item.type.rawValue == projectTypeRaw &&
            item.projectData?.targetCompletionDate != nil &&
            item.projectData!.targetCompletionDate! < now &&
            (item.projectData?.status.rawValue == notStartedRaw ||
             item.projectData?.status.rawValue == inProgressRaw)
        }
        
        let descriptor = FetchDescriptor<SavedItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.projectData?.targetCompletionDate, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
}