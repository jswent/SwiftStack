//
//  View+Keyboard.swift
//  STACK
//
//  Created by James Swent on 7/23/25.
//

import SwiftUI
import UIKit

public extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}