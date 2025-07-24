//
//  HybridLinkPreviewCache.swift
//  STACK
//
//  Created by James Swent on 7/23/25.
//

import Foundation
import LinkPresentation

// MARK: - Caching Protocol

/// Protocol for link preview caching implementations
protocol LinkPreviewCaching {
    func get(for url: URL) -> LPLinkMetadata?
    func set(_ metadata: LPLinkMetadata, for url: URL)
    func removeAll()
}

// MARK: - Hybrid Cache Implementation

/// Two-tier hybrid cache combining in-memory LRU with on-disk App Group storage
@MainActor
final class HybridLinkPreviewCache: LinkPreviewCaching {
    static let shared = HybridLinkPreviewCache()
    
    private let memoryCache: LinkPreviewCaching
    private let diskCache: LinkPreviewCaching
    
    private init() {
        self.memoryCache = LinkMetadataCache.shared
        self.diskCache = DiskLinkPreviewCache()
    }
    
    func get(for url: URL) -> LPLinkMetadata? {
        // 1. Check memory cache first
        if let metadata = memoryCache.get(for: url) {
            return metadata
        }
        
        // 2. Fall back to disk cache
        if let metadata = diskCache.get(for: url) {
            // Warm memory cache with disk hit
            memoryCache.set(metadata, for: url)
            return metadata
        }
        
        // 3. Cache miss
        return nil
    }
    
    func set(_ metadata: LPLinkMetadata, for url: URL) {
        // Write to both memory and disk
        memoryCache.set(metadata, for: url)
        diskCache.set(metadata, for: url)
    }
    
    func removeAll() {
        // Clear both layers
        memoryCache.removeAll()
        diskCache.removeAll()
    }
}
