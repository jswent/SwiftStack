//
//  SafariWebView.swift
//  SwiftUISampleApp
//
//  Created by James Swent on 7/23/25.
//

import Foundation
import SafariServices
import SwiftUI

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
