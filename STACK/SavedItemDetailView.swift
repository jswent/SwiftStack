//
//  SavedItemDetailView.swift
//  STACK
//
//  Created by James Swent on 7/12/25.
//

import SwiftUI
import SwiftData

/// Extension to provide ordinal suffix for day numbers
extension Int {
    var ordinalSuffix: String {
        let ones = self % 10
        let tens = (self / 10) % 10
        if tens == 1 { return "th" }
        switch ones {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}

/// A UIViewRepresentable wrapper around UITextView that auto-sizes to fit its content, matching Apple Notes style
struct ExpandingTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        textView.text = text
        // No border or background
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ExpandingTextView
        init(_ parent: ExpandingTextView) {
            self.parent = parent
        }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

/// A detail view to display and inline-edit a SavedItem's details
struct SavedItemDetailView: View {
    @Bindable var item: SavedItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Group title and date with reduced spacing
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(prettyDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Bind optional notes to a non-optional String for editing
                let notesBinding = Binding(
                    get: { item.notes ?? "" },
                    set: { newValue in
                        item.notes = newValue.isEmpty ? nil : newValue
                        item.lastEdited = Date()
                    }
                )

                // Expanding text view (Apple Notes style)
                ExpandingTextView(text: notesBinding)
                    .frame(minHeight: 50)
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Compute a pretty string for the createdAt date
    private var prettyDate: String {
        let month = item.createdAt.formatted(.dateTime.month(.wide))
        let day = Calendar.current.component(.day, from: item.createdAt)
        let year = item.createdAt.formatted(.dateTime.year())
        return "\(month) \(day)\(day.ordinalSuffix), \(year)"
    }
}
