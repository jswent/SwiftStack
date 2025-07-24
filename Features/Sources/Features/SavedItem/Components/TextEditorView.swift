//
//  TextEditorView.swift
//  STACK
//
//  Created by James Swent on 7/23/25.
//

import SwiftUI

struct TextEditorView: View {
    
    @Binding var text: String
    @State private var textEditorHeight: CGFloat = 20
    private let placeholder: String
    
    init(text: Binding<String>, placeholder: String = "Add notes...") {
        self._text = text
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            Text(text.isEmpty ? " " : text)
                .foregroundColor(.clear)
                .padding(8)
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: ViewHeightKey.self,
                                           value: geometry.frame(in: .local).size.height)
                })
            
            TextEditor(text: $text)
                .frame(height: max(20, textEditorHeight))
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .background(Color.clear)
                .padding(.horizontal, -4)
                .padding(.vertical, -8)
            
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .allowsHitTesting(false)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            
        }
        .onPreferenceChange(ViewHeightKey.self) { height in
            textEditorHeight = height
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = max(value, nextValue())
    }
}