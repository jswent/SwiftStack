//
//  LinkPreview.swift
//  STACK
//
//  Created by James Swent on 7/12/25.
//

import SwiftUI
import LinkPresentation

/// A UIViewRepresentable wrapper around LPLinkView with optimized caching
public struct LinkPreview: UIViewRepresentable {
    let url: URL
    
    public init(url: URL) {
        self.url = url
    }

    public func makeUIView(context: Context) -> LPLinkView {
        // Use cached metadata if available, else create empty
        let initialMetadata = HybridLinkPreviewCache.shared.get(for: url) ?? LPLinkMetadata()
        let linkView = LPLinkView(metadata: initialMetadata)

        // If not cached yet, fetch and cache
        if HybridLinkPreviewCache.shared.get(for: url) == nil {
            let provider = LPMetadataProvider()
            provider.startFetchingMetadata(for: url) { metadata, error in
                guard let metadata = metadata, error == nil else { return }
                HybridLinkPreviewCache.shared.set(metadata, for: url)
                DispatchQueue.main.async {
                    linkView.metadata = metadata
                }
            }
        }

        return linkView
    }

    public func updateUIView(_ uiView: LPLinkView, context: Context) {
        // Update with fresh cached metadata if URL changed
        if let cachedMetadata = HybridLinkPreviewCache.shared.get(for: url) {
            uiView.metadata = cachedMetadata
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        LinkPreview(url: URL(string: "https://example.com")!)
            .frame(height: 80)
        
        LinkPreview(url: URL(string: "https://apple.com")!)
            .frame(height: 80)
    }
    .padding()
}