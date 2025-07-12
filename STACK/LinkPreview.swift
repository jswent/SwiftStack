//
//  LinkPreview.swift
//  STACK
//
//  Created by James Swent on 7/12/25.
//

import SwiftUI
import LinkPresentation

import UIKit
import LinkPresentation

/// A thread-safe LRU cache for storing LPLinkMetadata with both memory-warning–driven
/// fractional pruning and an hourly capacity enforcement timer.
final class LinkMetadataCache {
    static let shared = LinkMetadataCache(
        prunePercentage: 0.25,   // fraction of entries to drop on each memory warning
        maxEntries: 10,           // maximum number of items to keep in cache
        hourlyInterval: 60 * 60   // interval (in seconds) to re-enforce capacity
    )

    // MARK: - LRU list node
    private class Node {
        let url: URL
        var metadata: LPLinkMetadata
        var prev: Node?
        var next: Node?
        init(url: URL, metadata: LPLinkMetadata) {
            self.url = url
            self.metadata = metadata
        }
    }

    // MARK: - Storage & configuration
    private var lookup: [URL: Node] = [:]
    private var head: Node?      // most-recently used
    private var tail: Node?      // least-recently used

    private let prunePercentage: Double
    private let maxEntries: Int
    private let hourlyInterval: TimeInterval

    private var hourlyTimer: DispatchSourceTimer?
    private var memoryObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?

    /// - Parameters:
    ///   - prunePercentage: fraction of entries to drop on each memory warning (0…1)
    ///   - maxEntries: maximum number of items to keep in cache
    ///   - hourlyInterval: seconds between enforced capacity checks
    private init(
        prunePercentage: Double,
        maxEntries: Int,
        hourlyInterval: TimeInterval
    ) {
        self.prunePercentage = prunePercentage
        self.maxEntries = maxEntries
        self.hourlyInterval = hourlyInterval

        // Schedule hourly capacity enforcement
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .background))
        timer.schedule(deadline: .now() + hourlyInterval,
                       repeating: hourlyInterval)
        timer.setEventHandler { [weak self] in
            self?.enforceCapacity()
        }
        timer.resume()
        self.hourlyTimer = timer

        // Listen for memory warnings
        memoryObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pruneFractional()
        }

        // Full clear on real termination
        terminateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.removeAll()
        }
    }

    deinit {
        if let m = memoryObserver {
            NotificationCenter.default.removeObserver(m)
        }
        if let t = terminateObserver {
            NotificationCenter.default.removeObserver(t)
        }
        hourlyTimer?.cancel()
    }

    // MARK: - Public API

    /// Retrieve metadata and bump to most-recent position
    func metadata(for url: URL) -> LPLinkMetadata? {
        guard let node = lookup[url] else { return nil }
        moveToHead(node)
        return node.metadata
    }

    /// Insert or update metadata, move to head, then enforce capacity
    func set(_ metadata: LPLinkMetadata, for url: URL) {
        if let node = lookup[url] {
            node.metadata = metadata
            moveToHead(node)
        } else {
            let node = Node(url: url, metadata: metadata)
            lookup[url] = node
            insertAtHead(node)
        }
        enforceCapacity()
    }

    // MARK: - LRU internals

    private func moveToHead(_ node: Node) {
        guard head !== node else { return }
        // unlink
        node.prev?.next = node.next
        node.next?.prev = node.prev
        if tail === node { tail = node.prev }
        // insert before head
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

    private func removeAll() {
        lookup.removeAll()
        head = nil
        tail = nil
    }

    // MARK: - Capacity enforcement

    /// Enforce hard capacity, dropping oldest entries if over budget
    private func enforceCapacity() {
        let excess = lookup.count - maxEntries
        guard excess > 0 else { return }
        prune(count: excess)
    }

    // MARK: - Fractional pruning

    /// Remove prunePercentage × current count items from LRU end
    private func pruneFractional() {
        let total = lookup.count
        guard total > 0 else { return }
        let toPrune = Int(ceil(Double(total) * prunePercentage))
        prune(count: toPrune)
    }

    /// Remove up to `count` items from the LRU end
    private func prune(count: Int) {
        var removed = 0
        while removed < count, let old = tail {
            lookup.removeValue(forKey: old.url)
            removeNode(old)
            removed += 1
        }
    }
}

struct LinkPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LPLinkView {
        // Use cached metadata if available, else create empty
        let initialMetadata = LinkMetadataCache.shared.metadata(for: url) ?? LPLinkMetadata()
        let linkView = LPLinkView(metadata: initialMetadata)

        // If not cached yet, fetch and cache
        if LinkMetadataCache.shared.metadata(for: url) == nil {
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metadata, error in
                guard let metadata = metadata, error == nil else { return }
                LinkMetadataCache.shared.set(metadata, for: url)
                DispatchQueue.main.async {
                    linkView.metadata = metadata
                }
            }
        }

        return linkView
    }

    func updateUIView(_ uiView: LPLinkView, context: Context) { }
}
