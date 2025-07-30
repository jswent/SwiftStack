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
    
    private let url: URL?
    private let scaledSize: CGSize?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var phase: Phase = .loading
    
    public init(
        url: URL?,
        scaledSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
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
        guard let url = url else {
            phase = .failure
            return
        }
        
        Task {
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
        url: URL?,
        scaledSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
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