//
//  SeparatorView.swift
//  MP3Book
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
        Color.white.opacity(0.1)
            .padding(.vertical, verticalPadding)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
            .zIndex(1)
    }
}