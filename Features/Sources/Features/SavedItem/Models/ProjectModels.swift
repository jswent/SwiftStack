//
//  ProjectModels.swift
//  Features
//
//  Created by James Swent on 8/4/25.
//

import Foundation

// MARK: - Project Status

public enum ProjectStatus: String, CaseIterable, Codable, Sendable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case onHold = "On Hold"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    public var color: String {
        switch self {
        case .notStarted: return "gray"
        case .inProgress: return "blue"
        case .onHold: return "orange"
        case .completed: return "green"
        case .cancelled: return "red"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "clock"
        case .onHold: return "pause.circle"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    public var isActive: Bool {
        return [.notStarted, .inProgress].contains(self)
    }
    
    public var isCompleted: Bool {
        return self == .completed
    }
    
    public var isCancelled: Bool {
        return self == .cancelled
    }
}

// MARK: - Project Data

public struct ProjectData: Codable, Sendable {
    public var status: ProjectStatus
    public var startDate: Date?
    public var targetCompletionDate: Date?
    public var progress: Double
    public var taskIds: [UUID]
    
    public init(
        status: ProjectStatus = .notStarted,
        startDate: Date? = nil,
        targetCompletionDate: Date? = nil,
        progress: Double = 0.0,
        taskIds: [UUID] = []
    ) {
        self.status = status
        self.startDate = startDate
        self.targetCompletionDate = targetCompletionDate
        self.progress = max(0.0, min(1.0, progress)) // Clamp between 0 and 1
        self.taskIds = taskIds
    }
    
    // Convenience computed properties
    public var isActive: Bool {
        return status.isActive
    }
    
    public var isCompleted: Bool {
        return status.isCompleted
    }
    
    public var isCancelled: Bool {
        return status.isCancelled
    }
    
    public var completionPercentage: Int {
        return Int(progress * 100)
    }
    
    public var isOverdue: Bool {
        guard let targetDate = targetCompletionDate, isActive else { return false }
        return targetDate < Date()
    }
    
    // Mutating methods for managing project state
    public mutating func updateProgress(_ newProgress: Double) {
        self.progress = max(0.0, min(1.0, newProgress))
        
        // Auto-update status based on progress
        if newProgress >= 1.0 && status.isActive {
            status = .completed
        }
    }
    
    public mutating func addTask(_ taskId: UUID) {
        if !taskIds.contains(taskId) {
            taskIds.append(taskId)
        }
    }
    
    public mutating func removeTask(_ taskId: UUID) {
        taskIds.removeAll { $0 == taskId }
    }
    
    public mutating func markAsCompleted() {
        status = .completed
        progress = 1.0
    }
    
    public mutating func markAsCancelled() {
        status = .cancelled
    }
    
    public mutating func putOnHold() {
        if status.isActive {
            status = .onHold
        }
    }
    
    public mutating func resume() {
        if status == .onHold {
            status = progress > 0 ? .inProgress : .notStarted
        }
    }
}
