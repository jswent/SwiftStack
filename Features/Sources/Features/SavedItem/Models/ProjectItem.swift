//
//  ProjectItem.swift
//  Features
//
//  Created by James Swent on 8/1/25.
//

import Foundation
import SwiftData

@Model
public final class ProjectItem: SavedItem {
    public var status: ProjectStatus
    public var startDate: Date?
    public var targetCompletionDate: Date?
    public var progress: Double // 0.0 to 1.0
    
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.project)
    public var tasks: [TaskItem] = []
    
    public init(title: String,
         notes: String? = nil,
         url: URL? = nil,
         status: ProjectStatus = .notStarted,
         startDate: Date? = nil,
         targetCompletionDate: Date? = nil) {
        self.status = status
        self.startDate = startDate
        self.targetCompletionDate = targetCompletionDate
        self.progress = 0.0
        super.init(title: title, notes: notes, url: url)
    }
    
    required public init(title: String, notes: String? = nil, url: URL? = nil) {
        self.status = .notStarted
        self.startDate = nil
        self.targetCompletionDate = nil
        self.progress = 0.0
        super.init(title: title, notes: notes, url: url)
    }
    
    public func addTask(_ task: TaskItem) {
        tasks.append(task)
        task.project = self
        markAsEdited()
    }
    
    public func removeTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        task.project = nil
        markAsEdited()
    }
    
    public var completionRate: Double {
        guard !tasks.isEmpty else { return 0.0 }
        let completedTasks = tasks.filter { $0.status == .done }.count
        return Double(completedTasks) / Double(tasks.count)
    }
    
    public var activeTasks: [TaskItem] {
        return tasks.filter { $0.isActive }
    }
    
    public var completedTasks: [TaskItem] {
        return tasks.filter { $0.status == .done }
    }
    
    public var canceledTasks: [TaskItem] {
        return tasks.filter { $0.status == .canceled }
    }
    
    public func updateProgress() {
        progress = completionRate
        markAsEdited()
    }
}

public enum ProjectStatus: String, CaseIterable, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case onHold = "On Hold"
    case completed = "Completed"
    case cancelled = "Cancelled"
}
