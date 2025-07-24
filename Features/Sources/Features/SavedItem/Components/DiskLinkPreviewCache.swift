//
//  DiskLinkPreviewCache.swift
//  STACK
//
//  Created by James Swent on 7/23/25.
//

import Foundation
import LinkPresentation

/// On-disk cache using UserDefaults in App Group
final class DiskLinkPreviewCache: LinkPreviewCaching {
    private let userDefaults: UserDefaults
    private let queue = DispatchQueue(label: "DiskLinkPreviewCache", qos: .utility)
    
    init() {
        guard let suite = UserDefaults(suiteName: "group.com.jswent.STACK") else {
            fatalError("Failed to create UserDefaults with app group suite")
        }
        self.userDefaults = suite
    }
    
    func get(for url: URL) -> LPLinkMetadata? {
        return queue.sync {
            let key = cacheKey(for: url)
            guard let data = userDefaults.data(forKey: key) else { return nil }
            
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data)
            } catch {
                // Remove corrupted entry
                userDefaults.removeObject(forKey: key)
                return nil
            }
        }
    }
    
    func set(_ metadata: LPLinkMetadata, for url: URL) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let key = self.cacheKey(for: url)
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
                self.userDefaults.set(data, forKey: key)
            } catch {
                // Silently fail archiving errors
            }
        }
    }
    
    func removeAll() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let keys = self.userDefaults.dictionaryRepresentation().keys
            
            for key in keys {
                if key.hasPrefix("linkpreview_") {
                    self.userDefaults.removeObject(forKey: key)
                }
            }
        }
    }
    
    private func cacheKey(for url: URL) -> String {
        return "linkpreview_" + url.absoluteString.data(using: .utf8)!.base64EncodedString()
    }
}