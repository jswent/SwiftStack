//
//  TextEditorView.swift
//  STACK
//
//  Created by James Swent on 7/23/25.
//

import SwiftUI

struct TextEditorView: View {
    @Binding var text: String
    var placeholder: String = "Add notes..."
    @State private var dynamicHeight: CGFloat = 20

    var body: some View {
        InternalTextView(text: $text,
                         placeholder: placeholder,
                         calculatedHeight: $dynamicHeight)
        .frame(minHeight: dynamicHeight, maxHeight: .infinity)
    }
}

private struct InternalTextView: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    @Binding var calculatedHeight: CGFloat

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if text.isEmpty {
            uiView.text = placeholder
            uiView.textColor = UIColor.secondaryLabel
        } else {
            uiView.text = text
            uiView.textColor = UIColor.label
        }

        DispatchQueue.main.async {
            let size = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: .greatestFiniteMagnitude))
            if abs(calculatedHeight - size.height) > 1 {
                calculatedHeight = size.height
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: InternalTextView

        init(_ parent: InternalTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            // Only update text if not showing placeholder
            if textView.textColor != UIColor.secondaryLabel {
                self.parent.text = textView.text
            }

            DispatchQueue.main.async {
                let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
                if abs(self.parent.calculatedHeight - size.height) > 1 {
                    self.parent.calculatedHeight = size.height
                }
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == UIColor.secondaryLabel {
                textView.text = ""
                textView.textColor = UIColor.label
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = self.parent.placeholder
                textView.textColor = UIColor.secondaryLabel
            }
        }
    }
}
