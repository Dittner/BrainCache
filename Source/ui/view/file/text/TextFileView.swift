//
//  TableView.swift
//  BrainCache
//
//  Created by Alexander Dittner on 28.03.2021.
//

import Combine
import SwiftUI

struct TextFileView: View {
    @ObservedObject private var file: File
    private let fileBody: TextFileBody
    @ObservedObject private var vm = FolderListVM.shared
    @ObservedObject private var notifier = HeightDidChangeNotifier()

    init(file: File, fileBody: TextFileBody) {
        self.file = file
        self.fileBody = fileBody
    }

    var body: some View {
        GeometryReader { proxy in
            VScrollBar(uid: file.uid) {
                TextFileBodyView(fileBody: fileBody, useMonoFont: file.useMonoFont, searchText: vm.search, width: proxy.size.width, minHeight: proxy.size.height)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct TextFileBodyView: View {
    @ObservedObject private var fileBody: TextFileBody
    @ObservedObject private var notifier = HeightDidChangeNotifier()
    let useMonoFont: Bool
    let searchText: String
    let font: NSFont
    let width: CGFloat
    let minHeight: CGFloat

    init(fileBody: TextFileBody, useMonoFont: Bool, searchText: String, width: CGFloat, minHeight: CGFloat) {
        print("TextFileBodyView init, useMonoFont = \(useMonoFont)")
        self.fileBody = fileBody
        self.useMonoFont = useMonoFont
        self.searchText = searchText
        self.width = width
        self.minHeight = minHeight
        font = NSFont(name: useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize)
    }

    var body: some View {
        TextArea(text: $fileBody.text, height: $notifier.height, width: width - 2 * SizeConstants.padding, textColor: Colors.text, font: font, highlightedText: searchText, lineHeight: SizeConstants.fontLineHeight)
            .colorScheme(.dark)
            .offset(x: -4)
            .padding(.horizontal, SizeConstants.padding)
            .frame(height: max(minHeight - 5, notifier.height))
    }
}
