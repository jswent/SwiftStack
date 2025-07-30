//
//  PhotoPreviewEnvironment.swift
//  STACK
//
//  Created by James Swent on 7/30/25.
//

import SwiftUI

// MARK: - Environment Key

private struct PhotoPreviewServiceKey: EnvironmentKey {
    static let defaultValue = PhotoPreviewService()
}

// MARK: - Environment Extension

public extension EnvironmentValues {
    var photoPreviewService: PhotoPreviewService {
        get { self[PhotoPreviewServiceKey.self] }
        set { self[PhotoPreviewServiceKey.self] = newValue }
    }
}

// MARK: - View Extension

public extension View {
    /// Provides a PhotoPreviewService to the view hierarchy
    func photoPreviewService(_ service: PhotoPreviewService) -> some View {
        environment(\.photoPreviewService, service)
    }
}