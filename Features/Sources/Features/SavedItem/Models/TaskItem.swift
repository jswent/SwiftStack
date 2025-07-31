//
//  TaskItem.swift
//  Features
//
//  Created by James Swent on 7/30/25.
//

import Foundation
import SwiftData

@Model
public final class TaskItem: SavedItem {
    public var status: TaskStatus
    public var priority: TaskPriority?
    public var dueDate: Date?
    public var estimatedDuration: TimeInterval?

    //    @Relationship(deleteRule: .nullify)
    //    public var project: ProjectItem?

    public init(
        title: String,
        notes: String? = nil,
        url: URL? = nil,
        status: TaskStatus = .backlog,
        priority: TaskPriority? = nil,
        dueDate: Date? = nil,
        estimatedDuration: TimeInterval? = nil
    ) {
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.estimatedDuration = estimatedDuration
        super.init(title: title, notes: notes, url: url)
    }

    required public init(title: String, notes: String? = nil, url: URL? = nil) {
        self.status = .todo
        self.priority = .medium
        self.dueDate = nil
        self.estimatedDuration = nil
        super.init(title: title, notes: notes, url: url)
    }

    public func markAsDone() {
        status = .done
        markAsEdited()
    }

    public func markAsCanceled() {
        status = .canceled
        markAsEdited()
    }

    public var isCompleted: Bool {
        return status == .done
    }

    public var isCanceled: Bool {
        return status == .canceled
    }

    public var isActive: Bool {
        return ![.done, .canceled].contains(status)
    }

    public var isOverdue: Bool {
        guard let dueDate = dueDate, isActive else { return false }
        return dueDate < Date()
    }
}

// MARK: - Supporting Enums
public enum TaskStatus: String, CaseIterable, Codable {
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
}

public enum TaskPriority: String, CaseIterable, Codable {
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
}
