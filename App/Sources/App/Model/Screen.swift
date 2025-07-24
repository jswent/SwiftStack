//
//  Screen.swift
//  SwiftUISampleApp
//
//  Created by James Swent on 7/23/25.
//

import Core
import Foundation
import SavedItem

enum Screen: Identifiable, Hashable {
    case home
    case savedItems
    case savedItem(SavedItem)
    case about
    case libraries

    var id: String {
        switch self {
        case .home:
            return "home"
        case .savedItems:
            return "savedItems"
        case .about:
            return "about"
        case .libraries:
            return "libraries"
        case .savedItem(let item):
            return item.id.uuidString
        }
    }
}
