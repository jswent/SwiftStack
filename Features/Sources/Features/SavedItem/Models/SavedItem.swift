//
//  SavedItem.swift
//  STACK
//
//  Created by James Swent on 7/9/25.
//

import Foundation
import SwiftData

@Model
public final class SavedItem: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var notes: String?
    public var url: URL?
    public var createdAt: Date
    public var lastEdited: Date
    
    @Relationship(deleteRule: .cascade)
    public var photos: [Photo] = []

    public init(title: String,
         notes: String? = nil,
         url: URL? = nil) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.url = url
        let now = Date()
        self.createdAt = now
        self.lastEdited = now
    }
}

#if DEBUG
extension SavedItem {
    static var mock: Self {
        let item = SavedItem(
            title: "Sample Saved Item",
            notes: "This is a sample note for testing purposes",
            url: URL(string: "https://example.com")
        )
        item.photos = [.mock, .mock] // Add mock photos for testing carousel
        return item
    }
}
#endif
