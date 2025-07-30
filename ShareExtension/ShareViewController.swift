//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by James Swent on 7/22/25.
//

import UIKit
import SwiftUI
import SwiftData
import SavedItem
import LinkPresentation
import UniformTypeIdentifiers
import OSLog

@objc(ShareViewController)
class ShareViewController: UIViewController {
    private let logger = Logger(subsystem: "ShareExtension", category: "ViewController")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("ShareViewController viewDidLoad started")
        
        // Extract shared content from extension context
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            logger.error("No extension item or attachments found")
            close()
            return
        }
        
        logger.info("Found \(attachments.count) attachments")
        
        // Look for URL or JavaScript results
        processAttachments(attachments) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.showSwiftUIView(with: data)
                case .failure(let error):
                    self?.logger.error("Failed to process attachments: \(error.localizedDescription)")
                    self?.close()
                }
            }
        }
        
        // Listen for close notification from SwiftUI view
        NotificationCenter.default.addObserver(forName: NSNotification.Name("closeShareExtension"), object: nil, queue: nil) { _ in
            self.logger.info("Received close notification from SwiftUI view")
            DispatchQueue.main.async {
                self.close()
            }
        }
    }
    
    private func processAttachments(_ attachments: [NSItemProvider], completion: @escaping (Result<ShareData, Error>) -> Void) {
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
    
    private func processImages(from providers: [NSItemProvider], completion: @escaping ([Data]) -> Void) {
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
    
    private func processWebContent(from attachments: [NSItemProvider], completion: @escaping (Result<(title: String, url: String, notes: String), Error>) -> Void) {
        // First try JavaScript preprocessing results
        let propertyListProvider = attachments.first { $0.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) }
        
        if let provider = propertyListProvider {
            provider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { item, error in
                if let plistDict = item as? [String: Any],
                   let jsResults = plistDict["NSExtensionJavaScriptPreprocessingResultsKey"] as? [String: Any] {
                    let result = (
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
    
    private func tryWebURLFallback(attachments: [NSItemProvider], completion: @escaping (Result<(title: String, url: String, notes: String), Error>) -> Void) {
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
                let result = (
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
    
    private func showSwiftUIView(with data: ShareData) {
        logger.info("Showing SwiftUI view with data: title='\(data.title)', url='\(data.url)', photos=\(data.photos.count)")
        
        let contentView = UIHostingController(
            rootView: ShareExtensionView(shareData: data)
                .modelContainer(SharedModelContainer.container)
        )
        
        addChild(contentView)
        view.addSubview(contentView.view)
        
        // Set up constraints
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        
        contentView.didMove(toParent: self)
    }
    
    /// Close the Share Extension
    func close() {
        logger.info("Closing share extension")
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// MARK: - Share Data Model

struct ShareData {
    let title: String
    let url: String
    let notes: String
    let photos: [Data]
}

// MARK: - Errors

enum ShareExtensionError: LocalizedError {
    case noInputItems
    case noValidURL
    case invalidURL
    case invalidJavaScriptResults
    case timeout
    case noValidContent
    
    var errorDescription: String? {
        switch self {
        case .noInputItems:
            return "No content was shared"
        case .noValidURL:
            return "No valid URL found in shared content"
        case .invalidURL:
            return "The shared URL is invalid"
        case .invalidJavaScriptResults:
            return "Could not process shared web page"
        case .timeout:
            return "Request timed out"
        case .noValidContent:
            return "No valid content found to share"
        }
    }
}

// MARK: - SwiftUI View for Share Extension

struct ShareExtensionView: View {
    let shareData: ShareData
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ShareExtensionFormView(shareData: shareData)
            .onReceive(NotificationCenter.default.publisher(for: .savedItemCreated)) { _ in
                completeExtension()
            }
    }
    
    private func cancelExtension() {
        print("DEBUG: Cancel button tapped, posting close notification")
        NotificationCenter.default.post(name: NSNotification.Name("closeShareExtension"), object: nil)
    }
    
    private func completeExtension() {
        print("DEBUG: Completing extension")
        NotificationCenter.default.post(name: NSNotification.Name("closeShareExtension"), object: nil)
    }
}

struct ShareExtensionFormView: View {
    let shareData: ShareData
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String
    @State private var urlString: String
    @State private var notes: String
    @State private var photos: [Photo] = []
    @State private var isProcessingPhotos = false
    
    init(shareData: ShareData) {
        self.shareData = shareData
        self._title = State(initialValue: shareData.title)
        self._urlString = State(initialValue: shareData.url)
        self._notes = State(initialValue: shareData.notes)
    }
    
    var body: some View {
        NavigationView {
            SavedItemFormView(
                title: $title,
                urlString: $urlString,
                notes: $notes,
                photos: photos,
                onAddPhotos: { _ in }, // Disable adding new photos in share extension
                onDeletePhoto: deletePhoto,
                onCancel: cancelExtension,
                onSave: saveAndComplete
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: cancelExtension)
                        .font(.body)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: saveAndComplete)
                        .font(.body.weight(.semibold))
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .task {
                await processSharedPhotos()
            }
        }
    }
    
    @MainActor
    private func processSharedPhotos() async {
        guard !shareData.photos.isEmpty, photos.isEmpty else { return }
        
        isProcessingPhotos = true
        defer { isProcessingPhotos = false }
        
        for photoData in shareData.photos {
            do {
                let (imagePath, thumbnailPath) = try FileStorage.saveImageWithThumbnail(photoData)
                let photo = Photo(filePath: imagePath, thumbnailPath: thumbnailPath)
                
                modelContext.insert(photo)
                photos.append(photo)
                
                // Cache the images asynchronously for immediate display
                Task.detached {
                    await self.cacheImagesForPhoto(originalData: photoData, photo: photo)
                }
            } catch {
                print("Error saving photo in share extension: \(error)")
            }
        }
    }
    
    private func cacheImagesForPhoto(originalData: Data, photo: Photo) async {
        guard let fullImage = UIImage(data: originalData) else { return }
        
        // Cache full image on main actor
        await MainActor.run {
            PhotoPreviewCache.shared.setFullImage(fullImage, for: photo.id)
        }
        
        // Generate and cache thumbnail if needed
        do {
            let thumbnailData = try await MainActor.run {
                try FileStorage.generateThumbnail(from: originalData)
            }
            if let thumbnailImage = UIImage(data: thumbnailData) {
                await MainActor.run {
                    PhotoPreviewCache.shared.setThumbnail(thumbnailImage, for: photo.id)
                }
            }
        } catch {
            print("Error generating thumbnail for cache: \(error)")
        }
    }
    
    private func deletePhoto(_ photo: Photo) {
        // Remove from local array
        if let index = photos.firstIndex(of: photo) {
            photos.remove(at: index)
        }
        
        // Delete files from disk
        FileStorage.deleteImageAndThumbnail(
            imagePath: photo.filePath,
            thumbnailPath: photo.thumbnailPath
        )
        
        // Invalidate cache
        PhotoPreviewCache.shared.removeImages(for: photo.id)
        
        // Delete from SwiftData
        modelContext.delete(photo)
    }
    
    private func cancelExtension() {
        print("DEBUG: Cancel button tapped in share extension")
        NotificationCenter.default.post(name: NSNotification.Name("closeShareExtension"), object: nil)
    }
    
    private func saveAndComplete() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = trimmed.isEmpty ? nil : URL(string: trimmed)

        let newItem = SavedItem(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            url: url
        )
        
        // Link all photos to the new item and mark them as linked
        newItem.photos = photos
        for photo in photos {
            photo.savedItem = newItem
            photo.isLinked = true
        }
        
        modelContext.insert(newItem)
        
        // Ensure save is called before closing extension
        Task {
            do {
                try await modelContext.save()
                print("DEBUG: Successfully saved item to shared container")
                
                // Post local notification for coordination
                NotificationCenter.default.post(name: .savedItemCreated, object: newItem)
                
                // Post Darwin notification to wake up main app
                postDarwinNotification()
                
                // Only close after successful save
                await MainActor.run {
                    print("DEBUG: Item saved, closing extension")
                    NotificationCenter.default.post(name: NSNotification.Name("closeShareExtension"), object: nil)
                }
            } catch {
                print("ERROR: Failed to save item in share extension: \(error)")
                // Still close the extension to avoid hanging
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("closeShareExtension"), object: nil)
                }
            }
        }
    }
    
    private func postDarwinNotification() {
        let notificationName = "com.jswent.STACK.shareDidSave"
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName as CFString),
            nil,
            nil,
            true
        )
        print("DEBUG: Posted Darwin notification: \(notificationName)")
    }
}


// MARK: - Shared Model Container

enum SharedModelContainer {
    static let container: ModelContainer = {
        let schema = Schema([SavedItem.self])
        let configuration = ModelConfiguration(
            schema: schema,
            allowsSave: true,
            groupContainer: .identifier("group.com.jswent.STACK")
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()
}

// MARK: - Notification Extension

extension Notification.Name {
    static let savedItemCreated = Notification.Name("savedItemCreated")
}
