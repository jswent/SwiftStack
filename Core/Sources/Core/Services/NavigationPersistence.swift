//
//  NavigationPersistence.swift
//  Core
//
//  Created by James Swent on 7/22/25.
//

import Foundation

public struct NavigationPersistence: Sendable {
    public typealias Get = @Sendable () -> String?
    public typealias Set = @Sendable (String?) -> Void
    
    public let get: Get
    public let set: Set
    
    public init(get: @escaping @Sendable Get, set: @escaping @Sendable Set) {
        self.get = get
        self.set = set
    }
}

extension NavigationPersistence {
    private static let lastScreenKey = "lastScreen"
    
    public static let live: Self = NavigationPersistence(
        get: {
            UserDefaults.standard.string(forKey: lastScreenKey)
        },
        set: { screenId in
            if let screenId = screenId {
                UserDefaults.standard.set(screenId, forKey: lastScreenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastScreenKey)
            }
        }
    )
}

#if DEBUG
extension NavigationPersistence {
    public static func mock(lastScreen: String? = nil) -> Self {
        var stored = lastScreen
        return NavigationPersistence(
            get: { stored },
            set: { stored = $0 }
        )
    }
}
#endif