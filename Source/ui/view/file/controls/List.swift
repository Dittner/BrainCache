//
//  ListController.swift
//  BrainCache
//
//  Created by Alexander Dittner on 27.01.2020.
//  Copyright © 2020 Alexander Dittner. All rights reserved.
//

import Combine
import SwiftUI

class ColumnLineDragProcessor: ObservableObject {
    @Published var curDragOffset: CGFloat = 0
    @Published var curDragLine: ColumnLine? = nil
    
    private let minRatio: CGFloat = 0.05

    func dragDidEnd(with relativeOffset: CGFloat) {
        if let curDragLine = curDragLine {
            var offset: CGFloat = 0
            if curDragLine.leftColumn.ratio + relativeOffset < minRatio {
                offset = minRatio - curDragLine.leftColumn.ratio
            } else if curDragLine.rightColumn.ratio - relativeOffset < minRatio {
                offset = curDragLine.rightColumn.ratio - minRatio
            } else {
                offset = relativeOffset
            }
            curDragLine.position += offset
            curDragLine.leftColumn.ratio += offset
            curDragLine.rightColumn.ratio -= offset
        }
        curDragLine = nil
        curDragOffset = 0
    }

    func isDragEnabled(with relativeOffset: CGFloat) -> Bool {
        if let curDragLine = curDragLine {
            return curDragLine.leftColumn.ratio + relativeOffset > minRatio && curDragLine.rightColumn.ratio - relativeOffset > minRatio
        }
        return false
    }
}

class ListController: ObservableObject {
    @Published var stateDidChange: Bool = false

    var lines: [ColumnLine] = []
    let list: ListFileBody
    let dragProcessor: ColumnLineDragProcessor
    

    private var disposeBag: Set<AnyCancellable> = []
    init(list: ListFileBody) {
        self.list = list
        dragProcessor = ColumnLineDragProcessor()
        updateListLines()
        list.stateDidChange
            .filter { $0 != .listText }
            .sink { event in
                self.updateListLines()
                self.updateListView()
            }
            .store(in: &disposeBag)
    }

    private func updateListLines() {
        lines = []
        var total: CGFloat = 0
        for (index, c) in list.columns.enumerated() {
            if index < list.columns.count - 1 {
                total += c.ratio
                let line = ColumnLine(position: total, leftColumn: list.columns[index], rightColumn: list.columns[index + 1])
                lines.append(line)
            }
        }
    }

    func updateListView() {
        stateDidChange = true
    }

    func updateColumn(_ column: ListColumn, title: String) {
        column.title = title
    }
}

struct ListLinesView: View {
    @ObservedObject private var dragProcessor: ColumnLineDragProcessor
    @ObservedObject private var lc: ListController

    init(_ lc: ListController) {
        self.lc = lc
        self.dragProcessor = lc.dragProcessor
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

class ColumnLine: ObservableObject, Identifiable {
    let uid = UID()
    @Published var position: CGFloat
    @Published var leftColumn: ListColumn
    @Published var rightColumn: ListColumn

    init(position: CGFloat, leftColumn: ListColumn, rightColumn: ListColumn) {
        self.position = position
        self.leftColumn = leftColumn
        self.rightColumn = rightColumn
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

struct ListHeaderView: View {
    @ObservedObject private var lc: ListController

    let useMonoFont: Bool

    init(lc: ListController, useMonoFont: Bool) {
        self.lc = lc
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
                }
            }.frame(height: SizeConstants.listCellHeight)
        }
    }
}
