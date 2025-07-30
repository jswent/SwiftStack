//
//  ShareDataModel.swift
//  ShareExtension
//
//  Created by James Swent on 7/30/25.
//

import Foundation

// MARK: - Share Data Model

struct ShareData {
    let title: String
    let url: String
    let notes: String
    let photos: [Data]
    
    var isEmpty: Bool {
        title.isEmpty && url.isEmpty && notes.isEmpty && photos.isEmpty
    }
    
    var hasWebContent: Bool {
        !title.isEmpty || !url.isEmpty || !notes.isEmpty
    }
    
    var hasPhotos: Bool {
        !photos.isEmpty
    }
}

// MARK: - Web Content Result

struct WebContentResult {
    let title: String
    let url: String
    let notes: String
}