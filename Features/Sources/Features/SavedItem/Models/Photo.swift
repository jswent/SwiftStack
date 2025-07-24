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
    public var filePath: String // Store relative path instead of absolute URL
    public var thumbnailPath: String // Store relative path instead of absolute URL
    public var createdAt: Date
    public var isLinked: Bool
    
    @Relationship(deleteRule: .nullify, inverse: \SavedItem.photos)
    public var savedItem: SavedItem?
    
    public init(filePath: String, thumbnailPath: String) {
        self.id = UUID()
        self.filePath = filePath
        self.thumbnailPath = thumbnailPath
        self.createdAt = Date()
        self.isLinked = false // Start as unlinked (orphaned)
    }
    
    // Computed properties to get full URLs
    public var fileURL: URL? {
        guard let baseURL = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        return baseURL.appendingPathComponent(filePath)
    }
    
    public var thumbnailURL: URL? {
        guard let baseURL = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        return baseURL.appendingPathComponent(thumbnailPath)
    }
}

#if DEBUG
extension Photo {
    static var mock: Photo {
        let photo = Photo(
            filePath: "Photos/mock-photo.jpg",
            thumbnailPath: "Photos/Thumbnails/mock-thumbnail.jpg"
        )
        photo.isLinked = true // Mock is linked for testing
        return photo
    }
}
#endif