//
//  URLParser.swift
//  Core
//
//  Created by James Swent on 7/22/25.
//

import Foundation
import OSLog

/// Protocol for parsing URLs into routes
public protocol URLParsing: Sendable {
    func parse(_ url: URL) -> URLRoute
}

/// Default implementation of URL parsing for the SavedItem app
public struct URLParser: URLParsing, Sendable {
    private let expectedScheme: String
    private let logger = Logger(subsystem: "URLRouting", category: "Parser")
    
    public init(expectedScheme: String = "saveditem") {
        self.expectedScheme = expectedScheme
    }
    
    public func parse(_ url: URL) -> URLRoute {
        logger.debug("Parsing URL: \(url.absoluteString)")
        
        // Validate scheme
        guard url.scheme?.lowercased() == expectedScheme.lowercased() else {
            logger.warning("Invalid scheme. Expected '\(expectedScheme)', got '\(url.scheme ?? "nil")'")
            return .unsupported(url)
        }
        
        // Extract host (action) and path components
        let action = url.host?.lowercased() ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        logger.debug("Action: '\(action)', Path components: \(pathComponents)")
        
        switch action {
        case "item":
            return parseItemRoute(pathComponents: pathComponents, url: url)
        case "add":
            return parseAddRoute(queryItems: URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? [])
        default:
            logger.warning("Unknown action: '\(action)'")
            return .unsupported(url)
        }
    }
    
    // MARK: - Private Parsing Methods
    
    private func parseItemRoute(pathComponents: [String], url: URL) -> URLRoute {
        guard let uuidString = pathComponents.first,
              let uuid = UUID(uuidString: uuidString) else {
            logger.error("Invalid UUID in item route: \(pathComponents)")
            return .unsupported(url)
        }
        
        logger.info("Parsed item route with UUID: \(uuid)")
        return .openItem(uuid)
    }
    
    private func parseAddRoute(queryItems: [URLQueryItem]) -> URLRoute {
        let parameters = URLRoute.AddItemParameters(queryItems: queryItems)
//        logger.info("Parsed add route with parameters: \(parameters)")
        return .addItem(parameters)
    }
}

// MARK: - URL Builder (for testing and convenience)

extension URLParser {
    /// Build a URL for opening a specific item
    public func buildItemURL(uuid: UUID) -> URL? {
        return URL(string: "\(expectedScheme)://item/\(uuid.uuidString)")
    }
    
    /// Build a URL for adding an item with parameters
    public func buildAddURL(parameters: URLRoute.AddItemParameters) -> URL? {
        guard var components = URLComponents(string: "\(expectedScheme)://add") else {
            return nil
        }
        
        var queryItems: [URLQueryItem] = []
        
        if let title = parameters.title {
            queryItems.append(URLQueryItem(name: "title", value: title))
        }
        
        if let notes = parameters.notes {
            queryItems.append(URLQueryItem(name: "notes", value: notes))
        }
        
        if let url = parameters.url {
            queryItems.append(URLQueryItem(name: "url", value: url))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        return components.url
    }
}
