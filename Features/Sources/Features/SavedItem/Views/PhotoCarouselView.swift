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
    @State private var currentIndex = 0
    @State private var loadedIndices: Set<Int> = []
    
    private let preloadRange = 2 // Load current + 2 adjacent photos
    
    public init(photos: [Photo], maxHeight: CGFloat = 300) {
        self.photos = photos
        self.maxHeight = maxHeight
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                            if shouldLoadPhoto(at: index) {
                                PhotoImageView(photo: photo, maxHeight: maxHeight)
                                    .id(index)
                                    .containerRelativeFrame(.horizontal)
                                    .onAppear {
                                        loadedIndices.insert(index)
                                    }
                            } else {
                                // Placeholder for unloaded photos
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: min(200, maxHeight))
                                    .containerRelativeFrame(.horizontal)
                                    .id(index)
                                    .overlay {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: .constant(currentIndex))
                .onChange(of: currentIndex) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
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
                                currentIndex = index
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func shouldLoadPhoto(at index: Int) -> Bool {
        // Always load the first few photos immediately
        if photos.count <= 3 || index <= 1 {
            return true
        }
        
        // For larger sets, load progressively based on current position
        let range = max(0, currentIndex - preloadRange)...min(photos.count - 1, currentIndex + preloadRange)
        return range.contains(index) || loadedIndices.contains(index)
    }
    
    private func updateLoadedPhotos() {
        // Mark photos in preload range for loading
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