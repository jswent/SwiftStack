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
    public var url: URL?            // ← new optional URL property
    public var createdAt: Date
    public var lastEdited: Date

    public init(title: String,
         notes: String? = nil,
         url: URL? = nil) { // ← accept URL in initializer
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
        return .init(
            title: "Sample Saved Item",
            notes: "This is a sample note for testing purposes",
            url: URL(string: "https://example.com")
        )
    }
}
#endif