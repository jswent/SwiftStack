//
//  TaskRepository.swift
//  Features
//
//  Created by James Swent on 8/1/25.
//

import SwiftData
import Foundation

public protocol TaskRepositoryProtocol {
    func fetchAll() throws -> [TaskItem]
    func fetch(withStatus status: TaskStatus) throws -> [TaskItem]
    func fetchOverdue() throws -> [TaskItem]
    func fetchActive() throws -> [TaskItem]
    func fetchCompleted() throws -> [TaskItem]
    func fetchByPriority(_ priority: TaskPriority) throws -> [TaskItem]
    func save() throws
}

public final class TaskRepository: TaskRepositoryProtocol {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    public func fetchAll() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [
                SortDescriptor(\.status.sortOrder),
                SortDescriptor(\.priority?.sortOrder, order: .reverse),
                SortDescriptor(\.dueDate)
            ]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetch(withStatus status: TaskStatus) throws -> [TaskItem] {
        let predicate = #Predicate<TaskItem> { task in
            task.status == status
        }
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.priority?.sortOrder, order: .reverse),
                SortDescriptor(\.dueDate)
            ]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchOverdue() throws -> [TaskItem] {
        let now = Date()
        let predicate = #Predicate<TaskItem> { task in
            task.dueDate != nil && 
            task.dueDate! < now && 
            (task.status == TaskStatus.backlog || task.status == TaskStatus.todo || task.status == TaskStatus.inProgress || task.status == TaskStatus.inReview)
        }
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.dueDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchActive() throws -> [TaskItem] {
        let predicate = #Predicate<TaskItem> { task in
            task.status == TaskStatus.backlog || task.status == TaskStatus.todo || task.status == TaskStatus.inProgress || task.status == TaskStatus.inReview
        }
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.status.sortOrder),
                SortDescriptor(\.priority?.sortOrder, order: .reverse),
                SortDescriptor(\.dueDate)
            ]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchCompleted() throws -> [TaskItem] {
        let predicate = #Predicate<TaskItem> { task in
            task.status == TaskStatus.done
        }
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastEdited, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchByPriority(_ priority: TaskPriority) throws -> [TaskItem] {
        let predicate = #Predicate<TaskItem> { task in
            task.priority == priority
        }
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.status.sortOrder),
                SortDescriptor(\.dueDate)
            ]
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