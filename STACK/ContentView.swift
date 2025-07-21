//
//  ContentView.swift
//  STACK
//
//  Created by James Swent on 7/9/25.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showingAddSheet = false

    var body: some View {
        NavigationSplitView {
            SavedItemListView()
            .toolbar {
                // Add button on the left
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                // Edit button on the right
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSavedItemView()
            }
        } detail: {
            Text("Select an item")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedItem.self, inMemory: true)
}
