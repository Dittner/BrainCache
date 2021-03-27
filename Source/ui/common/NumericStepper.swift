//
//  NumericStepper.swift
//  BrainCache
//
//  Created by Alexander Dittner on 27.01.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import SwiftUI

struct NumericStepper: View {
    @Binding var value: Int
    let minimum: Int
    let maximum: Int
    let label: String
    let labelColor: Color

    init(value: Binding<Int>, minimum: Int, maximum: Int, label: String, labelColor: Color) {
        _value = value
        self.minimum = minimum
        self.maximum = maximum
        self.label = label
        self.labelColor = labelColor
    }

    var body: some View {
        HStack(alignment: .center, spacing: 1) {
            Text(label + self.value.description)
                .allowsHitTesting(false)
                .lineLimit(1)
                .foregroundColor(labelColor)
                .font(Font.custom(.pragmatica, size: SizeConstants.fontSize))

            IconButton(name: .minus, size: 8, color: labelColor, width: SizeConstants.iconSize + 6, height: SizeConstants.iconSize + 6) {
                if value > minimum {
                    value -= 1
                }
            }.background(Colors.black01.color)
            .cornerRadius(4)

            IconButton(name: .plus, size: 8, color: labelColor, width: SizeConstants.iconSize + 6, height: SizeConstants.iconSize + 6) {
                if value < maximum {
                    value += 1
                }
            }.background(Colors.black01.color)
            .cornerRadius(4)
        }
    }
}
