//
//  NSTextField.swift
//  BrainCache
//
//  Created by Alexander Dittner on 17.02.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import SwiftUI

extension NSTextField {
    override open var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}
