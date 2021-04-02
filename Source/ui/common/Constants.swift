//
//  Constants.swift
//  BrainCache
//
//  Created by Alexander Dittner on 02.05.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import SwiftUI

public struct Colors {
    static let appBG = NSColor(rgb: 0x2b2c2e)
    static let folderListBG = [Color(rgb: 0x323436), Color(rgb: 0x414346)]
    
    static let textDark = NSColor(rgb: 0x90959b)
    static let textLight = NSColor(rgb: 0xe9f0f9)
    static let text = NSColor(rgb: 0xd0d7df)
    static let clear = NSColor(rgb: 0x000000, alpha: 0.000001)
    static let black01 = NSColor(rgb: 0, alpha: 0.1)
    static let selection = NSColor(rgb: 0x353638)
    static let separator = NSColor(rgb: 0x3b3c3e, alpha: 1)
    static let debugLines = NSColor(rgb: 0x00C3FF, alpha: 1)
    
    static let textHighlight = NSColor(rgb: 0x333333)
    static let textHighlightBG = NSColor(rgb: 0x6956bc)
    static let focus = NSColor(rgb: 0x6baffd)
    static let button = NSColor(rgb: 0xa29cbd)
}

class SizeConstants {
    static let folderListWidth: CGFloat = 300
    static let fileListWidth: CGFloat = 200
    static let searchBarWidth: CGFloat = 150
    static let tableRowNumberWidth: CGFloat = 50
    static let appHeaderHeight: CGFloat = 25
    static let windowHeaderHeight: CGFloat = 20
    static let listCellHeight: CGFloat = 25
    static let fontSize: CGFloat = 13
    static let fontLineHeight: CGFloat = 20
    static let iconSize: CGFloat = 12
    static let padding: CGFloat = 10
}
