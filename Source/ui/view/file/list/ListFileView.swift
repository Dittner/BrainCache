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
    @ObservedObject private var vm = FolderListVM.shared
    private let scrollerWidth: CGFloat = 15
    private let headerHeight: CGFloat = SizeConstants.listCellHeight

    init(file: File, fileBody: ListFileBody) {
        self.file = file
        self.fileBody = fileBody
        lc = ListController(list: fileBody)
    }

    var body: some View {
        GeometryReader { proxy in
            ListHeaderView(lc: lc, useMonoFont: file.useMonoFont)
                .frame(width: proxy.size.width - scrollerWidth, height: headerHeight)

            VScrollBar(uid: file.uid) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(fileBody.columns, id: \.uid) { column in
                        ListColumnCell(lc: lc, column: column, useMonoFont: file.useMonoFont, searchText: vm.search, width: column.ratio * (proxy.size.width - scrollerWidth), minHeight: proxy.size.height - SizeConstants.listCellHeight - headerHeight)
                            .frame(width: column.ratio * (proxy.size.width - scrollerWidth))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .if(file.useMonoFont) {
                    $0.background(ListFileBG())
                }
            }
            .offset(y: headerHeight)
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

struct ListFileBG: View {
    private let lineRowHeight: CGFloat = SizeConstants.fontLineHeight

    func getYOffset(scrollPos: CGFloat) -> CGFloat {
        return CGFloat(Double(scrollPos).remainder(dividingBy: Double(lineRowHeight)))
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: lineRowHeight) {
                ForEach(1 ... Int(proxy.size.height / lineRowHeight) + 2, id: \.self) { row in
                    if row % 2 == 0 {
                        Colors.black01.color.frame(width: proxy.size.width, height: lineRowHeight)
                    }
                }
            }.allowsHitTesting(false)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
    }
}

struct ListHeaderView: View {
    @ObservedObject private var lc: ListController
    @ObservedObject private var dragProcessor: ListColumnDragProcessor
    let useMonoFont: Bool

    init(lc: ListController, useMonoFont: Bool) {
        self.lc = lc
        dragProcessor = lc.listColumnDragProcessor
        self.useMonoFont = useMonoFont
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {
                ForEach(lc.list.columns.enumeratedArray(), id: \.offset) { _, column in
                    EditableText(column.title, uid: column.uid, alignment: .center, useMonoFont: useMonoFont) { value in
                        self.lc.updateColumn(column, title: value)
                        lc.updateColumn(column, title: value)
                    }
                    .foregroundColor(Colors.textDark.color)
                    .frame(width: column.ratio * geometry.size.width, height: SizeConstants.listCellHeight)
                    .border(dragProcessor.dropCandidate?.uid == column.uid ? Colors.focus.color : Colors.clear.color)
                    .onDrag { self.dragProcessor.draggingColumn = column; return NSItemProvider(object: NSString()) }
                    .onDrop(of: ["public.plain-text"], delegate: ListColumnDropViewDelegate(destColumn: column, dragProcessor: dragProcessor))
                }
            }.frame(height: SizeConstants.listCellHeight)
        }
    }
}

struct ListColumnCell: View {
    private let lc: ListController
    private let column: ListColumn
    @ObservedObject private var textBuffer = TextBuffer()
    @ObservedObject private var notifier = HeightDidChangeNotifier()
    let useMonoFont: Bool
    let searchText: String
    let font: NSFont
    let width: CGFloat
    let minHeight: CGFloat
    private var subscription: AnyCancellable?
    
    init(lc: ListController, column: ListColumn, useMonoFont: Bool, searchText: String, width: CGFloat, minHeight: CGFloat) {
        self.lc = lc
        self.column = column
        self.useMonoFont = useMonoFont
        self.searchText = searchText
        self.width = width
        self.minHeight = minHeight
        font = NSFont(name: useMonoFont ? .mono : .pragmatica, size: SizeConstants.fontSize)
        
        textBuffer.text = column.text
        subscription = textBuffer.$text
            .dropFirst()
            .removeDuplicates()
            .sink { value in
                lc.updateColumn(column, text: value)
            }
    }

    var body: some View {
        TextArea(text: $textBuffer.text, height: $notifier.height, width: width - 2 * SizeConstants.padding, textColor: Colors.text, font: font, highlightedText: searchText, lineHeight: SizeConstants.fontLineHeight)
        .colorScheme(.dark)
        .offset(x: -4, y: -2)
        .padding(.horizontal, SizeConstants.padding)
        .frame(height: max(minHeight - 5, notifier.height))
    }
}

struct ListLinesView: View {
    @ObservedObject private var lc: ListController
    @ObservedObject private var dragProcessor: ColumnLineDragProcessor

    init(_ lc: ListController) {
        self.lc = lc
        dragProcessor = lc.columnLineDragProcessor
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(lc.lines, id: \.uid) { line in
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
            VSeparatorView()

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
