//
//  PhotoPreviewCache.swift
//  STACK
//
//  Created by James Swent on 7/30/25.
//

import UIKit
import Foundation

// MARK: - Caching Protocol

/// Protocol for photo preview caching implementations
protocol PhotoPreviewCaching {
    func getFullImage(for photoId: UUID) -> UIImage?
    func getThumbnail(for photoId: UUID) -> UIImage?
    func setFullImage(_ image: UIImage, for photoId: UUID)
    func setThumbnail(_ image: UIImage, for photoId: UUID)
    func removeImages(for photoId: UUID)
    func removeAll()
}

// MARK: - Cache Entry Types

enum PhotoCacheType {
    case fullImage
    case thumbnail
}

// MARK: - Main Cache Implementation

/// In-memory photo cache with separate pools for full images and thumbnails
@MainActor
final class PhotoPreviewCache: PhotoPreviewCaching {
    static let shared = PhotoPreviewCache()
    
    private let fullImageCache: PhotoMemoryCache
    private let thumbnailCache: PhotoMemoryCache
    
    private init() {
        self.fullImageCache = PhotoMemoryCache(
            type: .fullImage,
            maxEntries: 20,           // Full images are large - conservative limit
            prunePercentage: 0.3      // Aggressive pruning for memory pressure
        )
        self.thumbnailCache = PhotoMemoryCache(
            type: .thumbnail,
            maxEntries: 50,           // Thumbnails are small - allow more
            prunePercentage: 0.25     // Less aggressive pruning
        )
    }
    
    func getFullImage(for photoId: UUID) -> UIImage? {
        return fullImageCache.get(for: photoId)
    }
    
    func getThumbnail(for photoId: UUID) -> UIImage? {
        return thumbnailCache.get(for: photoId)
    }
    
    func setFullImage(_ image: UIImage, for photoId: UUID) {
        fullImageCache.set(image, for: photoId)
    }
    
    func setThumbnail(_ image: UIImage, for photoId: UUID) {
        thumbnailCache.set(image, for: photoId)
    }
    
    func removeImages(for photoId: UUID) {
        fullImageCache.remove(for: photoId)
        thumbnailCache.remove(for: photoId)
    }
    
    func removeAll() {
        fullImageCache.removeAll()
        thumbnailCache.removeAll()
    }
}