//
//  NSTextEditor.swift
//  BrainCache
//
//  Created by Alexander Dittner on 27.01.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import SwiftUI

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
            print("textView no layoutManager or textContainer")
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
        // vc.textView.textStorage?.delegate = context.coordinator
        return vc
    }

    func updateNSViewController(_ nsViewController: EditorController, context: Context) {
        let textView = nsViewController.textView
        textView.curHighlightedText = highlightedText
        textView.string = text

        let attributedStr = NSMutableAttributedString(string: text)

        attributedStr.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: text.count))

        let style = getStyle()

        attributedStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: text.count))

        textView.defaultParagraphStyle = style

        if !highlightedText.isEmpty {
            let ranges = text.ranges(of: highlightedText, options: .caseInsensitive)
            for r in ranges {
                attributedStr.addAttribute(NSAttributedString.Key.backgroundColor, value: Colors.textHighlightBG, range: NSRange(r, in: highlightedText))
            }
        }

        textView.textStorage?.setAttributedString(attributedStr)

        textView.font = font
        textView.textColor = textColor
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

    init(_ text: String, uid: UID, alignment: Alignment = .leading, useMonoFont: Bool = false, countClickActivation:Int = 2, action: @escaping (String) -> Void) {
        self.text = text
        self.uid = uid
        self.alignment = alignment
        self.useMonoFont = useMonoFont
        self.countClickActivation = countClickActivation
        self.action = action
    }

    var body: some View {
        GeometryReader { proxy in
            if notifier.isEditing && notifier.ownerUID == uid {
                TextField("", text: $notifier.editingText, onEditingChanged: { editing in
                    notifier.isEditing = editing
                }, onCommit: {
                    action(notifier.editingText)
                    notifier.isEditing = false
                })
                .focusable()
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(Font.custom(useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize))
                    .padding(.horizontal, SizeConstants.padding)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .border(Colors.focusColor.color)
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
    let action: (String) -> Void

    init(_ text: String, uid: UID, alignment: Alignment = .leading, width: CGFloat, useMonoFont: Bool = false, searchText: String = "", action: @escaping (String) -> Void) {
        self.text = text
        self.uid = uid
        self.alignment = alignment
        self.width = width
        self.useMonoFont = useMonoFont
        self.searchText = searchText
        self.action = action
    }

    var body: some View {
        if textManager.isEditing && textManager.ownerUID == uid {
            VStack(alignment: .trailing, spacing: 2) {
                TextArea(text: $textManager.editingText, height: $notifier.height, textColor: Colors.text, font: NSFont(name: useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize), highlightedText: searchText, lineHeight: SizeConstants.fontLineHeight, width: width - 2 * SizeConstants.padding)
                    .colorScheme(.dark)
                    .offset(x: -4)
                    .padding(.horizontal, SizeConstants.padding)
                    .frame(height: max(SizeConstants.listCellHeight, notifier.height))
                    .border(Colors.focusColor.color)

                HStack(alignment: .center, spacing: 2) {
                    TextButton(text: "Cancel", textColor: Colors.appBG.color, bgColor: Colors.focusColor.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), padding: 5) {
                        textManager.isEditing = false
                    }
                    .cornerRadius(2)

                    TextButton(text: "Save", textColor: Colors.appBG.color, bgColor: Colors.focusColor.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), height: SizeConstants.listCellHeight, padding: 5) {
                        action(textManager.editingText)
                        textManager.isEditing = false
                    }
                    .cornerRadius(2)
                }
            }

        } else {
            Text(self.text)
                .font(Font.custom(useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize))
                .padding(.vertical, 5)
                .padding(.horizontal, SizeConstants.padding)
                .frame(maxHeight: .infinity, alignment: alignment)
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

struct TextArea: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    let textColor: NSColor
    let font: NSFont
    var highlightedText: String = ""
    var lineHeight: CGFloat? = nil
    var width: CGFloat

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

        if let lineHeight = lineHeight {
            style.minimumLineHeight = lineHeight
            style.maximumLineHeight = lineHeight
            style.lineHeightMultiple = lineHeight
        }

        return style
    }

    func updateNSView(_ textArea: CustomNSTextView, context: Context) {
        if textArea.string != text || textArea.curHighlightedText != highlightedText || textArea.font != self.font {
            textArea.curHighlightedText = highlightedText
            textArea.string = text

            let attributedStr = NSMutableAttributedString(string: text)

            attributedStr.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location: 0, length: text.count))

            let style = getStyle()

            attributedStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: text.count))

            textArea.defaultParagraphStyle = style

            if !highlightedText.isEmpty {
                let ranges = text.ranges(of: highlightedText, options: .caseInsensitive)
                for r in ranges {
                    attributedStr.addAttribute(NSAttributedString.Key.backgroundColor, value: Colors.textHighlightBG, range: NSRange(r, in: highlightedText))
                }
            }

            textArea.textStorage?.setAttributedString(attributedStr)
            textArea.font = font
            textArea.textColor = textColor
        }

        textArea.textContainer?.containerSize.width = width
        if height != textArea.contentSize.height {
            height = textArea.contentSize.height
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
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            return newSelectedCharRange
        }
    }
}


class HeightDidChangeNotifier: ObservableObject {
    @Published var height: CGFloat = 0
}
