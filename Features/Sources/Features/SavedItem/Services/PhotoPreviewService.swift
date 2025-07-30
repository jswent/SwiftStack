//
//  PhotoPreviewService.swift
//  STACK
//
//  Created by James Swent on 7/30/25.
//

import SwiftUI
import QuickLook

/// Service responsible for presenting photo previews using QLPreviewController
@MainActor
public final class PhotoPreviewService: ObservableObject {
    @Published private(set) var isPresenting = false
    
    private var presentationController: UIViewController?
    private var previewItems: [PhotoPreviewItem] = []
    private var currentIndex: Int = 0
    
    nonisolated public init() {}
    
    /// Present a single photo in fullscreen
    public func presentPhoto(_ photo: Photo) {
        presentPhotos([photo], currentIndex: 0)
    }
    
    /// Present multiple photos with the ability to navigate between them
    public func presentPhotos(_ photos: [Photo], currentIndex: Int = 0) {
        guard !photos.isEmpty else { return }
        
        self.previewItems = photos.map(PhotoPreviewItem.init)
        self.currentIndex = max(0, min(currentIndex, photos.count - 1))
        self.isPresenting = true
        
        presentQLPreviewController()
    }
    
    private func presentQLPreviewController() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let previewController = QLPreviewController()
        let coordinator = PreviewCoordinator(items: previewItems, onDismiss: { [weak self] in
            self?.isPresenting = false
        })
        
        previewController.dataSource = coordinator
        previewController.delegate = coordinator
        previewController.currentPreviewItemIndex = currentIndex
        
        // Store references to prevent deallocation
        self.presentationController = previewController
        objc_setAssociatedObject(previewController, "coordinator", coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        rootViewController.present(previewController, animated: true)
    }
}

// MARK: - Coordinator

private final class PreviewCoordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    private let items: [PhotoPreviewItem]
    private let onDismiss: () -> Void
    
    init(items: [PhotoPreviewItem], onDismiss: @escaping () -> Void) {
        self.items = items
        self.onDismiss = onDismiss
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        items.count
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        items[index]
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        onDismiss()
    }
}

// MARK: - Preview Item

private final class PhotoPreviewItem: NSObject, QLPreviewItem {
    private let photo: Photo
    
    init(photo: Photo) {
        self.photo = photo
    }
    
    var previewItemURL: URL? {
        photo.fileURL
    }
    
    var previewItemTitle: String? {
        photo.savedItem?.title ?? "Photo"
    }
}