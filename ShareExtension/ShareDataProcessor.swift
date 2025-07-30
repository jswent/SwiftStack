//
//  ShareDataProcessor.swift
//  ShareExtension
//
//  Created by James Swent on 7/30/25.
//

import Foundation
import UniformTypeIdentifiers
import OSLog
import SwiftUI

// MARK: - Protocol

protocol ShareDataProcessing {
    func processAttachments(
        _ attachments: [NSItemProvider], 
        completion: @escaping (Result<ShareData, Error>) -> Void
    )
}

// MARK: - Implementation

final class ShareDataProcessor: ShareDataProcessing {
    private let logger = Logger(subsystem: "ShareExtension", category: "DataProcessor")
    
    func processAttachments(
        _ attachments: [NSItemProvider], 
        completion: @escaping (Result<ShareData, Error>) -> Void
    ) {
        let group = DispatchGroup()
        
        // Collect all content types
        var shareTitle = ""
        var shareURL = ""
        var shareNotes = ""
        var sharePhotos: [Data] = []
        var hasWebContent = false
        var processingError: Error?
        
        // Process images if present
        let imageProviders = attachments.filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }
        if !imageProviders.isEmpty {
            group.enter()
            processImages(from: imageProviders) { photos in
                sharePhotos = photos
                group.leave()
            }
        }
        
        // Process web content (JavaScript preprocessing or URL)
        group.enter()
        processWebContent(from: attachments) { result in
            switch result {
            case .success(let webData):
                shareTitle = webData.title
                shareURL = webData.url
                shareNotes = webData.notes
                hasWebContent = true
            case .failure(let error):
                if imageProviders.isEmpty {
                    // Only set error if we have no images to fall back on
                    processingError = error
                }
            }
            group.leave()
        }
        
        // Complete when all processing is done
        group.notify(queue: .main) {
            if let error = processingError, sharePhotos.isEmpty {
                completion(.failure(error))
            } else if !hasWebContent && sharePhotos.isEmpty {
                completion(.failure(ShareExtensionError.noValidContent))
            } else {
                let data = ShareData(
                    title: shareTitle,
                    url: shareURL,
                    notes: shareNotes,
                    photos: sharePhotos
                )
                completion(.success(data))
            }
        }
    }
}

// MARK: - Private Methods

private extension ShareDataProcessor {
    
    func processImages(from providers: [NSItemProvider], completion: @escaping ([Data]) -> Void) {
        let group = DispatchGroup()
        var collectedPhotos: [Data] = []
        
        logger.info("Processing \(providers.count) image attachments")
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                defer { group.leave() }
                
                if let error = error {
                    self.logger.error("Error loading image: \(error.localizedDescription)")
                    return
                }
                
                var imageData: Data?
                
                // Handle different data types (following iOS best practices)
                if let data = item as? Data {
                    imageData = data
                } else if let url = item as? URL {
                    imageData = try? Data(contentsOf: url)
                } else if let image = item as? UIImage {
                    imageData = image.pngData()
                }
                
                if let data = imageData {
                    collectedPhotos.append(data)
                    self.logger.info("Successfully processed image data (\(data.count) bytes)")
                } else {
                    self.logger.error("Failed to extract image data from item")
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(collectedPhotos)
        }
    }
    
    func processWebContent(from attachments: [NSItemProvider], completion: @escaping (Result<WebContentResult, Error>) -> Void) {
        // First try JavaScript preprocessing results
        let propertyListProvider = attachments.first { $0.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) }
        
        if let provider = propertyListProvider {
            provider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { item, error in
                if let plistDict = item as? [String: Any],
                   let jsResults = plistDict["NSExtensionJavaScriptPreprocessingResultsKey"] as? [String: Any] {
                    let result = WebContentResult(
                        title: jsResults["title"] as? String ?? "",
                        url: jsResults["url"] as? String ?? "",
                        notes: jsResults["description"] as? String ?? ""
                    )
                    completion(.success(result))
                    return
                }
                
                // If JavaScript processing fails, try URL fallback
                self.tryWebURLFallback(attachments: attachments, completion: completion)
            }
            return
        }
        
        // No JavaScript preprocessing, try URL fallback directly
        tryWebURLFallback(attachments: attachments, completion: completion)
    }
    
    func tryWebURLFallback(attachments: [NSItemProvider], completion: @escaping (Result<WebContentResult, Error>) -> Void) {
        let urlProvider = attachments.first { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }
        
        guard let provider = urlProvider else {
            completion(.failure(ShareExtensionError.noValidURL))
            return
        }
        
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let url = item as? URL {
                let result = WebContentResult(
                    title: "",
                    url: url.absoluteString,
                    notes: ""
                )
                completion(.success(result))
            } else {
                completion(.failure(ShareExtensionError.invalidURL))
            }
        }
    }
}
