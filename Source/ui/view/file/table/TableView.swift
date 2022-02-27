//
//  TableView.swift
//  BrainCache
//
//  Created by Alexander Dittner on 28.03.2021.
//

import Combine
import SwiftUI

struct TableFileView: View {
    @ObservedObject private var vm = FolderListVM.shared
    @ObservedObject private var tc: TableController
    @ObservedObject private var file: File
    private let fileBody: TableFileBody
    private let scrollerWidth: CGFloat = 15

    init(file: File, fileBody: TableFileBody) {
        print("TableContentView init, use mono font = \(file.useMonoFont)")
        self.file = file
        self.fileBody = fileBody
        tc = TableController(table: fileBody)
    }

    func getCellWidth(header: TableHeader, rootWidth: CGFloat) -> CGFloat {
        header.ratio * (rootWidth - SizeConstants.tableRowNumberWidth - scrollerWidth)
    }

    var body: some View {
        GeometryReader { root in
            Colors.black01.color
                .frame(width: SizeConstants.tableRowNumberWidth)

            TableHeaderView(tc, useMonoFont: file.useMonoFont)
                .offset(x: SizeConstants.tableRowNumberWidth)
                .frame(width: root.size.width - scrollerWidth - SizeConstants.tableRowNumberWidth, height: SizeConstants.listCellHeight)

            VScrollBar(uid: file.uid) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(fileBody.rows.enumeratedArray(), id: \.offset) { rowIndex, row in
                        HStack(alignment: .top, spacing: 0) {
                            Text("\(rowIndex + 1)")
                                .lineLimit(1)
                                .font(Font.custom(file.useMonoFont ? .mono : .def, size: SizeConstants.fontSize))
                                .foregroundColor(Colors.textDark.color)
                                .padding(.horizontal, SizeConstants.padding)
                                .padding(.top, 5)
                                .frame(width: SizeConstants.tableRowNumberWidth, alignment: .trailing)

                            ForEach(row.cells.enumeratedArray(), id: \.offset) { index, cell in
                                EditableMultilineText(cell.text, uid: cell.uid, alignment: .leading, width: getCellWidth(header: fileBody.headers[index], rootWidth: root.size.width), useMonoFont: file.useMonoFont, searchText: vm.search) { value in
                                    self.tc.updateCell(cell, text: value)
                                }
                                .foregroundColor(Colors.text.color)
                                .frame(width: getCellWidth(header: fileBody.headers[index], rootWidth: root.size.width))
                            }
                        }.offset(y: -3)
                        HSeparatorView()
                    }
                    
                    Spacer().frame(maxWidth: .infinity, maxHeight: 1)

                    TextButton(text: "Add Row", textColor: Colors.button.color, font: Font.custom(.pragmatica, size: SizeConstants.fontSize), padding: 5) {
                        self.tc.addTableRow()
                    }
                }.frame(width: root.size.width - scrollerWidth)
            }
            .frame(width: root.size.width, height: root.size.height - SizeConstants.listCellHeight)
            .padding(.top, SizeConstants.listCellHeight)
            .clipped()

            HSeparatorView()
                .offset(y: SizeConstants.listCellHeight)

            VSeparatorView()
                .offset(x: SizeConstants.tableRowNumberWidth)

            VSeparatorView()
                .offset(x: root.size.width - scrollerWidth)

            TableLinesView(tc)
                .offset(x: SizeConstants.tableRowNumberWidth - 1)
                .frame(width: root.size.width - scrollerWidth - SizeConstants.tableRowNumberWidth)
        }
    }
}

struct TableHeaderView: View {
    @ObservedObject private var tc: TableController
    @ObservedObject private var dragProcessor: TableHeaderDragProcessor
    let useMonoFont: Bool

    init(_ tc: TableController, useMonoFont: Bool) {
        self.tc = tc
        dragProcessor = tc.tableHeaderDragProcessor
        self.useMonoFont = useMonoFont
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {
                ForEach(tc.table.headers.enumeratedArray(), id: \.offset) { index, header in
                    ZStack(alignment: .leading) {
                        EditableText(header.title, uid: header.uid, alignment: .center, useMonoFont: useMonoFont) { value in
                            self.tc.updateHeader(header, title: value)
                        }

                        if tc.table.sortByHeaderIndex == index {
                            IconButton(name: .sort, size: SizeConstants.fontSize, color: tc.table.sortByHeaderIndex == index ? Colors.textLight.color : Colors.textDark.color) {
                                self.tc.updateSort(headerIndex: index)
                            }
                            .rotationEffect(.degrees(tc.table.sortType == .ascending ? 180 : 0))
                            .offset(x: header.ratio * geometry.size.width - 25)
                            .zIndex(2)
                        }
                    }
                    .onDrag { self.dragProcessor.draggingHeader = header; return NSItemProvider(object: NSString()) }
                    .onDrop(of: ["public.plain-text"], delegate: TableHeaderDropViewDelegate(destHeader: header, dragProcessor: dragProcessor))
                    .foregroundColor(tc.table.sortByHeaderIndex == index ? Colors.textLight.color : Colors.textDark.color)
                    .frame(width: header.ratio * geometry.size.width, height: SizeConstants.listCellHeight)
                    .border(dragProcessor.dropCandidate?.uid == header.uid ? Colors.focus.color : Colors.clear.color)
                    .if(tc.table.sortByHeaderIndex != index) {
                        $0.highPriorityGesture(
                            TapGesture()
                                .onEnded { _ in
                                    self.tc.updateSort(headerIndex: index)
                                }
                        )
                    }
                }
            }.frame(height: SizeConstants.listCellHeight)
        }
    }
}

struct TableLinesView: View {
    @ObservedObject private var tc: TableController
    @ObservedObject private var dragProcessor: TableLineDragProcessor

    init(_ tc: TableController) {
        self.tc = tc
        dragProcessor = tc.tableLineDragProcessor
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(tc.lines, id: \.id) { line in
                TableLineView()
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

struct TableLineView: View {
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
