//
//  Icon.swift
//  BrainCache
//
//  Created by Alexander Dittner on 08.03.2021.
//

//    Icon(name: Constants.font.icon.volume, size: 12)
//         .allowsHitTesting(false)

import SwiftUI

struct Icon: View {
    let name: FontIcon
    let size: CGFloat
    var body: some View {
        Text(name.rawValue)
            .lineLimit(1)
            .font(Font.custom(.icons, size: size))
    }
}
