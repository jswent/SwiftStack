//
//  Symbol.swift
//  SwiftUISampleApp
//
//  Created by James Swent on 7/23/25.
//

import Foundation
import SwiftUI

public enum Symbol: String {
    case info = "info.circle"
    case checkmark
    case rightChevron = "chevron.right"
    case gear
    case plus
    case close = "xmark"
}

public extension Image {
    init(symbol: Symbol) {
        self.init(systemName: symbol.rawValue)
    }
}
