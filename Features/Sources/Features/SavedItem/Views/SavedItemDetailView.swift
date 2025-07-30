//
//  SavedItemDetailView.swift
//  STACK
//
//  Created by James Swent on 7/12/25.
//

import Core
import SwiftUI
import SwiftData

/// A detail view to display and inline-edit a SavedItem's details
public struct SavedItemDetailView: View {
    public enum NavigationTarget {
        case editItem(SavedItem)
    }
    @Bindable var item: SavedItem
    @State private var showingEditSheet = false
    
    let onNavigation: (NavigationTarget) -> Void
    
    public init(item: SavedItem, onNavigation: @escaping (NavigationTarget) -> Void) {
        self.item = item
        self.onNavigation = onNavigation
    }


    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title + date
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(item.createdAt.prettyFormatted)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Link preview, shown only if there's a URL
                if let url = item.url {
                    LinkPreview(url: url)
                        .frame(minHeight: 80)
                        .cornerRadius(8)
                }

                // Photo carousel, shown only if there are photos
                if !item.photos.isEmpty {
                    PhotoCarouselView(photos: item.photos)
                }

                // Notes binding and expanding text view
                let notesBinding = Binding(
                    get: { item.notes ?? "" },
                    set: { newValue in
                        item.notes = newValue.isEmpty ? nil : newValue
                        item.lastEdited = Date()
                    }
                )

//                ExpandingTextView(
//                    text: notesBinding,
//                    placeholder: "Add notes..."
//                )
//                .frame(minHeight: 50)
                
                TextEditorView(text: notesBinding, placeholder: "Add notes...")
                    .frame(minHeight: 50)
            }
            .padding()
        }
        .onTapGesture {
            hideKeyboard()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    onNavigation(.editItem(item))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SavedItemDetailView(item: .mock, onNavigation: { _ in })
            .modelContainer(for: SavedItem.self, inMemory: true)
    }
}
