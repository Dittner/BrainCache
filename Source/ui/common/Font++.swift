//
//  NSFontExtension.swift
//  BrainCache
//
//  Created by Alexander Dittner on 11.03.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import SwiftUI

enum FontIcon: String {
    case next = "\u{e900}"
    case prev = "\u{e901}"
    case folder = "\u{e902}"
    case plus = "\u{e903}"
    case table = "\u{e904}"
    case file = "\u{e905}"
    case search = "\u{e906}"
    case close = "\u{e907}"
    case minus = "\u{e908}"
    case list = "\u{e909}"
    case sort = "\u{e90a}"
    case dropdown = "\u{e90b}"
    case arrow = "\u{e90c}"
}

enum FontName: String {
    case icons = "BrainCacheIcons"
    case pragmatica = "PragmaticaBook-Reg"
    //case pragmaticaLight = "PragmaticaLight"
    //case pragmaticaLightItalics = "PragmaticaLight-Oblique"
    //case pragmaticaExtraLight = "PragmaticaExtraLight-Reg"
    //case pragmaticaExtraLightItalics = "PragmaticaExtraLight-Oblique"
    //case pragmaticaSemiBold = "PragmaticaMedium"
    //case pragmaticaBold = "PragmaticaBold-Reg"
    //case mono = "PTMono-Regular"
    case mono = "Menlo-Regular"
    case def = "PragmaticaLight"
}

extension Font {
    static func custom(_ name: FontName, size: CGFloat) -> Font {
        Font.custom(name.rawValue, size: size)
    }
    
    static func printAllSystemFonts() {
        for family: String in NSFontManager.shared.availableFontFamilies {
            print("===\(family)===")
            for fontName: String in NSFontManager.shared.availableFonts {
                print("\(fontName)")
            }
        }
    }
}

extension NSFont {
    convenience init(name: FontName, size: CGFloat) {
        self.init(name: name.rawValue, size: size)!
    }
}

extension NSTextView {
    static var defaultInsertionPointColor: NSColor {
        return NSColor.controlTextColor
    }

    static var defaultSelectedTextAttributes: [NSAttributedString.Key : Any] {
        return [
            .foregroundColor: NSColor.selectedTextColor,
            .backgroundColor: NSColor.selectedTextBackgroundColor
        ]
    }
}
