//
//  PhotoMemoryCache.swift
//  STACK
//
//  Created by James Swent on 7/30/25.
//

import UIKit
import Foundation

/// Thread-safe LRU cache for UIImage storage with memory-pressure-driven pruning
final class PhotoMemoryCache {
    
    // MARK: - LRU Node
    
    private class Node {
        let photoId: UUID
        var image: UIImage
        var prev: Node?
        var next: Node?
        
        init(photoId: UUID, image: UIImage) {
            self.photoId = photoId
            self.image = image
        }
    }
    
    // MARK: - Configuration & Storage
    
    private let type: PhotoCacheType
    private let queue: DispatchQueue
    private var lookup: [UUID: Node] = [:]
    private var head: Node?      // most-recently used
    private var tail: Node?      // least-recently used
    
    private let prunePercentage: Double
    private let maxEntries: Int
    private let hourlyInterval: TimeInterval = 60 * 60
    
    private var hourlyTimer: DispatchSourceTimer?
    private var memoryObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    init(type: PhotoCacheType, maxEntries: Int, prunePercentage: Double) {
        self.type = type
        self.maxEntries = maxEntries
        self.prunePercentage = prunePercentage
        
        let label = "PhotoMemoryCache_\(type)"
        self.queue = DispatchQueue(label: label, qos: .utility)
        
        setupTimerAndObservers()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public API
    
    /// Retrieve image and bump to most-recent position
    func get(for photoId: UUID) -> UIImage? {
        return queue.sync {
            guard let node = lookup[photoId] else { return nil }
            moveToHead(node)
            return node.image
        }
    }
    
    /// Insert or update image, move to head, then enforce capacity
    func set(_ image: UIImage, for photoId: UUID) {
        queue.async { [weak self] in
            self?._unsafeSet(image, for: photoId)
        }
    }
    
    /// Remove specific photo from cache
    func remove(for photoId: UUID) {
        queue.async { [weak self] in
            self?._unsafeRemove(for: photoId)
        }
    }
    
    /// Remove all cached images
    func removeAll() {
        queue.sync {
            lookup.removeAll()
            head = nil
            tail = nil
        }
    }
    
    // MARK: - Timer & Observer Setup
    
    private func setupTimerAndObservers() {
        // Schedule hourly capacity enforcement
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + hourlyInterval, repeating: hourlyInterval)
        timer.setEventHandler { [weak self] in
            self?._unsafeEnforceCapacity()
        }
        timer.resume()
        self.hourlyTimer = timer
        
        // Memory warning handling
        memoryObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pruneFractional()
        }
        
        // Full cleanup on termination
        terminateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.removeAll()
        }
    }
    
    private func cleanup() {
        if let observer = memoryObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = terminateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        hourlyTimer?.cancel()
    }
    
    // MARK: - Private Implementation
    
    private func _unsafeSet(_ image: UIImage, for photoId: UUID) {
        if let node = lookup[photoId] {
            // Update existing node
            node.image = image
            moveToHead(node)
        } else {
            // Insert new node
            let node = Node(photoId: photoId, image: image)
            lookup[photoId] = node
            insertAtHead(node)
        }
        _unsafeEnforceCapacity()
    }
    
    private func _unsafeRemove(for photoId: UUID) {
        guard let node = lookup[photoId] else { return }
        lookup.removeValue(forKey: photoId)
        removeNode(node)
    }
    
    // MARK: - LRU Implementation
    
    private func moveToHead(_ node: Node) {
        guard head !== node else { return }
        
        // Unlink from current position
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if tail === node { tail = node.prev }
        
        // Insert at head
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
    }
    
    private func insertAtHead(_ node: Node) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        if tail == nil { tail = node }
    }
    
    private func removeNode(_ node: Node) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if head === node { head = node.next }
        if tail === node { tail = node.prev }
    }
    
    // MARK: - Capacity Management
    
    /// Enforce hard capacity limit
    private func _unsafeEnforceCapacity() {
        let excess = lookup.count - maxEntries
        guard excess > 0 else { return }
        _unsafePrune(count: excess)
    }
    
    /// Remove fraction of entries on memory pressure
    private func pruneFractional() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let total = self.lookup.count
            guard total > 0 else { return }
            let toPrune = Int(ceil(Double(total) * self.prunePercentage))
            self._unsafePrune(count: toPrune)
        }
    }
    
    /// Remove up to `count` items from LRU end
    private func _unsafePrune(count: Int) {
        var removed = 0
        while removed < count, let oldNode = tail {
            lookup.removeValue(forKey: oldNode.photoId)
            removeNode(oldNode)
            removed += 1
        }
    }
}