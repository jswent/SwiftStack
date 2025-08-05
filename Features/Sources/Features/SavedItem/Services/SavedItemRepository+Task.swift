//
//  SavedItemRepository+Task.swift
//  Features
//
//  Created by James Swent on 8/4/25.
//

import SwiftData
import Foundation

// MARK: - Task Repository Methods

extension SavedItemRepository {
    
    public func fetchTasks(withStatus status: TaskStatus) throws -> [SavedItem] {
        // Use raw values to avoid SwiftData enum issues
        let taskTypeRaw = SavedItemType.task.rawValue
        let statusRaw = status.rawValue
        
        let predicate = #Predicate<SavedItem> { item in
            item.type.rawValue == taskTypeRaw && 
            item.taskData?.status.rawValue == statusRaw
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
    
    public func fetchActiveTasks() throws -> [SavedItem] {
        let taskTypeRaw = SavedItemType.task.rawValue
        let doneStatusRaw = TaskStatus.done.rawValue
        let canceledStatusRaw = TaskStatus.canceled.rawValue
        
        let predicate = #Predicate<SavedItem> { item in
            item.type.rawValue == taskTypeRaw &&
            item.taskData?.status.rawValue != doneStatusRaw &&
            item.taskData?.status.rawValue != canceledStatusRaw
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
    
    public func fetchOverdueTasks() throws -> [SavedItem] {
        let now = Date()
        let taskTypeRaw = SavedItemType.task.rawValue
        let doneStatusRaw = TaskStatus.done.rawValue
        let canceledStatusRaw = TaskStatus.canceled.rawValue
        
        let predicate = #Predicate<SavedItem> { item in
            item.type.rawValue == taskTypeRaw &&
            item.taskData?.dueDate != nil &&
            item.taskData!.dueDate! < now &&
            item.taskData?.status.rawValue != doneStatusRaw &&
            item.taskData?.status.rawValue != canceledStatusRaw
        }
        
        let descriptor = FetchDescriptor<SavedItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.taskData?.dueDate, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
    
    public func fetchTasksForProject(_ projectId: UUID) throws -> [SavedItem] {
        let taskTypeRaw = SavedItemType.task.rawValue
        
        let predicate = #Predicate<SavedItem> { item in
            item.type.rawValue == taskTypeRaw && 
            item.taskData?.projectId == projectId
        }
        
        let descriptor = FetchDescriptor<SavedItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
}