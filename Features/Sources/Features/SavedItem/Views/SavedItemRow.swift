//
//  SavedItemRow.swift
//  STACK
//
//  Created by James Swent on 7/22/25.
//

import Core
import Foundation
import SwiftUI

struct SavedItemRow: View {
    let item: SavedItem
    let onTap: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Text(item.lastEdited.relativePrettyFormatted)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    if item.url != nil {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Image(symbol: .rightChevron)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .expandTap {
            onTap?()
        }
    }
}

#Preview {
    List {
        SavedItemRow(item: .mock, onTap: nil)
        SavedItemRow(
            item: SavedItem(
                title: "Item with very long title that should wrap to multiple lines gracefully",
                notes: "This is a sample note that demonstrates how the row handles longer content and multiple lines of text.",
                url: URL(string: "https://example.com")
            ),
            onTap: nil
        )
        SavedItemRow(
            item: SavedItem(title: "No notes or URL", notes: nil, url: nil),
            onTap: nil
        )
    }
}
