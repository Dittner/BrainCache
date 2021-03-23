//
//  SeparatorView.swift
//  MP3Book
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
        Color.white.opacity(0.1)
            .padding(.horizontal, horizontalPadding)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
