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

        if text != textView.string || textView.curHighlightedText != highlightedText {
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
                    //attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: Colors.textHighlight, range: NSRange(r, in: highlightedText))
                }
            }

            textView.textStorage?.setAttributedString(attributedStr)

            textView.font = font
            textView.textColor = textColor

            // context.coordinator.shouldUpdateText = false
            // context.coordinator.shouldUpdateText = true
        }

//        let layoutManager: NSLayoutManager = nsViewController.textView.layoutManager!
//        let numberOfGlyphs = layoutManager.numberOfGlyphs
//        var index: Int = 0
//        var lineRange = NSRange(location: NSNotFound, length: 0)
//        var numberOfLines: Int = 0
//
//        while index < numberOfGlyphs {
//            layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
//            index = NSMaxRange(lineRange)
//            numberOfLines += 1
//        }
//
//        if nsViewController.textView.string.last == "\n" {
//            numberOfLines += 1
//        }
//
//        print("numberOfLines = \(numberOfLines)")
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

class Coordinator2: NSObject, NSTextStorageDelegate {
    private var parent: NSTextEditor
    var shouldUpdateText = true

    init(_ parent: NSTextEditor) {
        self.parent = parent
    }

    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard shouldUpdateText else {
            return
        }
        let edited = textStorage.attributedSubstring(from: editedRange).string
        let insertIndex = parent.text.utf16.index(parent.text.utf16.startIndex, offsetBy: editedRange.lowerBound)

        func numberOfCharactersToDelete() -> Int {
            editedRange.length - delta
        }

        let endIndex = parent.text.utf16.index(insertIndex, offsetBy: numberOfCharactersToDelete())
        parent.text.replaceSubrange(insertIndex ..< endIndex, with: edited)
    }
}

