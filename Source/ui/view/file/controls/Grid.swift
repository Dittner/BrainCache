//
//  SwiftUI.swift
//  BrainCache
//
//  Created by Alexander Dittner on 27.01.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import SwiftUI

class GridController: ObservableObject {
    @Published var lines: [GridLine] = []
    @Published var table: TableFileBody

    @Published var curDragOffset: CGFloat = 0
    @Published var curDragLine: GridLine? = nil
    private let minRation: CGFloat = 0.05

    init(table: TableFileBody) {
        self.table = table

        var total: CGFloat = 0
        for (index, h) in table.headers.enumerated() {
            if index < table.headers.count - 1 {
                total += h.ratio
                let line = GridLine(position: total, leftColumn: table.headers[index], rightColumn: table.headers[index + 1])
                lines.append(line)
            }
        }
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

    func updateHeader(_ header: TableHeader, title: String) {
        table.updateHeaderTitle(header, title: title)
    }

    func updateCell(_ cell: TableCell, text: String) {
        table.updateCell(cell, with: text)
    }

    func addTableRow() {
        let row = TableRow(cells: [])
        for _ in 0 ... table.headers.count - 1 {
            row.cells.append(TableCell(text: ""))
        }
        table.rows.append(row)
    }

    func updateGridView() {
        curDragLine = nil
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
                ForEach(gc.table.headers, id: \.uid) { header in
                    EditableText(header.title, uid: header.uid, alignment: .center, useMonoFont: useMonoFont) { value in
                        self.gc.updateHeader(header, title: value)
                        self.gc.updateGridView()
                    }
                    .foregroundColor(Colors.text.color)
                    .frame(width: header.ratio * geometry.size.width, height: SizeConstants.listCellHeight)
                }
            }.frame(height: SizeConstants.listCellHeight)
        }
    }
}

struct GridLinesView: View {
    @ObservedObject private var gc: GridController

    init(_ gc: GridController) {
        self.gc = gc
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(gc.lines, id: \.id) { line in
                GridLineView()
                    .offset(x: line.uid == self.gc.curDragLine?.uid ? line.position * geometry.size.width + self.gc.curDragOffset : line.position * geometry.size.width)
                    .gesture(DragGesture()
                        .onChanged { gesture in
                            if line.uid != self.gc.curDragLine?.uid {
                                self.gc.curDragLine = line
                            }

                            if self.gc.isDragEnabled(with: gesture.translation.width / geometry.size.width) {
                                self.gc.curDragOffset = gesture.translation.width
                            }
                        }
                        .onEnded { _ in
                            self.gc.dragDidEnd(with: self.gc.curDragOffset / geometry.size.width)
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
