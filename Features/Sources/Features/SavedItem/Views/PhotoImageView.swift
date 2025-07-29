//
//  PhotoImageView.swift
//  STACK
//
//  Created by James Swent on 7/29/25.
//

import SwiftUI

public struct PhotoImageView: View {
    let photo: Photo
    let maxHeight: CGFloat
    
    public init(photo: Photo, maxHeight: CGFloat = 300) {
        self.photo = photo
        self.maxHeight = maxHeight
    }
    
    public var body: some View {
        AsyncImage(url: photo.fileURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: maxHeight)
            case .failure(_):
                // Fallback to thumbnail on main image failure
                AsyncImage(url: photo.thumbnailURL) { thumbnailPhase in
                    switch thumbnailPhase {
                    case .success(let thumbnailImage):
                        thumbnailImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: maxHeight)
                    case .failure(_):
                        // Final fallback for both image failures
                        errorPlaceholder
                    case .empty:
                        loadingPlaceholder
                    @unknown default:
                        errorPlaceholder
                    }
                }
            case .empty:
                loadingPlaceholder
            @unknown default:
                errorPlaceholder
            }
        }
        .cornerRadius(8)
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