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
        // Wrap on word
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.size.width = UIScreen.main.bounds.width - 32
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title + date
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(prettyDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Link preview, shown only if there's a URL
                if let url = item.url {
                    LinkPreview(url: url)
                        .frame(minHeight: 80)
                        .cornerRadius(8)
                }

                // Notes binding and expanding text view
                let notesBinding = Binding(
                    get: { item.notes ?? "" },
                    set: { newValue in
                        item.notes = newValue.isEmpty ? nil : newValue
                        item.lastEdited = Date()
                    }
                )

                ExpandingTextView(text: notesBinding)
                    .frame(maxWidth: UIScreen.main.bounds.width - 32, minHeight: 50)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditSavedItemView(item: item)
        }
    }

    private var prettyDate: String {
        let month = item.createdAt.formatted(.dateTime.month(.wide))
        let day = Calendar.current.component(.day, from: item.createdAt)
        let year = item.createdAt.formatted(.dateTime.year())
        return "\(month) \(day)\(day.ordinalSuffix), \(year)"
    }
}
