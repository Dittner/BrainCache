//
//  SeparatorView.swift
//  BrainCache
//
//  Created by Alexander Dittner on 11.02.2021.
//

import Combine
import SwiftUI

struct HSeparatorView: View {
    let horizontalPadding: CGFloat

    init(horizontalPadding: CGFloat = 0) {
        self.horizontalPadding = horizontalPadding
    }

    var body: some View {
        Colors.separator.color
            .padding(.horizontal, horizontalPadding)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
