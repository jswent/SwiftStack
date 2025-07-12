//
//  SavedItemFormView.swift
//  STACK
//
//  Created by James Swent on 7/12/25.
//

import SwiftUI
import SwiftData

/// A generic form for creating or editing a SavedItem, with live link preview.
struct SavedItemFormView: View {
    @Binding var title: String
    @Binding var urlString: String
    @Binding var notes: String

    let onCancel: () -> Void
    let onSave: () -> Void

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

    var body: some View {
        NavigationView {
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
                    Section {
                        LinkPreview(url: url)
                            .frame(minHeight: 80)
                            .cornerRadius(8)
                            .listRowBackground(Color.clear)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(navTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: onSave)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

/// A view for adding a new SavedItem.
struct AddSavedItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var urlString: String = ""
    @State private var notes: String = ""

    var body: some View {
        SavedItemFormView(
            title: $title,
            urlString: $urlString,
            notes: $notes,
            onCancel: { dismiss() },
            onSave: saveAndDismiss
        )
    }

    private func saveAndDismiss() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = trimmed.isEmpty ? nil : URL(string: trimmed)

        let newItem = SavedItem(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            url: url
        )
        modelContext.insert(newItem)
        dismiss()
    }
}

/// A view for editing an existing SavedItem.
struct EditSavedItemView: View {
    @Bindable var item: SavedItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

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

    var body: some View {
        SavedItemFormView(
            title: $item.title,
            urlString: urlString,
            notes: notesString,
            onCancel: { dismiss() },
            onSave: finalizeEdit
        )
    }

    private func finalizeEdit() {
        item.lastEdited = Date()
        dismiss()
    }
}

#Preview("Add and Edit SavedItemFormView") {
    let schema = Schema([SavedItem.self])
    let container = try! ModelContainer(for: schema)
    AddSavedItemView()
        .modelContainer(container)
    EditSavedItemView(item: SavedItem(title: "Example", notes: "Note", url: URL(string: "https://example.com")))
        .modelContainer(container)
}
