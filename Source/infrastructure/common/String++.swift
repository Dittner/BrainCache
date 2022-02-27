import CommonCrypto
import CryptoKit
import Foundation
import SwiftUI

extension String {
    /*
     "x123v456".matches(for: "v[0-9]+") // ["v456"]
     "x123v456".matches(for: "v([0-9]+)") // ["v456". "456"]
     */

    func matches(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0 ..< result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
    }

    func firstMatch(regex: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        let matches = results.map { result in
            (0 ..< result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
        return matches.count > 0 ? matches.first! : []
    }

    func firstDigits() -> Int {
        let matches = firstMatch(regex: "^(-?[0-9]+)")
        return matches.count > 0 ? Int(matches.first!) ?? 0 : 0
    }

    func indexesOf(string: String) -> [Int] {
        guard !string.isEmpty else { return [] }

        var indices = [Int]()

        let searchText = string.lowercased()
        let selfText = lowercased()
        var searchStartIndex = selfText.startIndex

        while searchStartIndex < endIndex,
              let range = selfText.range(of: searchText, range: searchStartIndex ..< selfText.endIndex),
              !range.isEmpty {
            let index = selfText.distance(from: selfText.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }

        return indices
    }

    /*
     "string_id".localized
     */

    func hasSubstring(_ str: String) -> Bool {
        return lowercased().contains(str.lowercased())
    }

    /*
     "string_id".localize
     */

    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func sha512() -> String? {
        guard let msg = data(using: .utf8) else { return nil }
        return SHA512.hash(data: msg).compactMap { String(format: "%02x", $0) }.joined()
    }

    func matches(predicate: NSPredicate) -> Bool {
        predicate.evaluate(with: self)
    }

    func textHeightFrom(width: CGFloat, fontName: String = "System Font", fontSize: CGFloat = 18) -> CGFloat {
        #if os(macOS)

            typealias UXFont = NSFont
            let text: NSTextField = .init(string: self)
            text.font = NSFont(name: fontName, size: fontSize)

        #else

            typealias UXFont = UIFont
            let text: UILabel = .init()
            text.text = self
            text.numberOfLines = 0

        #endif

        text.font = UXFont(name: fontName, size: fontSize)
        text.lineBreakMode = .byWordWrapping
        return text.sizeThatFits(CGSize(width: width, height: .infinity)).height
    }

    /*
     let str = "Hello, world"
     print(str[...4]) // "Hello"
     print(str[..<5]) // "Hello"
     print(str[7...]) // "world"
     print(str[3...4] + str[2]) // "lol"
     */

    subscript(i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }

    subscript(bounds: CountableRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < start { return "" }
        return self[start ..< end]
    }

    subscript(bounds: CountableClosedRange<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < start { return "" }
        return self[start ... end]
    }

    subscript(bounds: CountablePartialRangeFrom<Int>) -> Substring {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(endIndex, offsetBy: -1)
        if end < start { return "" }
        return self[start ... end]
    }

    subscript(bounds: PartialRangeThrough<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < startIndex { return "" }
        return self[startIndex ... end]
    }

    subscript(bounds: PartialRangeUpTo<Int>) -> Substring {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        if end < startIndex { return "" }
        return self[startIndex ..< end]
    }

    func index(from: Int) -> Index {
        return index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex ..< endIndex])
    }

    /*
     let a1 = "12345".containsOnlyDigits // true
     let a2 = "a12345".containsOnlyDigits // false
     let b1 = "abcde".containsOnlyLetters // true
     let b2 = "abcde1".containsOnlyLetters // false
     let c1 = "abcde12345".isAlphanumeric // true
     let c2 = "abcde.12345".isAlphanumeric // false
     let approved = "test@test.com".isValidEmail // true
     */

    var containsOnlyDigits: Bool {
        let notDigits = NSCharacterSet.decimalDigits.inverted
        return rangeOfCharacter(from: notDigits, options: String.CompareOptions.literal, range: nil) == nil
    }

    var containsOnlyLetters: Bool {
        let notLetters = NSCharacterSet.letters.inverted
        return rangeOfCharacter(from: notLetters, options: String.CompareOptions.literal, range: nil) == nil
    }

    var isAlphanumeric: Bool {
        let notAlphanumeric = NSCharacterSet.decimalDigits.union(NSCharacterSet.letters).inverted
        return rangeOfCharacter(from: notAlphanumeric, options: String.CompareOptions.literal, range: nil) == nil
    }

    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }

    /*
     "[0-9]{0,4}".asPredicate to format input to type only digits
     */

    var asPredicate: NSPredicate {
        return NSPredicate(format: "SELF MATCHES %@", self)
    }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }

    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }

    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        var indices: [Index] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = self[startIndex...]
              .range(of: string, options: options) {
            indices.append(range.lowerBound)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return indices
    }

    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = self[startIndex...]
              .range(of: string, options: options) {
            result.append(range)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
