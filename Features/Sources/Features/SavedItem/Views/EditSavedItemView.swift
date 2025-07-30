//
//  EditSavedItemView.swift
//  Features
//
//  Created by James Swent on 7/24/25.
//

import SwiftUI
import SwiftData

/// A view for editing an existing SavedItem.
public struct EditSavedItemView: View {
    @Bindable var item: SavedItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    public init(item: SavedItem) {
        self.item = item
    }

    /// Two-way binding to string for the URL property.
    private var urlString: Binding<String> {
        Binding(
            get: { item.url?.absoluteString ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                item.url = trimmed.isEmpty ? nil : URL(string: trimmed)
            }
        )
    }

    /// Two-way binding to string for notes property.
    private var notesString: Binding<String> {
        Binding(
            get: { item.notes ?? "" },
            set: { item.notes = $0.isEmpty ? nil : $0 }
        )
    }

    public var body: some View {
        NavigationView {
            SavedItemFormView(
                title: $item.title,
                urlString: urlString,
                notes: notesString,
                photos: item.photos,
                onAddPhotos: addPhotos,
                onDeletePhoto: deletePhoto,
                onCancel: { dismiss() },
                onSave: finalizeEdit
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: finalizeEdit)
                        .disabled(item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    @MainActor
    private func addPhotos(_ photoDataArray: [Data]) async {
        for data in photoDataArray {
            do {
                let (imagePath, thumbnailPath) = try FileStorage.saveImageWithThumbnail(data)
                let photo = Photo(filePath: imagePath, thumbnailPath: thumbnailPath)
                
                // Link to the existing item immediately and mark as linked
                photo.savedItem = item
                photo.isLinked = true
                
                modelContext.insert(photo)
                item.photos.append(photo)
                
                // Cache the images asynchronously for immediate display
                Task.detached {
                    await self.cacheImagesForPhoto(originalData: data, photo: photo)
                }
            } catch {
                print("Error saving photo: \(error)")
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
        // Remove from the item's photos
        if let index = item.photos.firstIndex(of: photo) {
            item.photos.remove(at: index)
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

    private func finalizeEdit() {
        item.lastEdited = Date()
        dismiss()
    }
}
