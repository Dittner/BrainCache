//
//  SeparatorView.swift
//  BrainCache
//
//  Created by Alexander Dittner on 11.02.2021.
//

import Combine
import SwiftUI

struct VSeparatorView: View {
    let verticalPadding: CGFloat

    init(verticalPadding: CGFloat = 0) {
        self.verticalPadding = verticalPadding
    }

    var body: some View {
        Colors.separator.color
            .padding(.vertical, verticalPadding)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
            .zIndex(-1)
    }
}
