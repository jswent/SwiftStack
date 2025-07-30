//
//  ShareExtensionError.swift
//  ShareExtension
//
//  Created by James Swent on 7/30/25.
//

import Foundation

enum ShareExtensionError: LocalizedError {
    case noInputItems
    case noValidURL
    case invalidURL
    case invalidJavaScriptResults
    case timeout
    case noValidContent
    
    var errorDescription: String? {
        switch self {
        case .noInputItems:
            return "No content was shared"
        case .noValidURL:
            return "No valid URL found in shared content"
        case .invalidURL:
            return "The shared URL is invalid"
        case .invalidJavaScriptResults:
            return "Could not process shared web page"
        case .timeout:
            return "Request timed out"
        case .noValidContent:
            return "No valid content found to share"
        }
    }
}