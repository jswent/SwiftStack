//
//  ExpandAreaTap.swift
//  SwiftUISampleApp
//
//  Created by James Swent on 7/23/25.
//

import Foundation
import SwiftUI

private struct ExpandAreaTap: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
            content
        }
    }
}

public extension View {
    func expandTap(tap: @escaping () -> Void) -> some View {
        self.modifier(ExpandAreaTap()).onTapGesture(perform: tap)
    }
}
