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
    var createdAt: Date
    var lastEdited: Date

    init(title: String, notes: String? = nil) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        let now = Date()
        self.createdAt = now
        self.lastEdited = now
    }
}
