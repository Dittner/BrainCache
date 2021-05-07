//
//  Inputs.swift
//  BrainCache
//
//  Created by Alexander Dittner on 27.01.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Combine
import SwiftUI

extension NSTextField {
    func becomeFirstResponderWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.becomeFirstResponder()
        }
    }
}

struct TextInput: NSViewRepresentable {
    private static var focusedField: NSTextField?
    static let tf: NSTextField = NSTextField()

    let title: String
    @Binding var text: String
    let textColor: NSColor
    let font: NSFont
    let alignment: NSTextAlignment
    var isFocused: Bool
    let isSecure: Bool
    let format: String?
    let isEditable: Bool
    let onEnterAction: (() -> Void)?
    let onFocusChangedAction: ((Bool) -> Void)?

    func makeNSView(context: Context) -> NSTextField {
        let tf = isSecure ? NSSecureTextField() : NSTextField()
        tf.isBordered = false
        tf.backgroundColor = nil
        tf.focusRingType = .none
        tf.textColor = textColor
        tf.placeholderString = title
        tf.allowsEditingTextAttributes = false
        tf.alignment = alignment
        tf.isEditable = isEditable
        tf.delegate = context.coordinator

        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.parent = self
        nsView.isEditable = isEditable
        nsView.stringValue = text
        nsView.font = font

        if isFocused && TextInput.focusedField != nsView {
            TextInput.focusedField = nsView
            nsView.becomeFirstResponderWithDelay()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TextInput

        init(_ parent: TextInput) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                if let format = parent.format, textField.stringValue.count > 0, !textField.stringValue.matches(predicate: format.asPredicate) {
                    textField.stringValue = parent.text
                } else if parent.text != textField.stringValue {
                    parent.text = textField.stringValue
                }
            }
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            parent.onFocusChangedAction?(true)
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onFocusChangedAction?(false)
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onEnterAction?()
            }
            return false
        }
    }
}

struct TextArea: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    let width: CGFloat
    let textColor: NSColor
    let font: NSFont
    let highlightedText: String
    let lineHeight: CGFloat?

    init(text: Binding<String>, height: Binding<CGFloat>, width: CGFloat, textColor: NSColor, font: NSFont, highlightedText: String, lineHeight: CGFloat? = nil) {
        _text = text
        _height = height
        self.width = width
        self.textColor = textColor
        self.font = font
        self.highlightedText = highlightedText
        self.lineHeight = lineHeight
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> CustomNSTextView {
        let tv = CustomNSTextView()
        tv.delegate = context.coordinator
        tv.textColor = textColor
        tv.font = font
        tv.allowsUndo = true
        tv.defaultParagraphStyle = getStyle()
        tv.backgroundColor = Colors.clear
        tv.isVerticallyResizable = false
        tv.canDrawSubviewsIntoLayer = true
        tv.string = "Ag"
        return tv
    }

    func getStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.firstLineHeadIndent = 0
        style.lineBreakMode = .byWordWrapping
        style.lineSpacing = 0

        if let lineHeight = lineHeight {
            style.minimumLineHeight = lineHeight
            style.maximumLineHeight = lineHeight
            style.lineHeightMultiple = lineHeight
        }

        return style
    }

    func updateNSView(_ textArea: CustomNSTextView, context: Context) {
        // need update parent, otherwise will be updated text from prev binding
        context.coordinator.parent = self
        if textArea.curHighlightedText != highlightedText {
            textArea.curHighlightedText = highlightedText
        }

        if textArea.string != text {
            textArea.string = text
        }

        if textArea.font != font {
            textArea.font = font
        }

        textArea.textStorage?.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: text.count))
        textArea.textStorage?.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: NSRange(location: 0, length: text.count))

        let style = getStyle()

        textArea.textStorage?.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: text.count))

        textArea.defaultParagraphStyle = style

        if !highlightedText.isEmpty {
            let ranges = text.ranges(of: highlightedText, options: .caseInsensitive)
            for r in ranges {
                textArea.textStorage?.addAttribute(NSAttributedString.Key.foregroundColor, value: Colors.textHighlight, range: NSRange(r, in: highlightedText))
            }
        }

        if text.count > 2, let regex = try? NSRegularExpression(pattern: "#(#| )+.*\n", options: .caseInsensitive) {
            let t = text.substring(to: text.count - 1) + "\n"
            let nsString = t as NSString
            let results = regex.matches(in: t, options: [], range: NSMakeRange(0, nsString.length))
            results.forEach { result in
                let r = result.range
                if r.length > 1 {
                    let tag = text[r.location + 1 ... r.location + 1]
                    if tag == "#" {
                        textArea.textStorage?.addAttribute(NSAttributedString.Key.foregroundColor, value: Colors.textBlack, range: NSRange(location: r.location, length: 2))
                        textArea.textStorage?.addAttribute(NSAttributedString.Key.foregroundColor, value: Colors.header, range: NSRange(location: r.location + 2, length: r.length - 2))
                    } else if tag == " " {
                        textArea.textStorage?.addAttribute(NSAttributedString.Key.foregroundColor, value: Colors.textBlack, range: NSRange(location: r.location, length: 1))
                        textArea.textStorage?.addAttribute(NSAttributedString.Key.foregroundColor, value: Colors.comment, range: NSRange(location: r.location + 1, length: r.length - 1))
                    }
                }
            }
        }

        updateHeight(textArea)
    }

    func updateHeight(_ textArea: CustomNSTextView) {
        textArea.textContainer?.containerSize.width = width
        let updatedHeight = textArea.contentSize.height
        if height != updatedHeight {
            height = updatedHeight
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextArea

        init(_ textArea: TextArea) {
            parent = textArea
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            return true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? CustomNSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            return newSelectedCharRange
        }
    }
}

class CustomNSTextView: NSTextView {
    var curHighlightedText: String = ""

    override func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    var contentSize: CGSize {
        guard let layoutManager = layoutManager, let textContainer = textContainer else {
            return .zero
        }

        layoutManager.ensureLayout(for: textContainer)
        return layoutManager.usedRect(for: textContainer).size
    }
}

class EditableTextManager: ObservableObject {
    static var shared: EditableTextManager = EditableTextManager()
    var ownerUID: UID = UID()
    @Published var isEditing: Bool = false
}

class TextBuffer: ObservableObject {
    @Published var text: String = ""
}

struct EditableText: View {
    @ObservedObject private var textManager = EditableTextManager.shared
    @ObservedObject private var textBuffer = TextBuffer()
    let text: String
    let uid: UID
    let alignment: Alignment
    let useMonoFont: Bool
    let countClickActivation: Int
    let action: (String) -> Void
    let font: NSFont

    init(_ text: String, uid: UID, alignment: Alignment = .leading, useMonoFont: Bool = false, countClickActivation: Int = 2, action: @escaping (String) -> Void) {
        self.text = text
        self.uid = uid
        self.alignment = alignment
        self.useMonoFont = useMonoFont
        self.countClickActivation = countClickActivation
        self.action = action
        font = NSFont(name: useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize)
    }

    var body: some View {
        GeometryReader { proxy in
            if textManager.isEditing && textManager.ownerUID == uid {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Colors.focus.color)
                    .frame(width: proxy.size.width - 3, height: proxy.size.height - 2)
                    .offset(x: 1, y: 0)

                TextInput(title: "", text: $textBuffer.text, textColor: Colors.text, font: font, alignment: .left, isFocused: textManager.isEditing && textManager.ownerUID == uid, isSecure: false, format: nil, isEditable: textManager.isEditing && textManager.ownerUID == uid, onEnterAction: {
                    action(textBuffer.text)
                    textManager.isEditing = false
                }, onFocusChangedAction: { hasFocus in
                    if textManager.isEditing && !hasFocus {
                        textManager.isEditing = false
                    }
                }).padding(.leading, SizeConstants.padding - 2)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture(count: countClickActivation) {
                        textBuffer.text = text
                        textManager.ownerUID = uid
                        textManager.isEditing = true
                    }

            } else {
                Text(self.text)
                    .lineLimit(1)
                    .font(Font.custom(useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize))
                    .padding(.horizontal, SizeConstants.padding)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: alignment)
                    .contentShape(Rectangle())
                    .onTapGesture(count: countClickActivation) {
                        textBuffer.text = text
                        textManager.ownerUID = uid
                        textManager.isEditing = true
                    }
            }
        }
    }
}

struct EditableMultilineText: View {
    @ObservedObject private var textBuffer = TextBuffer()
    @ObservedObject private var notifier = HeightDidChangeNotifier()

    let uid: UID
    let alignment: Alignment
    let width: CGFloat
    let useMonoFont: Bool
    let searchText: String
    let hasSearchMatches: Bool
    let action: (String) -> Void

    private var subscription: AnyCancellable?

    init(_ text: String, uid: UID, alignment: Alignment = .leading, width: CGFloat, useMonoFont: Bool = false, searchText: String = "", action: @escaping (String) -> Void) {
        print("EditableMultilineText init, uid = \(uid)")
        self.uid = uid
        self.alignment = alignment
        self.width = width
        self.useMonoFont = useMonoFont
        self.searchText = searchText
        hasSearchMatches = searchText.count > 0 ? text.hasSubstring(searchText) : false
        self.action = action
        textBuffer.text = text

        subscription = textBuffer.$text
            .dropFirst()
            .removeDuplicates()
            .sink { value in
                action(value)
            }
    }

    var body: some View {
        TextArea(text: $textBuffer.text, height: $notifier.height, width: width - SizeConstants.padding, textColor: Colors.text, font: NSFont(name: useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize), highlightedText: searchText, lineHeight: SizeConstants.fontLineHeight)
            .colorScheme(.dark)
            .frame(width: width - SizeConstants.padding, height: max(SizeConstants.listCellHeight, notifier.height))
    }
}

enum StringMark: Int {
    case comment = 0
    case search = 1
    case text = 2
}

struct MarkableString {
    let text: String
    let mark: StringMark
}

struct MarkableText: View {
    let text: [MarkableString]
    let matching: String
    let caseSensitive: Bool = false

    init(_ text: String, matching: String) {
        var sentences: [MarkableString] = []
        var s: String = ""
        var isCommenting: Bool = false

        var matchingBuffer: String = ""
        let searchText = matching.lowercased()
        for (index, char) in text.lowercased().enumerated() {
            if char == "#" && !isCommenting {
                isCommenting = true
                if matchingBuffer.count > 0 {
                    s.append(matchingBuffer)
                }
                if s.count > 0 {
                    sentences.append(MarkableString(text: s, mark: .text))
                    s = ""
                    matchingBuffer = ""
                }
                s.append(text[index])
            } else if char == "\n" && isCommenting {
                isCommenting = false
                if s.count > 0 {
                    sentences.append(MarkableString(text: s, mark: .comment))
                    s = ""
                    matchingBuffer = ""
                }
                s.append(text[index])
            } else if searchText.count > 0 && char == searchText[matchingBuffer.count] {
                matchingBuffer.append(text[index])
                if searchText.count > 0 && matchingBuffer.count == searchText.count {
                    sentences.append(MarkableString(text: s, mark: isCommenting ? .comment : .text))
                    sentences.append(MarkableString(text: matchingBuffer, mark: .search))
                    matchingBuffer = ""
                    s = ""
                }

            } else if matchingBuffer.count > 0 {
                s.append(matchingBuffer)
                s.append(text[index])
                matchingBuffer = ""
            } else {
                s.append(text[index])
            }
        }
        if matchingBuffer.count > 0 {
            s.append(matchingBuffer)
        }
        if s.count > 0 {
            sentences.append(MarkableString(text: s, mark: isCommenting ? .comment : .text))
        }

        self.text = sentences
        self.matching = matching
    }

    var body: some View {
        if text.count > 0 {
            return text.map { (str) -> Text in
                if str.text.count > 0 && str.mark == .search {
                    return Text(str.text).foregroundColor(Colors.textHighlight.color)
                } else if str.text.count > 0 && str.mark == .comment {
                    return Text(str.text).foregroundColor(Colors.comment.color)
                } else {
                    return Text(str.text)
                }
            }.reduce(Text("")) { (a, b) -> Text in
                a + b
            }
        } else {
            return Text("")
        }
    }
}

struct HighlightedText: View {
    let text: String
    let matching: String
    let caseSensitive: Bool

    init(_ text: String, matching: String, caseSensitive: Bool = false) {
        self.text = text
        self.matching = matching
        self.caseSensitive = caseSensitive
    }

    var body: some View {
        guard let regex = try? NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: matching).trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .regularExpression, locale: .current), options: caseSensitive ? .init() : .caseInsensitive)
        else {
            return Text(text)
        }

        let range = NSRange(location: 0, length: text.count)
        let matches = regex.matches(in: text, options: .withTransparentBounds, range: range)

        return text.enumerated().map { (char) -> Text in
            if matches.filter({ $0.range.contains(char.offset) }).count > 0 {
                return Text(String(char.element)).foregroundColor(Colors.textHighlight.color)

            } else {
                return Text(String(char.element))
            }
        }.reduce(Text("")) { (a, b) -> Text in
            a + b
        }
    }
}

class HeightDidChangeNotifier: ObservableObject {
    @Published var height: CGFloat = 0
}
