//
//  PhotoImageView.swift
//  STACK
//
//  Created by James Swent on 7/29/25.
//

import SwiftUI

public struct PhotoImageView: View {
    private let photo: Photo
    private let maxHeight: CGFloat
    private let allPhotos: [Photo]?
    
    @Environment(\.photoPreviewService) private var previewService
    
    public init(photo: Photo, maxHeight: CGFloat = 300, allPhotos: [Photo]? = nil) {
        self.photo = photo
        self.maxHeight = maxHeight
        self.allPhotos = allPhotos
    }
    
    public var body: some View {
        AsyncPhoto(photo: photo) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: maxHeight)
        } placeholder: {
            loadingPlaceholder
        }
        .id(photo.id)
        .cornerRadius(8)
        .onTapGesture {
            presentPhoto()
        }
    }
    
    private func presentPhoto() {
        if let allPhotos = allPhotos,
           let currentIndex = allPhotos.firstIndex(where: { $0.id == photo.id }) {
            previewService.presentPhotos(allPhotos, currentIndex: currentIndex)
        } else {
            previewService.presentPhoto(photo)
        }
    }
    
    private var loadingPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(height: min(200, maxHeight))
            .overlay {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
    }
    
    private var errorPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.red.opacity(0.1))
            .frame(height: min(200, maxHeight))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text("Image unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
    }
}

#Preview {
    VStack(spacing: 16) {
        PhotoImageView(photo: .mock)
        PhotoImageView(photo: .mock, maxHeight: 150)
    }
    .padding()
}