//
//  SavedItemType.swift
//  Features
//
//  Created by James Swent on 8/4/25.
//

import Foundation

public enum SavedItemType: String, CaseIterable, Codable, Sendable {
    case item = "Item"
    case task = "Task"
    case project = "Project"
    
    public var displayName: String {
        return rawValue
    }
    
    public var systemImage: String {
        switch self {
        case .item: return "doc.text"
        case .task: return "checkmark.circle"
        case .project: return "folder"
        }
    }
    
    public var pluralDisplayName: String {
        switch self {
        case .item: return "Items"
        case .task: return "Tasks"
        case .project: return "Projects"
        }
    }
}