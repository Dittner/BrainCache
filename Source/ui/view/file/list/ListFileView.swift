//
//  TableView.swift
//  BrainCache
//
//  Created by Alexander Dittner on 28.03.2021.
//

import Combine
import SwiftUI

struct ListFileView: View {
    @ObservedObject private var lc: ListController
    @ObservedObject private var file: File
    private let fileBody: ListFileBody
    @ObservedObject private var folder: Folder
    private let scrollerWidth: CGFloat = 15
    private let headerHeight: CGFloat = SizeConstants.listCellHeight

    init(file: File, fileBody: ListFileBody, folder: Folder) {
        print("ListFileBodyView init, use mono font = \(file.useMonoFont)")
        self.file = file
        self.fileBody = fileBody
        self.folder = folder
        lc = ListController(list: fileBody)
    }

    var body: some View {
        GeometryReader { proxy in
            ListHeaderView(lc: lc, useMonoFont: file.useMonoFont)
                .frame(width: proxy.size.width - scrollerWidth, height: headerHeight)

            VScrollBar(uid: file.uid) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(fileBody.columns, id: \.uid) { column in
                        ListColumnCell(column: column, useMonoFont: file.useMonoFont, searchText: folder.search, width: column.ratio * (proxy.size.width - scrollerWidth), minHeight: proxy.size.height - SizeConstants.listCellHeight - headerHeight)
                            .frame(width: column.ratio * (proxy.size.width - scrollerWidth))
                    }
                }
            }
            .padding(.top, headerHeight)
            .frame(width: proxy.size.width, height: proxy.size.height - headerHeight)

            HSeparatorView()
                .offset(y: headerHeight)

            VSeparatorView()
                .offset(x: proxy.size.width - scrollerWidth)

            ListLinesView(lc)
                .frame(width: proxy.size.width - scrollerWidth)
        }
    }
}

struct ListHeaderView: View {
    @ObservedObject private var lc: ListController
    @ObservedObject private var dragProcessor: ListColumnDragProcessor
    let useMonoFont: Bool

    init(lc: ListController, useMonoFont: Bool) {
        self.lc = lc
        self.dragProcessor = lc.listColumnDragProcessor
        self.useMonoFont = useMonoFont
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {
                ForEach(lc.list.columns.enumeratedArray(), id: \.offset) { _, column in
                    EditableText(column.title, uid: column.uid, alignment: .center, useMonoFont: useMonoFont) { value in
                        self.lc.updateColumn(column, title: value)
                        column.title = value
                    }
                    .foregroundColor(Colors.textDark.color)
                    .frame(width: column.ratio * geometry.size.width, height: SizeConstants.listCellHeight)
                    .border(dragProcessor.dropCandidate?.uid == column.uid ? Colors.focusColor.color : Colors.clear.color)
                    .onDrag { self.dragProcessor.draggingColumn = column; return NSItemProvider(object: NSString()) }
                    .onDrop(of: ["public.plain-text"], delegate: ListColumnDropViewDelegate(destColumn: column, dragProcessor: dragProcessor))
                }
            }.frame(height: SizeConstants.listCellHeight)
        }
    }
}

struct ListColumnCell: View {
    @ObservedObject private var column: ListColumn
    @ObservedObject private var notifier = HeightDidChangeNotifier()
    let useMonoFont: Bool
    let searchText: String
    let font: NSFont
    let width: CGFloat
    let minHeight: CGFloat

    init(column: ListColumn, useMonoFont: Bool, searchText: String, width: CGFloat, minHeight: CGFloat) {
        print("ListColumnCell init, useMonoFont = \(useMonoFont)")
        self.column = column
        self.useMonoFont = useMonoFont
        self.searchText = searchText
        self.width = width
        self.minHeight = minHeight
        font = NSFont(name: useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize)
    }

    var body: some View {
        TextArea(text: $column.text, height: $notifier.height, textColor: Colors.text, font: font, highlightedText: searchText, lineHeight: SizeConstants.fontLineHeight, width: width - 2 * SizeConstants.padding)
            .colorScheme(.dark)
            .offset(x: -4)
            .padding(.horizontal, SizeConstants.padding)
            .frame(height: max(minHeight - 5, notifier.height))
    }
}

struct ListLinesView: View {
    @ObservedObject private var dragProcessor: ColumnLineDragProcessor
    @ObservedObject private var lc: ListController

    init(_ lc: ListController) {
        self.lc = lc
        dragProcessor = lc.columnLineDragProcessor
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(lc.lines, id: \.id) { line in
                ColumnLineView()
                    .offset(x: line.uid == self.dragProcessor.curDragLine?.uid ? line.position * geometry.size.width + self.dragProcessor.curDragOffset : line.position * geometry.size.width)
                    .gesture(DragGesture()
                        .onChanged { gesture in
                            if line.uid != self.dragProcessor.curDragLine?.uid {
                                self.dragProcessor.curDragLine = line
                            }

                            if self.dragProcessor.isDragEnabled(with: gesture.translation.width / geometry.size.width) {
                                self.dragProcessor.curDragOffset = gesture.translation.width
                            }
                        }
                        .onEnded { _ in
                            self.dragProcessor.dragDidEnd(with: self.dragProcessor.curDragOffset / geometry.size.width)
                        }
                    )
            }
        }
    }
}

struct ColumnLineView: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.1)
                .frame(width: 1)
                .frame(maxHeight: .infinity)

            Colors.clear.color
                .frame(width: 10)
                .frame(maxHeight: .infinity)
                .onHover { inside in
                    if inside {
                        NSCursor.resizeLeftRight.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
        }
        .frame(width: 1)
        .zIndex(1)
    }
}
