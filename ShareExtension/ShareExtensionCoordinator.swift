//
//  ShareExtensionCoordinator.swift
//  ShareExtension
//
//  Created by James Swent on 7/30/25.
//

import SwiftUI
import SwiftData
import SavedItem
import OSLog

// MARK: - Protocol

protocol ShareExtensionCoordinating: AnyObject {
    func presentShareInterface(with data: ShareData)
    func closeExtension()
}

// MARK: - Implementation

@MainActor
final class ShareExtensionCoordinator: ObservableObject, ShareExtensionCoordinating {
    weak var viewController: ShareViewController?
    private let logger = Logger(subsystem: "ShareExtension", category: "Coordinator")
    
    init(viewController: ShareViewController) {
        self.viewController = viewController
        
        // Listen for close notification from SwiftUI view
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("closeShareExtension"), 
            object: nil, 
            queue: nil
        ) { _ in
            Task { @MainActor in
                self.closeExtension()
            }
        }
    }
    
    func presentShareInterface(with data: ShareData) {
        logger.info("Presenting share interface with data: title='\(data.title)', url='\(data.url)', photos=\(data.photos.count)")
        
        guard let viewController = viewController else {
            logger.error("ViewController is nil when trying to present share interface")
            return
        }
        
        let contentView = UIHostingController(
            rootView: ShareExtensionView(shareData: data, coordinator: self)
                .modelContainer(SharedModelContainer.container)
        )
        
        viewController.addChild(contentView)
        viewController.view.addSubview(contentView.view)
        
        // Set up constraints
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            contentView.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            contentView.view.leftAnchor.constraint(equalTo: viewController.view.leftAnchor),
            contentView.view.rightAnchor.constraint(equalTo: viewController.view.rightAnchor)
        ])
        
        contentView.didMove(toParent: viewController)
    }
    
    func closeExtension() {
        logger.info("Closing share extension")
        viewController?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// MARK: - SwiftUI Views

struct ShareExtensionView: View {
    let shareData: ShareData
    let coordinator: ShareExtensionCoordinator
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ShareExtensionFormView(shareData: shareData, coordinator: coordinator)
            .onReceive(NotificationCenter.default.publisher(for: .savedItemCreated)) { _ in
                coordinator.closeExtension()
            }
    }
}

struct ShareExtensionFormView: View {
    let shareData: ShareData
    let coordinator: ShareExtensionCoordinator
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String
    @State private var urlString: String
    @State private var notes: String
    @State private var photos: [Photo] = []
    @State private var isProcessingPhotos = false
    
    init(shareData: ShareData, coordinator: ShareExtensionCoordinator) {
        self.shareData = shareData
        self.coordinator = coordinator
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
                onCancel: coordinator.closeExtension,
                onSave: saveAndComplete
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: coordinator.closeExtension)
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
}

// MARK: - Private Methods

private extension ShareExtensionFormView {
    
    @MainActor
    func processSharedPhotos() async {
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
    
    func cacheImagesForPhoto(originalData: Data, photo: Photo) async {
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
    
    func deletePhoto(_ photo: Photo) {
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
    
    func saveAndComplete() {
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
                    coordinator.closeExtension()
                }
            } catch {
                print("ERROR: Failed to save item in share extension: \(error)")
                // Still close the extension to avoid hanging
                await MainActor.run {
                    coordinator.closeExtension()
                }
            }
        }
    }
    
    func postDarwinNotification() {
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
        let configuration = ModelConfiguration(
            allowsSave: true,
            groupContainer: .identifier("group.com.jswent.STACK")
        )
        
        do {
            return try ModelContainer(
                for: SavedItem.self, Photo.self,
                migrationPlan: SavedItemMigrationPlan.self,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()
}

// MARK: - Notification Extension

public extension Notification.Name {
    static let savedItemCreated = Notification.Name("savedItemCreated")
}