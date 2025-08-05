//
//  SavedItemService+Project.swift
//  Features
//
//  Created by James Swent on 8/4/25.
//

import Foundation

// MARK: - Project Business Logic

extension SavedItemService {
    
    /// Complete a project
    public func completeProject(_ item: SavedItem) throws {
        guard item.isProject else {
            throw SavedItemServiceError.invalidItemType("Item must be a project")
        }
        
        item.projectData?.markAsCompleted()
        item.markAsEdited()
        
        try repository.save()
    }
    
    /// Cancel a project
    public func cancelProject(_ item: SavedItem) throws {
        guard item.isProject else {
            throw SavedItemServiceError.invalidItemType("Item must be a project")
        }
        
        item.projectData?.markAsCancelled()
        item.markAsEdited()
        
        try repository.save()
    }
    
    /// Put a project on hold
    public func putProjectOnHold(_ item: SavedItem) throws {
        guard item.isProject else {
            throw SavedItemServiceError.invalidItemType("Item must be a project")
        }
        
        item.projectData?.putOnHold()
        item.markAsEdited()
        
        try repository.save()
    }
    
    /// Resume a project from hold
    public func resumeProject(_ item: SavedItem) throws {
        guard item.isProject else {
            throw SavedItemServiceError.invalidItemType("Item must be a project")
        }
        
        item.projectData?.resume()
        item.markAsEdited()
        
        try repository.save()
    }
    
    /// Update project properties
    public func updateProject(
        _ item: SavedItem,
        status: ProjectStatus? = nil,
        startDate: Date? = nil,
        targetCompletionDate: Date? = nil,
        progress: Double? = nil
    ) throws {
        guard item.isProject else {
            throw SavedItemServiceError.invalidItemType("Item must be a project")
        }
        
        if let status = status {
            item.projectData?.status = status
        }
        
        if let startDate = startDate {
            item.projectData?.startDate = startDate
        }
        
        if let targetCompletionDate = targetCompletionDate {
            item.projectData?.targetCompletionDate = targetCompletionDate
        }
        
        if let progress = progress {
            item.projectData?.updateProgress(progress)
        }
        
        item.markAsEdited()
        try repository.save()
    }
    
    /// Calculate and update project progress based on its tasks
    public func updateProjectProgress(_ item: SavedItem) throws {
        guard item.isProject else {
            throw SavedItemServiceError.invalidItemType("Item must be a project")
        }
        
        let projectTasks = try repository.fetchTasksForProject(item.id)
        
        guard !projectTasks.isEmpty else {
            // No tasks, keep current progress
            return
        }
        
        let completedTasks = projectTasks.filter { $0.taskData?.isCompleted == true }
        let progress = Double(completedTasks.count) / Double(projectTasks.count)
        
        item.projectData?.updateProgress(progress)
        item.markAsEdited()
        
        try repository.save()
    }
    
    /// Get a summary of project status and progress
    public func getProjectSummary(_ item: SavedItem) throws -> ProjectSummary {
        guard item.isProject else {
            throw SavedItemServiceError.invalidItemType("Item must be a project")
        }
        
        let projectTasks = try repository.fetchTasksForProject(item.id)
        let completedTasks = projectTasks.filter { $0.taskData?.isCompleted == true }
        let activeTasks = projectTasks.filter { $0.taskData?.isActive == true }
        let overdueTasks = projectTasks.filter { $0.taskData?.isOverdue == true }
        
        let completionRate = projectTasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(projectTasks.count)
        
        // Calculate days until deadline
        var daysUntilDeadline: Int?
        if let targetDate = item.projectData?.targetCompletionDate {
            let calendar = Calendar.current
            daysUntilDeadline = calendar.dateComponents([.day], from: Date(), to: targetDate).day
        }
        
        // Determine if project is on track (simple heuristic)
        let isOnTrack = overdueTasks.isEmpty && (item.projectData?.isActive == true)
        
        return ProjectSummary(
            totalTasks: projectTasks.count,
            completedTasks: completedTasks.count,
            activeTasks: activeTasks.count,
            overdueTasks: overdueTasks.count,
            completionRate: completionRate,
            isOnTrack: isOnTrack,
            daysUntilDeadline: daysUntilDeadline
        )
    }
}

// MARK: - Project Summary

public struct ProjectSummary {
    public let totalTasks: Int
    public let completedTasks: Int
    public let activeTasks: Int
    public let overdueTasks: Int
    public let completionRate: Double
    public let isOnTrack: Bool
    public let daysUntilDeadline: Int?
    
    public init(
        totalTasks: Int,
        completedTasks: Int,
        activeTasks: Int,
        overdueTasks: Int,
        completionRate: Double,
        isOnTrack: Bool,
        daysUntilDeadline: Int?
    ) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.activeTasks = activeTasks
        self.overdueTasks = overdueTasks
        self.completionRate = completionRate
        self.isOnTrack = isOnTrack
        self.daysUntilDeadline = daysUntilDeadline
    }
}