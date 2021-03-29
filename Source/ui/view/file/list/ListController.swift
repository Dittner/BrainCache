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

class ListColumnDragProcessor: ObservableObject {
    let list: ListFileBody

    @Published var draggingColumn: ListColumn?
    @Published var dropCandidate: ListColumn?

    init(_ list: ListFileBody) {
        self.list = list
    }

    func perform() -> Bool {
        guard let draggingColumn = draggingColumn else { return false }
        guard let dropCandidate = dropCandidate else { return false }

        let fromIndex = list.columns.firstIndex { $0.uid == draggingColumn.uid } ?? 0
        let toIndex = list.columns.firstIndex { $0.uid == dropCandidate.uid } ?? 0

        self.draggingColumn = nil
        self.dropCandidate = nil

        if fromIndex != toIndex {
            withAnimation {
                Async.after(milliseconds: 100) { [weak self] in
                    self?.list.moveColumn(fromIndex: fromIndex, toIndex: toIndex)
                }
            }
            return true
        } else {
            return false
        }
    }
}

struct ListColumnDropViewDelegate: DropDelegate {
    let destColumn: ListColumn
    let dragProcessor: ListColumnDragProcessor
    init(destColumn: ListColumn, dragProcessor: ListColumnDragProcessor) {
        self.destColumn = destColumn
        self.dragProcessor = dragProcessor
    }

    func validateDrop(info: DropInfo) -> Bool {
        guard let draggingColumn = dragProcessor.draggingColumn else { return false }
        return draggingColumn.uid != destColumn.uid
    }

    func dropEntered(info: DropInfo) {
        dragProcessor.dropCandidate = destColumn
    }

    func dropExited(info: DropInfo) {
        dragProcessor.dropCandidate = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        return dragProcessor.perform()
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
