//
//  UID.swift
//  BrainCache
//
//  Created by Alexander Dittner on 19.03.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Foundation
typealias UID = Int64

extension UID {
    private static var ids:UID = UID(Date().timeIntervalSince1970)

    init() {
        UID.ids += 1
        self = UID.ids
    }
}
