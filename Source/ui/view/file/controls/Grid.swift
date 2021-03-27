//
//  SwiftUI.swift
//  BrainCache
//
//  Created by Alexander Dittner on 27.01.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Combine
import SwiftUI

class TableLineDragProcessor: ObservableObject {
    @Published var curDragOffset: CGFloat = 0
    @Published var curDragLine: GridLine? = nil
    private let minRation: CGFloat = 0.05
    let table: TableFileBody
    init(_ table:TableFileBody) {
        self.table = table
    }

    func dragDidEnd(with relativeOffset: CGFloat) {
        if let curDragLine = curDragLine {
            var offset: CGFloat = 0
            if curDragLine.leftColumn.ratio + relativeOffset < minRation {
                offset = minRation - curDragLine.leftColumn.ratio
            } else if curDragLine.rightColumn.ratio - relativeOffset < minRation {
                offset = curDragLine.rightColumn.ratio - minRation
            } else {
                offset = relativeOffset
            }
            curDragLine.position += offset
            table.updateHeaderRation(curDragLine.leftColumn, ration: curDragLine.leftColumn.ratio + offset)
            table.updateHeaderRation(curDragLine.rightColumn, ration: curDragLine.rightColumn.ratio - offset)
        }
        curDragLine = nil
        curDragOffset = 0
    }

    func isDragEnabled(with relativeOffset: CGFloat) -> Bool {
        if let curDragLine = curDragLine {
            return curDragLine.leftColumn.ratio + relativeOffset > minRation && curDragLine.rightColumn.ratio - relativeOffset > minRation
        }
        return false
    }
}

class GridController: ObservableObject {
    @Published var lines: [GridLine] = []
    @Published var stateDidChange: Bool = false
    let table: TableFileBody
    let dragProcessor: TableLineDragProcessor

    private var disposeBag: Set<AnyCancellable> = []
    init(table: TableFileBody) {
        self.table = table
        dragProcessor = TableLineDragProcessor(table)
        updateGridlines()
        table.stateDidChange
            .sink { _ in
                self.updateGridlines()
                self.updateGridView()
            }
            .store(in: &disposeBag)
    }

    private func updateGridlines() {
        lines = []
        var total: CGFloat = 0
        for (index, h) in table.headers.enumerated() {
            if index < table.headers.count - 1 {
                total += h.ratio
                let line = GridLine(position: total, leftColumn: table.headers[index], rightColumn: table.headers[index + 1])
                lines.append(line)
            }
        }
    }
    
    private func updateGridView() {
        stateDidChange = true
    }

    func updateHeader(_ header: TableHeader, title: String) {
        table.updateHeaderTitle(header, title: title)
    }

    func updateCell(_ cell: TableCell, text: String) {
        table.updateCell(cell, with: text)
    }

    func updateSort(headerIndex: Int) {
        if table.sortByHeaderIndex == headerIndex {
            table.updateSorting(headerIndex: headerIndex, type: table.sortType == .ascending ? .descending : .ascending)
        } else {
            table.updateSorting(headerIndex: headerIndex, type: .ascending)
        }
    }

    func addTableRow() {
        table.addNewRow()
    }

    
}

struct GridHeaderView: View {
    @ObservedObject private var gc: GridController
    let useMonoFont: Bool

    init(_ gc: GridController, useMonoFont: Bool) {
        self.gc = gc
        self.useMonoFont = useMonoFont
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {
                ForEach(gc.table.headers.enumeratedArray(), id: \.offset) { index, header in
                    ZStack(alignment: .leading) {
                        EditableText(header.title, uid: header.uid, alignment: .center, useMonoFont: useMonoFont) { value in
                            self.gc.updateHeader(header, title: value)
                        }

                        if gc.table.sortByHeaderIndex == index {
                            IconButton(name: .sort, size: SizeConstants.fontSize, color: gc.table.sortByHeaderIndex == index ? Colors.textLight.color : Colors.textDark.color) {
                                self.gc.updateSort(headerIndex: index)
                            }
                            .rotationEffect(.degrees(gc.table.sortType == .ascending ? 180 : 0))
                            .offset(x: header.ratio * geometry.size.width - 25)
                            .zIndex(2)
                        }
                    }
                    .foregroundColor(gc.table.sortByHeaderIndex == index ? Colors.textLight.color : Colors.textDark.color)
                    .frame(width: header.ratio * geometry.size.width, height: SizeConstants.listCellHeight)
                    .if(gc.table.sortByHeaderIndex != index) {
                        $0.highPriorityGesture(
                            TapGesture()
                                .onEnded { _ in
                                    self.gc.updateSort(headerIndex: index)
                                }
                        )
                    }
                }
            }.frame(height: SizeConstants.listCellHeight)
        }
    }
}

struct GridLinesView: View {
    @ObservedObject private var gc: GridController
    @ObservedObject private var dragProcessor: TableLineDragProcessor

    init(_ gc: GridController) {
        self.gc = gc
        self.dragProcessor = gc.dragProcessor
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(gc.lines, id: \.id) { line in
                GridLineView()
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

class GridLine: ObservableObject, Identifiable {
    let uid = UID()
    @Published var position: CGFloat
    @Published var leftColumn: TableHeader
    @Published var rightColumn: TableHeader

    init(position: CGFloat, leftColumn: TableHeader, rightColumn: TableHeader) {
        self.position = position
        self.leftColumn = leftColumn
        self.rightColumn = rightColumn
    }
}

struct GridLineView: View {
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
