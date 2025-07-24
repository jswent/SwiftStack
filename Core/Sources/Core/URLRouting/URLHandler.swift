//
//  URLHandler.swift
//  Core
//
//  Created by James Swent on 7/22/25.
//

import Foundation
import OSLog

/// Protocol for handling specific URL routes
public protocol URLRouteHandling {
    /// Whether this handler can handle the given route
    func canHandle(_ route: URLRoute) -> Bool
    
    /// Handle the route, returning true if successful
    func handle(_ route: URLRoute) async -> Bool
}

/// Result of URL handling operation
public enum URLHandlingResult: Sendable {
    case handled
    case notHandled
    case error(Error)
    
    public var isSuccess: Bool {
        switch self {
        case .handled:
            return true
        case .notHandled, .error:
            return false
        }
    }
}

/// Coordinates multiple URL handlers using the Chain of Responsibility pattern
@MainActor
public final class URLCoordinator {
    private let parser: URLParsing
    private var handlers: [URLRouteHandling] = []
    private let logger = Logger(subsystem: "URLRouting", category: "Coordinator")
    
    public init(parser: URLParsing = URLParser()) {
        self.parser = parser
    }
    
    /// Register a new handler
    public func register(handler: URLRouteHandling) {
        handlers.append(handler)
        logger.debug("Registered handler: \(String(describing: type(of: handler)))")
    }
    
    /// Handle a raw URL
    public func handle(_ url: URL) async -> URLHandlingResult {
        logger.info("Handling URL: \(url.absoluteString)")
        
        let route = parser.parse(url)
        
        guard route.requiresNavigation else {
            logger.warning("Route does not require navigation: \(route.description)")
            return .notHandled
        }
        
        return await handle(route: route)
    }
    
    /// Handle a parsed route
    public func handle(route: URLRoute) async -> URLHandlingResult {
        logger.debug("Handling route: \(route.description)")
        
        for handler in handlers {
            if handler.canHandle(route) {
                logger.debug("Found handler: \(String(describing: type(of: handler)))")
                
                let success = await handler.handle(route)
                if success {
                    logger.info("Route handled successfully")
                    return .handled
                } else {
                    logger.error("Handler failed to process route")
                }
            }
        }
        
        logger.warning("No handler found for route: \(route.description)")
        return .notHandled
    }
}

// MARK: - Convenience Methods

extension URLCoordinator {
    /// Handle multiple handlers registration at once
    public func register(handlers: [URLRouteHandling]) {
        for handler in handlers {
            self.handlers.append(handler)
            logger.debug("Registered handler: \(String(describing: type(of: handler)))")
        }
    }
    
    /// Check if any handler can handle a specific route type
    public func canHandle(_ route: URLRoute) -> Bool {
        return handlers.contains { $0.canHandle(route) }
    }
}