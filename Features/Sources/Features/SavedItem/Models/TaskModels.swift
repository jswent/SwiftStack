//
//  TaskModels.swift
//  Features
//
//  Created by James Swent on 8/4/25.
//

import Foundation

// MARK: - Task Status

public enum TaskStatus: String, CaseIterable, Codable, Sendable {
    case backlog = "Backlog"
    case todo = "Todo"
    case inProgress = "In Progress"
    case inReview = "In Review"
    case done = "Done"
    case canceled = "Canceled"

    public var sortOrder: Int {
        switch self {
        case .backlog: return 1
        case .todo: return 2
        case .inProgress: return 3
        case .inReview: return 4
        case .done: return 5
        case .canceled: return 6
        }
    }

    public var color: String {
        switch self {
        case .backlog: return "gray"
        case .todo: return "blue"
        case .inProgress: return "orange"
        case .inReview: return "purple"
        case .done: return "green"
        case .canceled: return "gray"
        }
    }

    public var systemImage: String {
        switch self {
        case .backlog: return "tray"
        case .todo: return "circle"
        case .inProgress: return "clock"
        case .inReview: return "eye"
        case .done: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
        }
    }
    
    public var isCompleted: Bool {
        return self == .done
    }
    
    public var isCanceled: Bool {
        return self == .canceled
    }
    
    public var isActive: Bool {
        return ![.done, .canceled].contains(self)
    }
}

// MARK: - Task Priority

public enum TaskPriority: String, CaseIterable, Codable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    public var sortOrder: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .urgent: return 4
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Task Data

public struct TaskData: Codable, Sendable {
    public var status: TaskStatus
    public var priority: TaskPriority?
    public var dueDate: Date?
    public var estimatedDuration: TimeInterval?
    public var projectId: UUID?
    
    public init(
        status: TaskStatus = .todo,
        priority: TaskPriority? = nil,
        dueDate: Date? = nil,
        estimatedDuration: TimeInterval? = nil,
        projectId: UUID? = nil
    ) {
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.estimatedDuration = estimatedDuration
        self.projectId = projectId
    }
    
    // Convenience computed properties
    public var isCompleted: Bool {
        return status.isCompleted
    }
    
    public var isCanceled: Bool {
        return status.isCanceled
    }
    
    public var isActive: Bool {
        return status.isActive
    }
    
    public var isOverdue: Bool {
        guard let dueDate = dueDate, isActive else { return false }
        return dueDate < Date()
    }
    
    // Mutating methods
    public mutating func markAsCompleted() {
        status = .done
    }
    
    public mutating func markAsCanceled() {
        status = .canceled
    }
    
    public mutating func assignToProject(_ projectId: UUID) {
        self.projectId = projectId
    }
    
    public mutating func removeFromProject() {
        self.projectId = nil
    }
}