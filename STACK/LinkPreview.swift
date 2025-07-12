//
//  LinkPreview.swift
//  STACK
//
//  Created by James Swent on 7/12/25.
//

import SwiftUI
import LinkPresentation

final class LinkMetadataCache {
    static let shared = LinkMetadataCache()

    private let cache = NSCache<NSURL, LPLinkMetadata>()

    private init() {}

    func metadata(for url: URL) -> LPLinkMetadata? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ metadata: LPLinkMetadata, for url: URL) {
        cache.setObject(metadata, forKey: url as NSURL)
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
