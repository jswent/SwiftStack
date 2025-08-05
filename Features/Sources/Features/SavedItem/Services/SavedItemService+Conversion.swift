//
//  SavedItemService+Conversion.swift
//  Features
//
//  Created by James Swent on 8/4/25.
//

import Foundation

// MARK: - Type Conversion Operations

extension SavedItemService {
    
    /// Convert an item to a task
    public func convertToTask(
        _ item: SavedItem,
        status: TaskStatus = .todo,
        priority: TaskPriority? = nil,
        dueDate: Date? = nil,
        estimatedDuration: TimeInterval? = nil,
        projectId: UUID? = nil
    ) throws {
        // Don't convert if already a task
        guard !item.isTask else { return }
        
        // Set type and initialize task data
        item.type = SavedItemType.task
        item.taskData = TaskData(
            status: status,
            priority: priority,
            dueDate: dueDate,
            estimatedDuration: estimatedDuration,
            projectId: projectId
        )
        item.projectData = nil
        item.markAsEdited()
        
        try repository.save()
    }
    
    /// Convert an item to a project
    public func convertToProject(
        _ item: SavedItem,
        status: ProjectStatus = .notStarted,
        startDate: Date? = nil,
        targetCompletionDate: Date? = nil,
        progress: Double = 0.0
    ) throws {
        // Don't convert if already a project
        guard !item.isProject else { return }
        
        // Set type and initialize project data
        item.type = SavedItemType.project
        item.projectData = ProjectData(
            status: status,
            startDate: startDate,
            targetCompletionDate: targetCompletionDate,
            progress: progress
        )
        item.taskData = nil
        item.markAsEdited()
        
        try repository.save()
    }
    
    /// Convert an item back to a basic item
    public func convertToItem(_ item: SavedItem) throws {
        // Don't convert if already a basic item
        guard !item.isItem else { return }
        
        // Clear type-specific data and set to basic item
        item.type = SavedItemType.item
        item.taskData = nil
        item.projectData = nil
        item.markAsEdited()
        
        try repository.save()
    }
    
    /// Convert multiple items to tasks
    public func convertMultipleToTasks(
        _ items: [SavedItem],
        defaultStatus: TaskStatus = .todo,
        defaultPriority: TaskPriority? = nil
    ) throws {
        for item in items {
            try convertToTask(
                item,
                status: defaultStatus,
                priority: defaultPriority
            )
        }
    }
    
    /// Convert multiple items to projects
    public func convertMultipleToProjects(
        _ items: [SavedItem],
        defaultStatus: ProjectStatus = .notStarted
    ) throws {
        for item in items {
            try convertToProject(item, status: defaultStatus)
        }
    }
    
    /// Convert a task to a project while preserving relevant data
    public func convertTaskToProject(
        _ item: SavedItem,
        preserveTaskData: Bool = true,
        projectStatus: ProjectStatus = .notStarted
    ) throws {
        guard item.isTask else {
            throw SavedItemServiceError.invalidItemType("Item must be a task to convert to project")
        }
        
        // Extract task data before conversion if preserving
        var startDate: Date?
        var targetDate: Date?
        
        if preserveTaskData {
            targetDate = item.taskData?.dueDate
            startDate = Date() // Use current date as start date
        }
        
        // Convert to project
        try convertToProject(
            item,
            status: projectStatus,
            startDate: startDate,
            targetCompletionDate: targetDate
        )
    }
}