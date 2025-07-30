//
//  PhotoCarouselView.swift
//  STACK
//
//  Created by James Swent on 7/29/25.
//

import SwiftUI

public struct PhotoCarouselView: View {
    let photos: [Photo]
    let maxHeight: CGFloat
    @State private var scrollPosition: Int? = 0
    @State private var loadedIndices: Set<Int> = []
    
    private let preloadRange = 2 // Load current + 2 adjacent photos
    
    public init(photos: [Photo], maxHeight: CGFloat = 300) {
        self.photos = photos
        self.maxHeight = maxHeight
    }
    
    private var currentIndex: Int {
        scrollPosition ?? 0
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                            PhotoImageView(photo: photo, maxHeight: maxHeight)
                                .id(index)
                                .containerRelativeFrame(.horizontal)
                                .onAppear {
                                    loadedIndices.insert(index)
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrollPosition)
                .onChange(of: scrollPosition) { _, newValue in
                    updateLoadedPhotos()
                }
                .onAppear {
                    updateLoadedPhotos()
                }
            }
            
            // Page indicator - only show if multiple photos
            if photos.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<photos.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.primary : Color.secondary.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                scrollPosition = index
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func updateLoadedPhotos() {
        // Track loaded photos for potential future optimizations
        let range = max(0, currentIndex - preloadRange)...min(photos.count - 1, currentIndex + preloadRange)
        for index in range {
            loadedIndices.insert(index)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        // Single photo
        PhotoCarouselView(photos: [.mock])
        
        // Multiple photos (simulated)
        PhotoCarouselView(photos: [.mock, .mock, .mock], maxHeight: 200)
    }
    .padding()
}