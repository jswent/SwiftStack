//
//  URLRoute.swift
//  Core
//
//  Created by James Swent on 7/22/25.
//

import Foundation

/// Represents the possible URL routes that the app can handle
public enum URLRoute: Equatable, Sendable {
    /// Open a specific saved item by UUID
    case openItem(UUID)
    
    /// Add a new item, optionally with pre-filled data
    case addItem(AddItemParameters)
    
    /// Unknown or unsupported route
    case unsupported(URL)
    
    /// Parameters for adding a new item
    public struct AddItemParameters: Equatable, Sendable {
        public let title: String?
        public let notes: String?
        public let url: String?
        
        public init(title: String? = nil, notes: String? = nil, url: String? = nil) {
            self.title = title
            self.notes = notes
            self.url = url
        }
        
        /// Create from URL query parameters
        public init(queryItems: [URLQueryItem]) {
            var title: String?
            var notes: String?
            var url: String?
            
            for item in queryItems {
                switch item.name.lowercased() {
                case "title":
                    title = item.value
                case "notes", "note":
                    notes = item.value
                case "url", "link":
                    url = item.value
                default:
                    break
                }
            }
            
            self.title = title
            self.notes = notes
            self.url = url
        }
        
        /// Check if any parameters are provided
        public var hasParameters: Bool {
            return title != nil || notes != nil || url != nil
        }
    }
}

// MARK: - Route Information

extension URLRoute {
    /// Human-readable description of the route
    public var description: String {
        switch self {
        case .openItem(let uuid):
            return "Open item: \(uuid.uuidString)"
        case .addItem(let params):
            return "Add item with parameters: \(params)"
        case .unsupported(let url):
            return "Unsupported URL: \(url.absoluteString)"
        }
    }
    
    /// Whether this route requires navigation
    public var requiresNavigation: Bool {
        switch self {
        case .openItem, .addItem:
            return true
        case .unsupported:
            return false
        }
    }
}