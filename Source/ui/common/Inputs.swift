//
//  Inputs.swift
//  BrainCache
//
//  Created by Alexander Dittner on 27.01.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

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
    let action: ((String) -> Void)?

    init(text: Binding<String>, height: Binding<CGFloat>, width: CGFloat, textColor: NSColor, font: NSFont, highlightedText: String, lineHeight: CGFloat? = nil) {
        _text = text
        _height = height
        self.width = width
        self.textColor = textColor
        self.font = font
        self.highlightedText = highlightedText
        self.lineHeight = lineHeight
        action = nil
    }

    init(text: String, height: Binding<CGFloat>, width: CGFloat, textColor: NSColor, font: NSFont, highlightedText: String, lineHeight: CGFloat? = nil, action: @escaping (String) -> Void) {
        _text = Binding.constant(text)
        _height = height
        self.width = width
        self.textColor = textColor
        self.font = font
        self.highlightedText = highlightedText
        self.lineHeight = lineHeight
        self.action = action
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
        //need update parent, otherwise will be updated text from prev binding
        context.coordinator.parent = self
        let str = context.coordinator.bufferText ?? text
        if textArea.string != str || textArea.curHighlightedText != highlightedText || textArea.font != font {
            textArea.curHighlightedText = highlightedText
            textArea.string = str

            let attributedStr = NSMutableAttributedString(string: str)

            attributedStr.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: str.count))
            attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: NSRange(location: 0, length: text.count))


            let style = getStyle()

            attributedStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: str.count))

            textArea.defaultParagraphStyle = style

            if !highlightedText.isEmpty {
                let ranges = str.ranges(of: highlightedText, options: .caseInsensitive)
                for r in ranges {
                    attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: Colors.textHighlight, range: NSRange(r, in: highlightedText))
                }
            }

            textArea.textStorage?.setAttributedString(attributedStr)
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
        var bufferText: String?

        init(_ textArea: TextArea) {
            parent = textArea
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            return true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? CustomNSTextView else { return }

            if parent.action != nil {
                bufferText = textView.string
                parent.action?(textView.string)
                parent.updateHeight(textView)
            } else {
                parent.text = textView.string
            }
        }

        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            return newSelectedCharRange
        }
    }
}

class EditorController: NSViewController {
    var textView = CustomNSTextView()
    var scroller: NSScrollView?

    override func loadView() {
        let scrollView = NSScrollView()
        scroller = scrollView
        scrollView.hasVerticalScroller = true
        scrollView.backgroundColor = .clear
        scrollView.contentView.backgroundColor = .clear
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true

        textView.autoresizingMask = [.width]
        textView.backgroundColor = .clear
        textView.allowsUndo = true
        textView.isSelectable = true
        textView.isEditable = true
        textView.string = "Ag"

        scrollView.documentView = textView

        view = scrollView
    }

    override func viewDidAppear() {
        view.window?.makeFirstResponder(view)
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

struct NSTextEditor: NSViewControllerRepresentable {
    @Binding var text: String
    var font: NSFont
    let textColor: NSColor
    var lineHeight: CGFloat? = nil
    let highlightedText: String

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeNSViewController(context: Context) -> EditorController {
        let vc = EditorController()
        vc.textView.delegate = context.coordinator
        return vc
    }

    func updateNSViewController(_ nsViewController: EditorController, context: Context) {
        let textView = nsViewController.textView
        textView.curHighlightedText = highlightedText
        textView.string = text

        let attributedStr = NSMutableAttributedString(string: text)

        attributedStr.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: text.count))
        attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: NSRange(location: 0, length: text.count))

        let style = getStyle()

        attributedStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: text.count))

        textView.defaultParagraphStyle = style

        if !highlightedText.isEmpty {
            let ranges = text.ranges(of: highlightedText, options: .caseInsensitive)
            for r in ranges {
                attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: Colors.textHighlight, range: NSRange(r, in: highlightedText))
            }
        }
        
        textView.textStorage?.setAttributedString(attributedStr)
    }

    func getStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        style.firstLineHeadIndent = 0
        style.lineBreakMode = .byWordWrapping

        if let lineHeight = lineHeight {
            style.minimumLineHeight = lineHeight
            style.maximumLineHeight = lineHeight
        }

        return style
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSTextEditor

        init(_ parent: NSTextEditor) {
            self.parent = parent
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            return true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            return newSelectedCharRange
        }
    }
}

class EditableTextManager: ObservableObject {
    static var shared: EditableTextManager = EditableTextManager()
    var ownerUID: UID = UID()
    @Published var editingText: String = ""
    @Published var isEditing: Bool = false
}

struct EditableText: View {
    @ObservedObject private var notifier = EditableTextManager.shared
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
            if notifier.isEditing && notifier.ownerUID == uid {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Colors.focus.color)
                    .frame(width: proxy.size.width - 3, height: proxy.size.height - 2)
                    .offset(x: 1, y: 0)

                TextInput(title: "", text: $notifier.editingText, textColor: Colors.text, font: font, alignment: .left, isFocused: notifier.isEditing && notifier.ownerUID == uid, isSecure: false, format: nil, isEditable: notifier.isEditing && notifier.ownerUID == uid, onEnterAction: {
                    action(notifier.editingText)
                    notifier.isEditing = false
                }, onFocusChangedAction: { hasFocus in
                    if notifier.isEditing && !hasFocus {
                        notifier.isEditing = false
                    }
                }).padding(.leading, SizeConstants.padding - 2)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture(count: countClickActivation) {
                        notifier.editingText = text
                        notifier.ownerUID = uid
                        notifier.isEditing = true
                    }

            } else {
                Text(self.text)
                    .lineLimit(1)
                    .font(Font.custom(useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize))
                    .padding(.horizontal, SizeConstants.padding)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: alignment)
                    .contentShape(Rectangle())
                    .onTapGesture(count: countClickActivation) {
                        notifier.editingText = text
                        notifier.ownerUID = uid
                        notifier.isEditing = true
                    }
            }
        }
    }
}

struct EditableMultilineText: View {
    @ObservedObject private var textManager = EditableTextManager.shared
    @ObservedObject private var notifier = HeightDidChangeNotifier()
    let text: String
    let uid: UID
    let alignment: Alignment
    let width: CGFloat
    let useMonoFont: Bool
    let searchText: String
    let hasSearchMatches: Bool
    let action: (String) -> Void

    init(_ text: String, uid: UID, alignment: Alignment = .leading, width: CGFloat, useMonoFont: Bool = false, searchText: String = "", action: @escaping (String) -> Void) {
        self.text = text
        self.uid = uid
        self.alignment = alignment
        self.width = width
        self.useMonoFont = useMonoFont
        self.searchText = searchText
        self.hasSearchMatches = searchText.count > 0 ? text.hasSubstring(searchText) : false
        self.action = action
    }

    var body: some View {
        if textManager.ownerUID == uid {
            VStack(alignment: .trailing, spacing: 2) {
                TextArea(text: $textManager.editingText, height: $notifier.height, width: width - 2 * SizeConstants.padding, textColor: Colors.text, font: NSFont(name: useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize), highlightedText: "", lineHeight: SizeConstants.fontLineHeight)
                    .colorScheme(.dark)
                    .offset(x: -5)
                    .padding(.horizontal, SizeConstants.padding)
                    .frame(height: max(SizeConstants.listCellHeight - 1, notifier.height - 1))
                    .border(Colors.focus.color)

                HStack(alignment: .center, spacing: 2) {
                    TextButton(text: width < 100 ? "C" : "Cancel", textColor: Colors.appBG.color, bgColor: Colors.focus.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), padding: 5) {
                        textManager.isEditing = false
                        textManager.ownerUID = UID()
                    }
                    .cornerRadius(2)

                    TextButton(text: width < 100 ? "S" : "Save", textColor: Colors.appBG.color, bgColor: Colors.focus.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), height: SizeConstants.listCellHeight, padding: 5) {
                        action(textManager.editingText)
                        textManager.isEditing = false
                        textManager.ownerUID = UID()
                    }
                    .cornerRadius(2)
                }
            }.frame(width: width - 1)

        } else {
            
            HighlightedText(self.text, matching: self.searchText)
                        
                .font(Font.custom(useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize))
                .padding(.vertical, 5)
                .padding(.horizontal, SizeConstants.padding)
                .frame(maxHeight: .infinity, alignment: alignment)
                .frame(width: width, alignment: alignment)
                .lineLimit(nil)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    textManager.editingText = text
                    textManager.ownerUID = uid
                    textManager.isEditing = true
                }
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
        guard  let regex = try? NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: matching).trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .regularExpression, locale: .current), options: caseSensitive ? .init() : .caseInsensitive) else {
            return Text(text)
        }

        let range = NSRange(location: 0, length: text.count)
        let matches = regex.matches(in: text, options: .withTransparentBounds, range: range)

        return text.enumerated().map { (char) -> Text in
            guard matches.filter( {
                $0.range.contains(char.offset)
            }).count == 0 else {
                return Text( String(char.element) ).foregroundColor(Colors.textHighlight.color)
            }
            return Text( String(char.element) )

        }.reduce(Text("")) { (a, b) -> Text in
            return a + b
        }
    }
}


class HeightDidChangeNotifier: ObservableObject {
    @Published var height: CGFloat = 0
}
