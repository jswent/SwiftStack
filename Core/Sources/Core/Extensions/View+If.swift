//
//  File.swift
//  Core
//
//  Created by James Swent on 7/23/25.
//

import Foundation
import SwiftUI

public extension View {
   @ViewBuilder
   func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }
}
