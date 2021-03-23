//
//  TextFormatter.swift
//  BrainCache
//
//  Created by Alexander Dittner on 11.06.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Foundation

class TextFormatter {
    static func removeSpaceDuplicates(_ text: String, selection: NSRange?) -> String {
        var res = text
        let range = selection != nil ? Range(selection!, in: res) : nil

        res = res.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression, range: range)
        return res
    }
    
    static func replaceHyphenWithDash(_ text: String, selection: NSRange?) -> String {
        var res = text
        let range = selection != nil ? Range(selection!, in: res) : nil

        res = res.replacingOccurrences(of: " -", with: " —", options: .regularExpression, range: range)
        res = res.replacingOccurrences(of: "\n-", with: "\n—", options: .regularExpression, range: range)
        res = res.replacingOccurrences(of: " –", with: " —", options: .regularExpression, range: range)
        res = res.replacingOccurrences(of: "\n–", with: "\n—", options: .regularExpression, range: range)
        return res
    }
    
    static func removeWordWrapping(_ text: String, selection: NSRange?) -> String {
        var res = text
        var range = selection != nil ? Range(selection!, in: res) : nil

        res = res.replacingOccurrences(of: "-\n", with: "", options: .caseInsensitive, range: range)
        if res.count != text.count, let selection = selection {
            let r = NSRange(location: selection.location, length: selection.length - (text.count - res.count))
            range = Range(r, in: res)
        }

        res = res.replacingOccurrences(of: "\n", with: " ", options: .caseInsensitive, range: range)
        return res
    }
}
