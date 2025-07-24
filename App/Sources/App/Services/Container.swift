//
//  Container.swift
//  SwiftUISampleApp
//
//  Created by James Swent on 7/23/25.
//

import Core
import Foundation

public struct Container: Sendable {
    var navigationPersistence: NavigationPersistence
}

extension Container {
    public static let live: Self = Container(
        navigationPersistence: .live
    )
}

#if DEBUG
extension Container {
    public static let mock: Self = Container(
        navigationPersistence: .mock()
    )
}
#endif
