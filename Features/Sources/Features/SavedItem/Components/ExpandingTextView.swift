//
//  ExpandingTextView.swift
//  STACK
//
//  Created by James Swent on 7/22/25.
//

import SwiftUI

/// A UIViewRepresentable wrapper around UITextView that auto-sizes to fit its content,
/// matching Apple Notes style with proper geometry handling
struct ExpandingTextView: UIViewRepresentable {
    @Binding var text: String
    private let placeholder: String?
    private let maxHeight: CGFloat?
    
    init(text: Binding<String>, placeholder: String? = nil, maxHeight: CGFloat? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.maxHeight = maxHeight
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        configureTextView(textView, context: context)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        
        // Update placeholder visibility
        updatePlaceholderVisibility(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func configureTextView(_ textView: UITextView, context: Context) {
        // Basic configuration
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        textView.text = text
        
        // Layout configuration
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        
        // Content priorities for proper layout
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        // Configure placeholder if provided
        if let placeholder = placeholder {
            setupPlaceholder(textView, placeholder: placeholder)
        }
        
        // Handle max height constraint
        if let maxHeight = maxHeight {
            textView.isScrollEnabled = true
            textView.addConstraint(NSLayoutConstraint(
                item: textView,
                attribute: .height,
                relatedBy: .lessThanOrEqual,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1,
                constant: maxHeight
            ))
        }
    }
    
    private func setupPlaceholder(_ textView: UITextView, placeholder: String) {
        // Add placeholder label as subview
        let placeholderLabel = UILabel()
        placeholderLabel.text = placeholder
        placeholderLabel.font = textView.font
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        textView.addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -5)
        ])
        
        // Store reference for updates
        placeholderLabel.tag = 999
        updatePlaceholderVisibility(textView)
    }
    
    private func updatePlaceholderVisibility(_ textView: UITextView) {
        if let placeholderLabel = textView.viewWithTag(999) as? UILabel {
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: ExpandingTextView
        
        init(_ parent: ExpandingTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.updatePlaceholderVisibility(textView)
            
            // Adjust scroll state based on height
            if let maxHeight = parent.maxHeight {
                let contentHeight = textView.contentSize.height
                textView.isScrollEnabled = contentHeight > maxHeight
            }
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.updatePlaceholderVisibility(textView)
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.updatePlaceholderVisibility(textView)
        }
    }
}