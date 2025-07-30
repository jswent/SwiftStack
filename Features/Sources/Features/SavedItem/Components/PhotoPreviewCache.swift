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
public protocol PhotoPreviewCaching {
    func getFullImage(for photoId: UUID) -> UIImage?
    func getThumbnail(for photoId: UUID) -> UIImage?
    func setFullImage(_ image: UIImage, for photoId: UUID)
    func setThumbnail(_ image: UIImage, for photoId: UUID)
    func removeImages(for photoId: UUID)
    func removeAll()
}

// MARK: - Cache Entry Types

public enum PhotoCacheType {
    case fullImage
    case thumbnail
}

// MARK: - Main Cache Implementation

/// In-memory photo cache with separate pools for full images and thumbnails
@MainActor
public final class PhotoPreviewCache: PhotoPreviewCaching {
    public static let shared = PhotoPreviewCache()
    
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
    
    public func getFullImage(for photoId: UUID) -> UIImage? {
        return fullImageCache.get(for: photoId)
    }
    
    public func getThumbnail(for photoId: UUID) -> UIImage? {
        return thumbnailCache.get(for: photoId)
    }
    
    public func setFullImage(_ image: UIImage, for photoId: UUID) {
        fullImageCache.set(image, for: photoId)
    }
    
    public func setThumbnail(_ image: UIImage, for photoId: UUID) {
        thumbnailCache.set(image, for: photoId)
    }
    
    public func removeImages(for photoId: UUID) {
        fullImageCache.remove(for: photoId)
        thumbnailCache.remove(for: photoId)
    }
    
    public func removeAll() {
        fullImageCache.removeAll()
        thumbnailCache.removeAll()
    }
}