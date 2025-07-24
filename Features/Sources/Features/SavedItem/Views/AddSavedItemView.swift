//
//  AddSavedItemView.swift
//  Features
//
//  Created by James Swent on 7/24/25.
//

import SwiftUI
import SwiftData
import Foundation

/// A view for adding a new SavedItem.
public struct AddSavedItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var urlString: String
    @State private var notes: String
    @State private var photos: [Photo] = []
    
    public init(initialTitle: String = "", initialURL: String = "", initialNotes: String = "") {
        _title = State(initialValue: initialTitle)
        _urlString = State(initialValue: initialURL)
        _notes = State(initialValue: initialNotes)
    }

    public var body: some View {
        NavigationView {
            SavedItemFormView(
                title: $title,
                urlString: $urlString,
                notes: $notes,
                photos: photos,
                onAddPhotos: addPhotos,
                onDeletePhoto: deletePhoto,
                onCancel: { dismiss() },
                onSave: saveAndDismiss
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: saveAndDismiss)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                
                modelContext.insert(photo)
                photos.append(photo)
            } catch {
                print("Error saving photo: \(error)")
            }
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
        
        // Delete from SwiftData
        modelContext.delete(photo)
    }

    private func saveAndDismiss() {
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
        
        // Post notification for share extension coordination
        NotificationCenter.default.post(name: .savedItemCreated, object: newItem)
        
        dismiss()
    }
}
