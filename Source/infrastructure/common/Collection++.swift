//
//  ArrayExtension.swift
//  BrainCache
//
//  Created by Alexander Dittner on 01.04.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Foundation
extension Collection {
    func enumeratedArray() -> Array<(offset: Int, element: Self.Element)> {
        return Array(enumerated())
    }
}
