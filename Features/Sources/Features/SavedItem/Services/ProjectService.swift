//
//  ProjectService.swift
//  Features
//
//  Created by James Swent on 8/1/25.
//

import Foundation

public protocol ProjectServiceProtocol {
    func updateProjectStatus(_ project: ProjectItem, status: ProjectStatus) throws
    func updateProjectTargetDate(_ project: ProjectItem, targetDate: Date?) throws
    func updateProjectStartDate(_ project: ProjectItem, startDate: Date?) throws
    func calculateProjectProgress(_ project: ProjectItem) throws -> Double
    func getProjectSummary(_ project: ProjectItem) -> ProjectSummary
}

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

public final class ProjectService: ProjectServiceProtocol {
    private let projectRepository: ProjectRepositoryProtocol
    
    public init(projectRepository: ProjectRepositoryProtocol) {
        self.projectRepository = projectRepository
    }
    
    public func updateProjectStatus(_ project: ProjectItem, status: ProjectStatus) throws {
        project.status = status
        project.markAsEdited()
        try projectRepository.save()
    }
    
    public func updateProjectTargetDate(_ project: ProjectItem, targetDate: Date?) throws {
        project.targetCompletionDate = targetDate
        project.markAsEdited()
        try projectRepository.save()
    }
    
    public func updateProjectStartDate(_ project: ProjectItem, startDate: Date?) throws {
        project.startDate = startDate
        project.markAsEdited()
        try projectRepository.save()
    }
    
    public func calculateProjectProgress(_ project: ProjectItem) throws -> Double {
        let progress = project.completionRate
        project.progress = progress
        project.markAsEdited()
        try projectRepository.save()
        return progress
    }
    
    public func getProjectSummary(_ project: ProjectItem) -> ProjectSummary {
        let totalTasks = project.tasks.count
        let completedTasks = project.completedTasks.count
        let activeTasks = project.activeTasks.count
        let overdueTasks = project.activeTasks.filter { $0.isOverdue }.count
        let completionRate = project.completionRate
        
        let daysUntilDeadline: Int? = {
            guard let targetDate = project.targetCompletionDate else { return nil }
            return Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day
        }()
        
        let isOnTrack: Bool = {
            guard let targetDate = project.targetCompletionDate,
                  let startDate = project.startDate else { return true }
            
            let totalDuration = targetDate.timeIntervalSince(startDate)
            let elapsedDuration = Date().timeIntervalSince(startDate)
            let expectedProgress = elapsedDuration / totalDuration
            
            return completionRate >= expectedProgress
        }()
        
        return ProjectSummary(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            activeTasks: activeTasks,
            overdueTasks: overdueTasks,
            completionRate: completionRate,
            isOnTrack: isOnTrack,
            daysUntilDeadline: daysUntilDeadline
        )
    }
}