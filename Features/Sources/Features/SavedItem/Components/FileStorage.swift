//
//  FileStorage.swift
//  STACK
//
//  Created by James Swent on 7/24/25.
//

import Foundation
import SwiftUI

public enum FileStorage {
    
    public enum StorageError: LocalizedError {
        case failedToCreateDirectory
        case failedToWriteFile
        case invalidImageData
        case failedToGenerateThumbnail
        
        public var errorDescription: String? {
            switch self {
            case .failedToCreateDirectory:
                return "Failed to create storage directory"
            case .failedToWriteFile:
                return "Failed to write file to disk"
            case .invalidImageData:
                return "Invalid image data provided"
            case .failedToGenerateThumbnail:
                return "Failed to generate thumbnail"
            }
        }
    }
    
    /// Saves image data to the Photos directory in Application Support
    /// - Parameters:
    ///   - data: The image data to save
    ///   - directory: The subdirectory name (default: "Photos")
    /// - Returns: URL of the saved file
    /// - Throws: StorageError if the operation fails
    public static func saveImageData(_ data: Data, directory: String = "Photos") throws -> URL {
        let baseURL = try getApplicationSupportDirectory()
        let photosURL = baseURL.appendingPathComponent(directory)
        
        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
        
        // Generate unique filename
        let filename = UUID().uuidString + ".jpg"
        let fileURL = photosURL.appendingPathComponent(filename)
        
        // Write data to file
        do {
            try data.write(to: fileURL)
        } catch {
            throw StorageError.failedToWriteFile
        }
        
        return fileURL
    }
    
    /// Generates a thumbnail from image data using SwiftUI's Image and ImageRenderer
    /// - Parameters:
    ///   - data: The original image data
    ///   - maxDimension: Maximum width/height for the thumbnail (default: 200)
    /// - Returns: Thumbnail image data as JPEG
    /// - Throws: StorageError if thumbnail generation fails
    @MainActor
    public static func generateThumbnail(from data: Data, maxDimension: CGFloat = 200) throws -> Data {
        #if canImport(UIKit)
        guard let uiImage = UIKit.UIImage(data: data) else {
            throw StorageError.invalidImageData
        }
        
        let originalSize = uiImage.size
        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
        
        // If image is already smaller than max dimension, return original
        if scale >= 1.0 {
            return data
        }
        
        let thumbnailSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
        let image = Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: thumbnailSize.width, height: thumbnailSize.height)
        
        let renderer = ImageRenderer(content: image)
        renderer.scale = 1.0
        
        guard let renderedImage = renderer.uiImage,
              let thumbnailData = renderedImage.jpegData(compressionQuality: 0.8) else {
            throw StorageError.failedToGenerateThumbnail
        }
        
        return thumbnailData
        
        #else
        // For macOS or other platforms, we might need a different approach
        throw StorageError.failedToGenerateThumbnail
        #endif
    }
    
    /// Saves thumbnail data to the specified directory
    /// - Parameters:
    ///   - data: The thumbnail data to save
    ///   - directory: The directory path (default: "Photos/Thumbnails")
    /// - Returns: URL of the saved thumbnail file
    /// - Throws: StorageError if the operation fails
    public static func saveThumbnailData(_ data: Data, directory: String = "Photos/Thumbnails") throws -> URL {
        return try saveImageData(data, directory: directory)
    }
    
    /// Deletes a file at the given URL
    /// - Parameter url: The file URL to delete
    /// - Throws: File system errors
    public static func deleteFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    /// Gets the Application Support directory URL
    /// - Returns: URL of the Application Support directory
    /// - Throws: StorageError if directory cannot be accessed
    private static func getApplicationSupportDirectory() throws -> URL {
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw StorageError.failedToCreateDirectory
        }
        return url
    }
}

// MARK: - Batch Operations

public extension FileStorage {
    
    /// Saves an image and generates its thumbnail in one operation
    /// - Parameters:
    ///   - data: The original image data
    ///   - maxThumbnailDimension: Maximum dimension for thumbnail
    /// - Returns: Tuple containing (imageURL, thumbnailURL)
    /// - Throws: StorageError if any operation fails
    @MainActor
    static func saveImageWithThumbnail(_ data: Data, maxThumbnailDimension: CGFloat = 200) throws -> (imageURL: URL, thumbnailURL: URL) {
        let imageURL = try saveImageData(data)
        let thumbnailData = try generateThumbnail(from: data, maxDimension: maxThumbnailDimension)
        let thumbnailURL = try saveThumbnailData(thumbnailData)
        
        return (imageURL, thumbnailURL)
    }
    
    /// Deletes both the image and thumbnail files for a photo
    /// - Parameters:
    ///   - imageURL: URL of the main image file
    ///   - thumbnailURL: URL of the thumbnail file
    static func deleteImageAndThumbnail(imageURL: URL, thumbnailURL: URL) {
        try? deleteFile(at: imageURL)
        try? deleteFile(at: thumbnailURL)
    }
}