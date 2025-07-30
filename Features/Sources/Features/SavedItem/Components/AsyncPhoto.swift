//
//  AsyncPhoto.swift
//  STACK
//
//  Created by James Swent on 7/30/25.
//

import SwiftUI

public struct AsyncPhoto<Content: View, Placeholder: View>: View {
    public enum Phase {
        case loading
        case success(Image)
        case failure
    }
    
    private let photo: Photo?
    private let scaledSize: CGSize?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var phase: Phase = .loading
    
    public init(
        photo: Photo?,
        scaledSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.photo = photo
        self.scaledSize = scaledSize
        self.content = content
        self.placeholder = placeholder
    }
    
    public var body: some View {
        switch phase {
        case .loading:
            placeholder()
                .onAppear {
                    loadImage()
                }
        case .success(let image):
            content(image)
        case .failure:
            placeholder()
        }
    }
    
    private func loadImage() {
        guard let photo = photo else {
            phase = .failure
            return
        }
        
        Task {
            // Try cache first
            if let cachedImage = tryLoadFromCache(photo: photo) {
                let image = Image(uiImage: cachedImage)
                await MainActor.run {
                    phase = .success(image)
                }
                return
            }
            
            // Fall back to file loading
            guard let url = photo.fileURL else {
                await MainActor.run { phase = .failure }
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                
                let uiImage: UIImage
                if let scaledSize = scaledSize {
                    uiImage = try await scaleImage(data: data, to: scaledSize)
                } else {
                    guard let originalImage = UIImage(data: data) else {
                        await MainActor.run { phase = .failure }
                        return
                    }
                    uiImage = originalImage
                }
                
                // Cache the loaded image
                cacheLoadedImage(uiImage, for: photo)
                
                let image = Image(uiImage: uiImage)
                await MainActor.run {
                    phase = .success(image)
                }
            } catch {
                await MainActor.run {
                    phase = .failure
                }
            }
        }
    }
    
    private func tryLoadFromCache(photo: Photo) -> UIImage? {
        let cache = PhotoPreviewCache.shared
        // Always try full image first for better quality
        return cache.getFullImage(for: photo.id) ?? cache.getThumbnail(for: photo.id)
    }
    
    private func cacheLoadedImage(_ image: UIImage, for photo: Photo) {
        Task { @MainActor in
            let cache = PhotoPreviewCache.shared
            // Cache as full image (the scaledSize handling is done separately)
            cache.setFullImage(image, for: photo.id)
        }
    }
    
    @MainActor
    private func scaleImage(data: Data, to size: CGSize) async throws -> UIImage {
        guard let originalImage = UIImage(data: data) else {
            throw AsyncPhotoError.invalidImageData
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            originalImage.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

public enum AsyncPhotoError: Error {
    case invalidImageData
}

// Convenience initializer with default placeholder
public extension AsyncPhoto where Placeholder == AnyView {
    init(
        photo: Photo?,
        scaledSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            photo: photo,
            scaledSize: scaledSize,
            content: content,
            placeholder: {
                AnyView(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                )
            }
        )
    }
}