//
//  ContentView.swift
//  STACK
//
//  Created by James Swent on 7/9/25.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\SavedItem.lastEdited, order: .reverse)]) private var items: [SavedItem]
    @State private var showingAddSheet = false

    // Group items into Today, Yesterday, Previous 7 Days, Previous 30 Days,
    // then by month (current year only) and by year for older items.
    private var groupedItems: [(String, [SavedItem])] {
        let calendar = Calendar.current
        let now = Date()
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now),
              let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)
        else { return [] }

        var buckets: [String: [SavedItem]] = [:]
        var olderCurrentYear: [SavedItem] = []
        var olderPriorYears: [SavedItem] = []

        for item in items {
            let date = item.lastEdited
            if calendar.isDateInToday(date) {
                buckets["Today", default: []].append(item)
            } else if calendar.isDateInYesterday(date) {
                buckets["Yesterday", default: []].append(item)
            } else if date >= sevenDaysAgo {
                buckets["Previous 7 Days", default: []].append(item)
            } else if date >= thirtyDaysAgo {
                buckets["Previous 30 Days", default: []].append(item)
            } else {
                let year = calendar.component(.year, from: date)
                let currentYear = calendar.component(.year, from: now)
                if year == currentYear {
                    olderCurrentYear.append(item)
                } else {
                    olderPriorYears.append(item)
                }
            }
        }

        // Month grouping for current year items
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "LLLL"
        for item in olderCurrentYear {
            let month = monthFormatter.string(from: item.lastEdited)
            buckets[month, default: []].append(item)
        }

        // Year grouping for prior-year items
        for item in olderPriorYears {
            let yearString = String(calendar.component(.year, from: item.lastEdited))
            buckets[yearString, default: []].append(item)
        }

        // Build ordered result
        var result: [(String, [SavedItem])] = []
        let fixedOrder = ["Today", "Yesterday", "Previous 7 Days", "Previous 30 Days"]
        // Fixed buckets
        for key in fixedOrder {
            if let list = buckets[key] {
                result.append((key, list))
            }
        }
        
        // Month sections in current-year order (reverse calendar order)
        // Unwrap optional monthSymbols safely
        let monthNames = monthFormatter.monthSymbols ?? []
        for month in monthNames.reversed() {
            if let list = buckets[month] {
                result.append((month, list))
            }
        }
        
        // Year sections descending
        let yearKeys = buckets.keys
            .filter { key in
                !fixedOrder.contains(key) && !monthNames.contains(key)
            }
            .compactMap { Int($0) }
            .sorted(by: >)
            .map { String($0) }
        for year in yearKeys {
            if let list = buckets[year] {
                result.append((year, list))
            }
        }
        
        return result
    }

    var body: some View {
        NavigationSplitView {
            List {
                // Header showing title and count
                VStack(alignment: .leading, spacing: 4) {
                    Text("All Items")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("\(items.count) \(items.count == 1 ? "item" : "items")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // Sections for each group with custom header styling
                ForEach(groupedItems, id: \.0) { section in
                    Section(header:
                        Text(section.0)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.vertical, 1)
                            .padding(.horizontal, -20)
                    ) {
                        ForEach(section.1) { item in
                            NavigationLink(destination: SavedItemDetailView(item: item)) {
                                Text(item.title)
                            }
                        }
                        .onDelete { offsets in
                            withAnimation {
                                offsets.map { section.1[$0] }.forEach(modelContext.delete)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .headerProminence(.increased)
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
