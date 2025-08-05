//
//  SavedItemService+Task.swift
//  Features
//
//  Created by James Swent on 8/4/25.
//

import Foundation

// MARK: - Task Business Logic

extension SavedItemService {
    
    /// Complete a task item and update project progress if applicable
    public func completeTask(_ item: SavedItem) throws {
        guard item.isTask else {
            throw SavedItemServiceError.invalidItemType("Item must be a task")
        }
        
        // Mark task as completed using TaskData mutation
        item.taskData?.markAsCompleted()
        item.markAsEdited()
        
        // Update project progress if task is part of a project
        if let projectId = item.taskData?.projectId {
            try updateProjectProgressForTask(projectId: projectId)
        }
        
        try repository.save()
    }
    
    /// Cancel a task item and update project progress if applicable
    public func cancelTask(_ item: SavedItem) throws {
        guard item.isTask else {
            throw SavedItemServiceError.invalidItemType("Item must be a task")
        }
        
        // Mark task as canceled using TaskData mutation
        item.taskData?.markAsCanceled()
        item.markAsEdited()
        
        // Update project progress if task is part of a project
        if let projectId = item.taskData?.projectId {
            try updateProjectProgressForTask(projectId: projectId)
        }
        
        try repository.save()
    }
    
    /// Assign a task to a project
    public func assignTaskToProject(_ task: SavedItem, project: SavedItem) throws {
        guard task.isTask else {
            throw SavedItemServiceError.invalidItemType("First item must be a task")
        }
        guard project.isProject else {
            throw SavedItemServiceError.invalidItemType("Second item must be a project")
        }
        
        // Update task's project reference
        task.taskData?.assignToProject(project.id)
        task.markAsEdited()
        
        // Add task to project's task list
        project.projectData?.addTask(task.id)
        project.markAsEdited()
        
        // Update project progress
        try updateProjectProgressForTask(projectId: project.id)
        
        try repository.save()
    }
    
    /// Remove a task from its current project
    public func removeTaskFromProject(_ task: SavedItem) throws {
        guard task.isTask else {
            throw SavedItemServiceError.invalidItemType("Item must be a task")
        }
        
        guard let projectId = task.taskData?.projectId else {
            return // Task is not assigned to a project
        }
        
        // Remove task from project
        task.taskData?.removeFromProject()
        task.markAsEdited()
        
        // Find and update the project
        let projects = try repository.fetchByType(SavedItemType.project)
        if let project = projects.first(where: { $0.id == projectId }) {
            project.projectData?.removeTask(task.id)
            project.markAsEdited()
            
            // Update project progress
            try updateProjectProgressForTask(projectId: projectId)
        }
        
        try repository.save()
    }
    
    /// Update task properties
    public func updateTask(
        _ item: SavedItem,
        status: TaskStatus? = nil,
        priority: TaskPriority? = nil,
        dueDate: Date? = nil,
        estimatedDuration: TimeInterval? = nil
    ) throws {
        guard item.isTask else {
            throw SavedItemServiceError.invalidItemType("Item must be a task")
        }
        
        var needsProjectUpdate = false
        let oldProjectId = item.taskData?.projectId
        
        // Update task data
        if let status = status {
            let oldStatus = item.taskData?.status
            item.taskData?.status = status
            // Check if completion status changed
            needsProjectUpdate = oldStatus?.isCompleted != status.isCompleted
        }
        
        if let priority = priority {
            item.taskData?.priority = priority
        }
        
        if let dueDate = dueDate {
            item.taskData?.dueDate = dueDate
        }
        
        if let estimatedDuration = estimatedDuration {
            item.taskData?.estimatedDuration = estimatedDuration
        }
        
        item.markAsEdited()
        
        // Update project progress if task completion status changed
        if needsProjectUpdate, let projectId = oldProjectId {
            try updateProjectProgressForTask(projectId: projectId)
        }
        
        try repository.save()
    }
    
    // MARK: - Private Helpers
    
    private func updateProjectProgressForTask(projectId: UUID) throws {
        let projectTasks = try repository.fetchTasksForProject(projectId)
        let projects = try repository.fetchByType(SavedItemType.project)
        
        guard let project = projects.first(where: { $0.id == projectId }) else {
            return
        }
        
        let completedTasks = projectTasks.filter { $0.taskData?.isCompleted == true }
        let progress = projectTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(projectTasks.count)
        
        project.projectData?.updateProgress(progress)
        project.markAsEdited()
    }
}

// MARK: - Service Errors

public enum SavedItemServiceError: LocalizedError {
    case invalidItemType(String)
    case itemNotFound
    case repositoryError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidItemType(let message):
            return "Invalid item type: \(message)"
        case .itemNotFound:
            return "Item not found"
        case .repositoryError(let error):
            return "Repository error: \(error.localizedDescription)"
        }
    }
}