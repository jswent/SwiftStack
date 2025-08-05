//
//  SavedItem.swift
//  STACK
//
//  Created by James Swent on 7/9/25.
//

import Foundation
import SwiftData

/// A unified model for all saved content types with type discrimination
@Model
public class SavedItem: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var notes: String?
    public var url: URL?
    public var createdAt: Date
    public var lastEdited: Date
    public var type: SavedItemType
    
    @Relationship(deleteRule: .cascade)
    public var photos: [Photo] = []
    
    // Type-specific embedded data
    public var taskData: TaskData?
    public var projectData: ProjectData?

    public init(
        title: String,
        notes: String? = nil,
        url: URL? = nil,
        type: SavedItemType = .item
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.url = url
        self.type = type
        let now = Date()
        self.createdAt = now
        self.lastEdited = now
        
        // Initialize type-specific data
        self.initializeTypeSpecificData()
    }
    
    // Legacy initializer for compatibility
    public required init(title: String, notes: String? = nil, url: URL? = nil) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.url = url
        self.type = .item
        let now = Date()
        self.createdAt = now
        self.lastEdited = now
        
        // Initialize type-specific data
        self.initializeTypeSpecificData()
    }
    
    /// Marks the item as edited with current timestamp
    public func markAsEdited() {
        self.lastEdited = Date()
    }
    
    /// Initializes type-specific data based on the current type
    private func initializeTypeSpecificData() {
        switch type {
        case .item:
            taskData = nil
            projectData = nil
        case .task:
            taskData = TaskData()
            projectData = nil
        case .project:
            taskData = nil
            projectData = ProjectData()
        }
    }
}

// MARK: - Basic Properties

extension SavedItem {
    /// Convenience property to check if this is a task
    public var isTask: Bool { type == .task }
    
    /// Convenience property to check if this is a project  
    public var isProject: Bool { type == .project }
    
    /// Convenience property to check if this is a basic item
    public var isItem: Bool { type == .item }
}

// MARK: - Validation

extension SavedItem {
    /// Validates that the item's type matches its data
    public var isValid: Bool {
        switch type {
        case .item:
            return taskData == nil && projectData == nil
        case .task:
            return taskData != nil && projectData == nil
        case .project:
            return taskData == nil && projectData != nil
        }
    }
    
    /// Fixes any data inconsistencies by re-initializing type data
    public func validateAndFix() {
        if !isValid {
            initializeTypeSpecificData()
            markAsEdited()
        }
    }
}

#if DEBUG
extension SavedItem {
    static var mockItem: SavedItem {
        return SavedItem(
            title: "Sample Item",
            notes: "This is a sample item for testing purposes",
            url: URL(string: "https://example.com"),
            type: .item
        )
    }
    
    static var mockTask: SavedItem {
        let item = SavedItem(
            title: "Sample Task",
            notes: "This is a sample task",
            type: .task
        )
        item.taskData = TaskData(
            status: .todo,
            priority: .medium,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        return item
    }
    
    static var mockProject: SavedItem {
        let item = SavedItem(
            title: "Sample Project",
            notes: "This is a sample project",
            type: .project
        )
        item.projectData = ProjectData(
            status: .inProgress,
            startDate: Date(),
            targetCompletionDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            progress: 0.3
        )
        return item
    }
    
    // Legacy compatibility
    static var mock: SavedItem {
        return mockItem
    }
}
#endif
