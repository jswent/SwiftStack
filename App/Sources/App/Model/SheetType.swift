//
//  SheetType.swift
//  SwiftUISampleApp
//
//  Created by James Swent on 7/23/25.
//

import Core
import Foundation
import SavedItem

enum SheetType: Identifiable {
    case addItem(URLRoute.AddItemParameters?)
    case editItem(SavedItem)
    
    var id: String {
        switch self {
        case .addItem:
            return "addItem"
        case .editItem(let item):
            return "editItem-\(item.id.uuidString)"
        }
    }
}