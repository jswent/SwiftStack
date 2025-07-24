//
//  HomeView.swift
//  STACK
//
//  Created by James Swent on 7/22/25.
//

import Core
import SwiftUI

public struct HomeView: View {
    public enum NavigationTarget {
        case items
        case about
    }
    
    let onNavigation: (NavigationTarget) -> Void
    
    public init(onNavigation: @escaping (NavigationTarget) -> Void) {
        self.onNavigation = onNavigation
    }
    
    public var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Items")
                            .font(.headline)
                        
                        Text("Saved items and bookmarks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(symbol: .rightChevron)
                        .foregroundStyle(.tertiary)
                }
                .expandTap {
                    onNavigation(.items)
                }
            }
        }
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    onNavigation(.about)
                } label: {
                    Image(symbol: .info)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(onNavigation: { _ in })
    }
}