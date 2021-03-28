//
//  ListController.swift
//  BrainCache
//
//  Created by Alexander Dittner on 28.03.2021.
//

import Combine
import SwiftUI

class ListController: ObservableObject {
    @Published var stateDidChange: Bool = false

    var lines: [ColumnLine] = []
    let list: ListFileBody
    let columnLineDragProcessor: ColumnLineDragProcessor
    let listColumnDragProcessor: ListColumnDragProcessor

    private var disposeBag: Set<AnyCancellable> = []
    init(list: ListFileBody) {
        self.list = list
        columnLineDragProcessor = ColumnLineDragProcessor()
        listColumnDragProcessor = ListColumnDragProcessor(list)
        updateListLines()
        list.stateDidChange
            .filter { $0 != .listText }
            .sink { _ in
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

class ListColumnDragProcessor {
    let list: ListFileBody
    var draggingColumn: ListColumn?

    init(_ list: ListFileBody) {
        self.list = list
    }

    func perform(destColumn: ListColumn) -> Bool {
        guard let srcColumn = draggingColumn else { return false }

        let fromIndex = list.columns.firstIndex { $0.uid == srcColumn.uid } ?? 0
        let toIndex = list.columns.firstIndex { $0.uid == destColumn.uid } ?? 0

        if fromIndex != toIndex {
            withAnimation {
                list.moveColumn(fromIndex: fromIndex, toIndex: toIndex)
                draggingColumn = nil
            }
            draggingColumn = nil
            return true
        } else {
            draggingColumn = nil
            return false
        }
    }
}

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
