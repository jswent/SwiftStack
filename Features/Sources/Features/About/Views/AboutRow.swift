//
//  AboutRow.swift
//  SwiftUISampleApp
//
//  Created by James Swent on 7/23/25.
//

import Core
import Foundation
import SwiftUI

struct AboutRow: View {
    let title: String
    let onTap: (() -> Void)?

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .expandTap {
                onTap?()
            }
    }
}
