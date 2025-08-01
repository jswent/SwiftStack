//
//  ConversionService.swift
//  Features
//
//  Created by James Swent on 8/1/25.
//

import SwiftData
import Foundation

// MARK: - Conversion Errors

public enum ConversionError: LocalizedError {
    case invalidSourceType
    case dataTransferFailed
    case saveOperationFailed(Error)
    case relationshipPreservationFailed
    case validationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidSourceType:
            return "Cannot convert this item type"
        case .dataTransferFailed:
            return "Failed to transfer item data during conversion"
        case .saveOperationFailed(let error):
            return "Save operation failed: \(error.localizedDescription)"
        case .relationshipPreservationFailed:
            return "Failed to preserve item relationships"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

// MARK: - Conversion Result Types

public enum ConversionResult<T> {
    case success(T)
    case failure(ConversionError)
}

// MARK: - Conversion Service Protocol

public protocol ConversionServiceProtocol {
    func convertToTask(_ item: SavedItem, status: TaskStatus, priority: TaskPriority?, dueDate: Date?, estimatedDuration: TimeInterval?) -> ConversionResult<TaskItem>
    func convertToProject(_ item: SavedItem, status: ProjectStatus, startDate: Date?, targetCompletionDate: Date?) -> ConversionResult<ProjectItem>
    func convertTaskToProject(_ task: TaskItem, preserveData: Bool) -> ConversionResult<ProjectItem>
    func convertMultipleToTasks(_ items: [SavedItem], defaultPriority: TaskPriority?, defaultStatus: TaskStatus) -> [ConversionResult<TaskItem>]
    func convertMultipleToProjects(_ items: [SavedItem], defaultStatus: ProjectStatus) -> [ConversionResult<ProjectItem>]
}

// MARK: - Atomic Conversion Service

public final class ConversionService: ConversionServiceProtocol {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - SavedItem to TaskItem Conversion
    
    public func convertToTask(
        _ item: SavedItem,
        status: TaskStatus = .backlog,
        priority: TaskPriority? = nil,
        dueDate: Date? = nil,
        estimatedDuration: TimeInterval? = nil
    ) -> ConversionResult<TaskItem> {
        
        // Validation
        guard type(of: item) == SavedItem.self else {
            return .failure(.invalidSourceType)
        }
        
        do {
            // 1. Create new TaskItem with copied data
            let taskItem = TaskItem(
                title: item.title,
                notes: item.notes,
                url: item.url,
                status: status,
                priority: priority,
                dueDate: dueDate,
                estimatedDuration: estimatedDuration
            )
            
            // 2. Preserve metadata
            taskItem.createdAt = item.createdAt
            taskItem.lastEdited = Date()
            
            // 3. Transfer relationships atomically
            try transferRelationships(from: item, to: taskItem)
            
            // 4. Insert new item
            modelContext.insert(taskItem)
            
            // 5. Delete old item (after successful creation)
            modelContext.delete(item)
            
            // 6. Commit transaction
            try modelContext.save()
            
            return .success(taskItem)
            
        } catch {
            return .failure(.saveOperationFailed(error))
        }
    }
    
    // MARK: - SavedItem to ProjectItem Conversion
    
    public func convertToProject(
        _ item: SavedItem,
        status: ProjectStatus = .notStarted,
        startDate: Date? = nil,
        targetCompletionDate: Date? = nil
    ) -> ConversionResult<ProjectItem> {
        
        // Validation
        guard type(of: item) == SavedItem.self else {
            return .failure(.invalidSourceType)
        }
        
        do {
            // 1. Create new ProjectItem
            let projectItem = ProjectItem(
                title: item.title,
                notes: item.notes,
                url: item.url,
                status: status,
                startDate: startDate,
                targetCompletionDate: targetCompletionDate
            )
            
            // 2. Preserve metadata
            projectItem.createdAt = item.createdAt
            projectItem.lastEdited = Date()
            
            // 3. Transfer relationships
            try transferRelationships(from: item, to: projectItem)
            
            // 4. Insert and delete atomically
            modelContext.insert(projectItem)
            modelContext.delete(item)
            
            // 5. Commit
            try modelContext.save()
            
            return .success(projectItem)
            
        } catch {
            return .failure(.saveOperationFailed(error))
        }
    }
    
    // MARK: - TaskItem to ProjectItem Conversion
    
    public func convertTaskToProject(
        _ task: TaskItem,
        preserveData: Bool = true
    ) -> ConversionResult<ProjectItem> {
        
        do {
            // Determine project status from task status
            let projectStatus: ProjectStatus = preserveData ? mapTaskStatusToProjectStatus(task.status) : .notStarted
            let targetDate = preserveData ? task.dueDate : nil
            
            let projectItem = ProjectItem(
                title: task.title,
                notes: task.notes,
                url: task.url,
                status: projectStatus,
                targetCompletionDate: targetDate
            )
            
            // Preserve metadata
            projectItem.createdAt = task.createdAt
            projectItem.lastEdited = Date()
            
            // Handle project-task relationships (if task was part of another project)
            if let parentProject = task.project {
                // Remove task from parent project's task list
                parentProject.removeTask(task)
            }
            
            // Transfer other relationships
            try transferRelationships(from: task, to: projectItem)
            
            modelContext.insert(projectItem)
            modelContext.delete(task)
            try modelContext.save()
            
            return .success(projectItem)
            
        } catch {
            return .failure(.saveOperationFailed(error))
        }
    }
    
    // MARK: - Specialized Item to Base SavedItem Conversion
    
    // TODO: implement this later if necessary
    
    // MARK: - Batch Conversion Operations
    
    public func convertMultipleToTasks(
        _ items: [SavedItem],
        defaultPriority: TaskPriority? = nil,
        defaultStatus: TaskStatus = .backlog
    ) -> [ConversionResult<TaskItem>] {
        
        var results: [ConversionResult<TaskItem>] = []
        
        // Process each item in a separate transaction for safety
        for item in items {
            let result = convertToTask(item, status: defaultStatus, priority: defaultPriority)
            results.append(result)
        }
        
        return results
    }
    
    public func convertMultipleToProjects(
        _ items: [SavedItem],
        defaultStatus: ProjectStatus = .notStarted
    ) -> [ConversionResult<ProjectItem>] {
        
        var results: [ConversionResult<ProjectItem>] = []
        
        for item in items {
            let result = convertToProject(item, status: defaultStatus)
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Private Helper Methods
    
    private func transferRelationships(from source: SavedItem, to destination: SavedItem) throws {
        // Transfer photos relationship
        destination.photos = source.photos
        
        // Note: Other relationships would be handled here
        // This is where you'd handle any additional @Relationship properties
    }
    
    private func mapTaskStatusToProjectStatus(_ taskStatus: TaskStatus) -> ProjectStatus {
        switch taskStatus {
        case .backlog, .todo:
            return .notStarted
        case .inProgress:
            return .inProgress
        case .inReview:
            return .inProgress // Review is still "in progress" for a project
        case .done:
            return .completed
        case .canceled:
            return .cancelled
        }
    }
}

// MARK: - Validation Service

public final class ConversionValidationService {
    
    public static func canConvert(_ item: SavedItem, to targetType: SavedItem.Type) -> (Bool, String?) {
        let sourceType = type(of: item)
        
        // Base SavedItem can convert to anything
        if sourceType == SavedItem.self {
            return (true, nil)
        }
        
        // TaskItem conversions
        if sourceType == TaskItem.self {
            if targetType == ProjectItem.self {
                return (true, nil)
            } else if targetType == SavedItem.self {
                let task = item as! TaskItem
                if task.project != nil {
                    return (false, "Task is part of a project. Remove from project first.")
                }
                return (true, nil)
            }
        }
        
        // ProjectItem conversions
        if sourceType == ProjectItem.self {
            if targetType == TaskItem.self {
                let project = item as! ProjectItem
                if !project.tasks.isEmpty {
                    return (false, "Project has \(project.tasks.count) tasks. Handle tasks first.")
                }
                return (true, nil)
            } else if targetType == SavedItem.self {
                let project = item as! ProjectItem
                if !project.tasks.isEmpty {
                    return (false, "Project has tasks that would be lost. Remove tasks first.")
                }
                return (true, nil)
            }
        }
        
        return (false, "Invalid conversion path")
    }
    
    public static func getConversionWarnings(for item: SavedItem, to targetType: SavedItem.Type) -> [String] {
        var warnings: [String] = []
        
        if let task = item as? TaskItem {
            if targetType == ProjectItem.self {
                warnings.append("Task priority information will be lost")
                if task.estimatedDuration != nil {
                    warnings.append("Estimated duration will be lost")
                }
            }
        }
        
        if let project = item as? ProjectItem {
            if targetType == TaskItem.self {
                warnings.append("Project progress information will be lost")
                if project.startDate != nil {
                    warnings.append("Start date will be lost")
                }
            }
        }
        
        return warnings
    }
}
