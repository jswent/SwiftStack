//
//  SavedItemListView.swift
//  STACK
//
//  Created by James Swent on 7/21/25.
//

import Core
import SwiftUI
import SwiftData

public struct SavedItemListView: View {
    public enum NavigationTarget {
        case item(SavedItem)
        case addItem
        case editItem(SavedItem)
    }
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: [SortDescriptor(\SavedItem.lastEdited, order: .reverse)]) private var items: [SavedItem]
    @State private var isRefreshing = false
    @State private var groupedItems: [(String, [SavedItem])] = []
    
    let onNavigation: (NavigationTarget) -> Void
    
    public init(onNavigation: @escaping (NavigationTarget) -> Void) {
        self.onNavigation = onNavigation
    }
    
    // Group items into Today, Yesterday, Previous 7 Days, Previous 30 Days,
    // then by month (current year only) and by year for older items.
    private func calculateGroupedItems() -> [(String, [SavedItem])] {
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
    
    private func recalculateGroupings() async {
        let newGroupings = calculateGroupedItems()
        await MainActor.run {
            groupedItems = newGroupings
        }
    }
    
    private func refreshData() async {
        // Simulate a brief delay for better UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Recalculate groupings after refresh
        await recalculateGroupings()
        
        // Can implement cloud sync later
    }

    public var body: some View {
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
                        SavedItemRow(item: item) {
                            onNavigation(.item(item))
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
        .refreshable {
            await refreshData()
        }
        .listStyle(.insetGrouped)
        .headerProminence(.increased)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    onNavigation(.addItem)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            // Initial grouping calculation
            await recalculateGroupings()
        }
        .onChange(of: items) { _, _ in
            // Recalculate when items change
            Task {
                await recalculateGroupings()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Recalculate when app becomes active (handles date changes)
            if newPhase == .active {
                Task {
                    await recalculateGroupings()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SavedItemListView(onNavigation: { _ in })
            .modelContainer(for: SavedItem.self, inMemory: true)
    }
}
