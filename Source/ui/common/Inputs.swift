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

    override func loadView() {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.backgroundColor = .clear
        scrollView.contentView.backgroundColor = .clear
        scrollView.drawsBackground = false

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
}

struct NSTextEditor: NSViewControllerRepresentable {
    @Binding var text: String
    var font: NSFont
    let textColor: NSColor
    let lineHeight: CGFloat?
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
    let action: (String) -> Void

    init(_ text: String, uid: UID, alignment: Alignment = .leading, useMonoFont: Bool = false, action: @escaping (String) -> Void) {
        self.text = text
        self.uid = uid
        self.alignment = alignment
        self.useMonoFont = useMonoFont
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
                    .onTapGesture(count: 2) {
                        notifier.editingText = text
                        notifier.ownerUID = uid
                        notifier.isEditing = true
                    }
            }
        }
    }
}

struct EditableMultilineText: View {
    @ObservedObject private var notifier = EditableTextManager.shared
    let text: String
    let uid: UID
    let alignment: Alignment
    let useMonoFont: Bool
    let searchText: String
    let action: (String) -> Void

    init(_ text: String, uid: UID, alignment: Alignment = .leading, useMonoFont: Bool = false, searchText: String = "", action: @escaping (String) -> Void) {
        self.text = text
        self.uid = uid
        self.alignment = alignment
        self.useMonoFont = useMonoFont
        self.searchText = searchText
        self.action = action
    }

    var body: some View {
        if notifier.isEditing && notifier.ownerUID == uid {
            VStack(alignment: .trailing, spacing: 2) {
                if useMonoFont {
                    NSTextEditor(text: $notifier.editingText, font: NSFont(name: .mono, size: SizeConstants.fontSize), textColor: Colors.text, lineHeight: SizeConstants.fontLineHeight, highlightedText: searchText)
                        .padding(.leading, SizeConstants.padding - 5)
                        .frame(height: SizeConstants.listCellHeight * 8)
                        .border(Colors.focusColor.color)
                } else {
                    NSTextEditor(text: $notifier.editingText, font: NSFont(name: .pragmatica, size: SizeConstants.fontSize), textColor: Colors.text, lineHeight: SizeConstants.fontLineHeight, highlightedText: searchText)
                        .padding(.leading, SizeConstants.padding - 5)
                        .frame(height: SizeConstants.listCellHeight * 8)
                        .border(Colors.focusColor.color)
                }

                HStack(alignment: /*@START_MENU_TOKEN@*/ .center/*@END_MENU_TOKEN@*/, spacing: 2) {
                    TextButton(text: "Cancel", textColor: Colors.appBG.color, bgColor: Colors.focusColor.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), padding: 5) {
                        notifier.isEditing = false
                    }
                    .cornerRadius(2)

                    TextButton(text: "Save", textColor: Colors.appBG.color, bgColor: Colors.focusColor.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), height: SizeConstants.listCellHeight, padding: 5) {
                        action(notifier.editingText)
                        notifier.isEditing = false
                    }
                    .cornerRadius(2)
                }
            }

        } else {
            Text(self.text)
                .font(Font.custom(useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize))
                .padding(.vertical, 5)
                .padding(.horizontal, SizeConstants.padding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                .lineLimit(nil)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    notifier.editingText = text
                    notifier.ownerUID = uid
                    notifier.isEditing = true
                }
        }
    }
}
