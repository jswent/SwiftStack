//
//  ProjectRepository.swift
//  Features
//
//  Created by James Swent on 8/1/25.
//

import SwiftData
import Foundation

public protocol ProjectRepositoryProtocol {
    func fetchAll() throws -> [ProjectItem]
    func fetchActive() throws -> [ProjectItem]
    func fetchCompleted() throws -> [ProjectItem]
    func fetch(withStatus status: ProjectStatus) throws -> [ProjectItem]
    func fetchOverdue() throws -> [ProjectItem]
    func save() throws
}

public final class ProjectRepository: ProjectRepositoryProtocol {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    public func fetchAll() throws -> [ProjectItem] {
        let descriptor = FetchDescriptor<ProjectItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchActive() throws -> [ProjectItem] {
        let predicate = #Predicate<ProjectItem> { project in
            project.status == ProjectStatus.inProgress || project.status == ProjectStatus.notStarted
        }
        
        let descriptor = FetchDescriptor<ProjectItem>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.status.rawValue),
                SortDescriptor(\.targetCompletionDate)
            ]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchCompleted() throws -> [ProjectItem] {
        let predicate = #Predicate<ProjectItem> { project in
            project.status == ProjectStatus.completed
        }
        
        let descriptor = FetchDescriptor<ProjectItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastEdited, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetch(withStatus status: ProjectStatus) throws -> [ProjectItem] {
        let predicate = #Predicate<ProjectItem> { project in
            project.status == status
        }
        
        let descriptor = FetchDescriptor<ProjectItem>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.targetCompletionDate),
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchOverdue() throws -> [ProjectItem] {
        let now = Date()
        let predicate = #Predicate<ProjectItem> { project in
            project.targetCompletionDate != nil && 
            project.targetCompletionDate! < now && 
            (project.status == ProjectStatus.inProgress || project.status == ProjectStatus.notStarted)
        }
        
        let descriptor = FetchDescriptor<ProjectItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.targetCompletionDate)]
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