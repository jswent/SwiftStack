//
//  SavedItem.swift
//  STACK
//
//  Created by James Swent on 7/9/25.
//

import Foundation
import SwiftData

@Model
final class SavedItem: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String?
    var url: URL?            // ← new optional URL property
    var createdAt: Date
    var lastEdited: Date

    init(title: String,
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
