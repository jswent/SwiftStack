//
//  TaskService.swift
//  Features
//
//  Created by James Swent on 8/1/25.
//

import Foundation

public protocol TaskServiceProtocol {
    func completeTask(_ task: TaskItem) throws
    func cancelTask(_ task: TaskItem) throws
    func addTaskToProject(_ task: TaskItem, project: ProjectItem) throws
    func removeTaskFromProject(_ task: TaskItem) throws
    func updateTaskPriority(_ task: TaskItem, priority: TaskPriority) throws
    func updateTaskDueDate(_ task: TaskItem, dueDate: Date?) throws
    func updateTaskStatus(_ task: TaskItem, status: TaskStatus) throws
}

public final class TaskService: TaskServiceProtocol {
    private let taskRepository: TaskRepositoryProtocol
    private let projectRepository: ProjectRepositoryProtocol
    
    public init(
        taskRepository: TaskRepositoryProtocol,
        projectRepository: ProjectRepositoryProtocol
    ) {
        self.taskRepository = taskRepository
        self.projectRepository = projectRepository
    }
    
    public func completeTask(_ task: TaskItem) throws {
        task.markAsDone()
        
        if let project = task.project {
            project.updateProgress()
        }
        
        try taskRepository.save()
    }
    
    public func cancelTask(_ task: TaskItem) throws {
        task.markAsCanceled()
        
        if let project = task.project {
            project.updateProgress()
        }
        
        try taskRepository.save()
    }
    
    public func addTaskToProject(_ task: TaskItem, project: ProjectItem) throws {
        project.addTask(task)
        try projectRepository.save()
    }
    
    public func removeTaskFromProject(_ task: TaskItem) throws {
        guard let project = task.project else { return }
        
        project.removeTask(task)
        try projectRepository.save()
    }
    
    public func updateTaskPriority(_ task: TaskItem, priority: TaskPriority) throws {
        task.priority = priority
        task.markAsEdited()
        try taskRepository.save()
    }
    
    public func updateTaskDueDate(_ task: TaskItem, dueDate: Date?) throws {
        task.dueDate = dueDate
        task.markAsEdited()
        try taskRepository.save()
    }
    
    public func updateTaskStatus(_ task: TaskItem, status: TaskStatus) throws {
        let oldStatus = task.status
        task.status = status
        task.markAsEdited()
        
        // Update project progress if status changed to/from completed
        if let project = task.project,
           (oldStatus == .done || status == .done) {
            project.updateProgress()
        }
        
        try taskRepository.save()
    }
}