//
//  Photo.swift
//  STACK
//
//  Created by James Swent on 7/24/25.
//

import Foundation
import SwiftData

@Model
public final class Photo: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var fileURL: URL
    public var thumbnailURL: URL
    public var createdAt: Date
    public var isLinked: Bool
    
    @Relationship(deleteRule: .nullify, inverse: \SavedItem.photos)
    public var savedItem: SavedItem?
    
    public init(fileURL: URL, thumbnailURL: URL) {
        self.id = UUID()
        self.fileURL = fileURL
        self.thumbnailURL = thumbnailURL
        self.createdAt = Date()
        self.isLinked = false // Start as unlinked (orphaned)
    }
}

#if DEBUG
extension Photo {
    static var mock: Photo {
        let photo = Photo(
            fileURL: URL(fileURLWithPath: "/mock/photo.jpg"),
            thumbnailURL: URL(fileURLWithPath: "/mock/thumbnail.jpg")
        )
        photo.isLinked = true // Mock is linked for testing
        return photo
    }
}
#endif