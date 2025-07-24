//
//  SavedItemFormView.swift
//  STACK
//
//  Created by James Swent on 7/12/25.
//

import Core
import SwiftUI
import SwiftData
import Foundation
import PhotosUI

/// A generic form for creating or editing a SavedItem, with live link preview.
public struct SavedItemFormView: View {
    @Binding var title: String
    @Binding var urlString: String
    @Binding var notes: String
    let photos: [Photo]
    let onAddPhotos: ([Data]) async -> Void
    let onDeletePhoto: (Photo) -> Void
    let onCancel: () -> Void
    let onSave: () -> Void
    
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isProcessingPhotos = false
    @State private var showingDeleteConfirmation = false
    @State private var photoToDelete: Photo?
    
    public init(
        title: Binding<String>,
        urlString: Binding<String>,
        notes: Binding<String>,
        photos: [Photo] = [],
        onAddPhotos: @escaping ([Data]) async -> Void = { _ in },
        onDeletePhoto: @escaping (Photo) -> Void = { _ in },
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self._title = title
        self._urlString = urlString
        self._notes = notes
        self.photos = photos
        self.onAddPhotos = onAddPhotos
        self.onDeletePhoto = onDeletePhoto
        self.onCancel = onCancel
        self.onSave = onSave
    }

    /// Show "New Item" when title is blank, otherwise show the title.
    private var navTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "New Item" : trimmed
    }

    /// Trim whitespace for URL parsing.
    private var trimmedURL: String {
        urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Convert to URL if valid and non-empty.
    private var previewURL: URL? {
        guard !trimmedURL.isEmpty,
              let url = URL(string: trimmedURL)
        else { return nil }
        return url
    }

    public var body: some View {
        Form {
            Section("Title") {
                TextField("Enter title", text: $title)
            }

            Section("URL") {
                TextField("Enter URL", text: $urlString)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }

            // Live link preview under the URL field
            if let url = previewURL {
                    LinkPreview(url: url)
                        .frame(minHeight: 80)
                        .cornerRadius(8)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
            
            Section("Photos") {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 0, // unlimited
                    matching: .images
                ) {
                    Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                }
                .disabled(isProcessingPhotos)
                
                if !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(photos, id: \.id) { photo in
                                PhotoThumbnailView(photo: photo) {
                                    photoToDelete = photo
                                    showingDeleteConfirmation = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                if isProcessingPhotos {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing photos...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(navTitle)
        .onChange(of: pickerItems) { _, items in
            Task {
                await processPhotoItems(items)
            }
        }
        .confirmationDialog(
            "Delete Photo",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let photo = photoToDelete {
                    onDeletePhoto(photo)
                    photoToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                photoToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }
    
    @MainActor
    private func processPhotoItems(_ items: [PhotosPickerItem]) async {
        isProcessingPhotos = true
        defer { isProcessingPhotos = false }
        
        var photoDataArray: [Data] = []
        
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    continue
                }
                photoDataArray.append(data)
            } catch {
                print("Error loading photo data: \(error)")
            }
        }
        
        if !photoDataArray.isEmpty {
            await onAddPhotos(photoDataArray)
        }
        
        // Clear the picker selection
        pickerItems = []
    }
}

// MARK: - Photo Thumbnail View

private struct PhotoThumbnailView: View {
    let photo: Photo
    let onDelete: () -> Void
    
    var body: some View {
        VStack {
            AsyncImage(url: photo.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6), in: Circle())
                }
                .offset(x: 4, y: -4)
            }
            .padding(.vertical, 4)
        }
    }
}

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
                let (imageURL, thumbnailURL) = try FileStorage.saveImageWithThumbnail(data)
                let photo = Photo(fileURL: imageURL, thumbnailURL: thumbnailURL)
                
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
            imageURL: photo.fileURL,
            thumbnailURL: photo.thumbnailURL
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
                let (imageURL, thumbnailURL) = try FileStorage.saveImageWithThumbnail(data)
                let photo = Photo(fileURL: imageURL, thumbnailURL: thumbnailURL)
                
                // Link to the existing item immediately and mark as linked
                photo.savedItem = item
                photo.isLinked = true
                
                modelContext.insert(photo)
                item.photos.append(photo)
            } catch {
                print("Error saving photo: \(error)")
            }
        }
    }
    
    private func deletePhoto(_ photo: Photo) {
        // Remove from the item's photos
        if let index = item.photos.firstIndex(of: photo) {
            item.photos.remove(at: index)
        }
        
        // Delete files from disk
        FileStorage.deleteImageAndThumbnail(
            imageURL: photo.fileURL,
            thumbnailURL: photo.thumbnailURL
        )
        
        // Delete from SwiftData
        modelContext.delete(photo)
    }

    private func finalizeEdit() {
        item.lastEdited = Date()
        dismiss()
    }
}

#Preview("Add and Edit SavedItemFormView") {
    let schema = Schema([SavedItem.self, Photo.self])
    let container = try! ModelContainer(for: schema)
    AddSavedItemView()
        .modelContainer(container)
    EditSavedItemView(item: SavedItem(title: "Example", notes: "Note", url: URL(string: "https://example.com")))
        .modelContainer(container)
}

// MARK: - Notification Extension

public extension Notification.Name {
    static let savedItemCreated = Notification.Name("savedItemCreated")
}
