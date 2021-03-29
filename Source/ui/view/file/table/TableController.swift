//
//  TableController.swift
//  BrainCache
//
//  Created by Alexander Dittner on 28.03.2021.
//

import Combine
import SwiftUI

class TableController: ObservableObject {
    @Published var lines: [TableLine] = []
    @Published var stateDidChange: Bool = false
    let table: TableFileBody
    let tableLineDragProcessor: TableLineDragProcessor
    let tableHeaderDragProcessor: TableHeaderDragProcessor

    private var disposeBag: Set<AnyCancellable> = []
    init(table: TableFileBody) {
        self.table = table
        tableLineDragProcessor = TableLineDragProcessor(table)
        tableHeaderDragProcessor = TableHeaderDragProcessor(table)
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
                let line = TableLine(position: total, leftColumn: table.headers[index], rightColumn: table.headers[index + 1])
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

class TableLine: ObservableObject, Identifiable {
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

class TableLineDragProcessor: ObservableObject {
    @Published var curDragOffset: CGFloat = 0
    @Published var curDragLine: TableLine? = nil
    private let minRation: CGFloat = 0.05
    let table: TableFileBody
    init(_ table: TableFileBody) {
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

class TableHeaderDragProcessor: ObservableObject {
    let table: TableFileBody
    @Published var draggingHeader: TableHeader?
    @Published var dropCandidate: TableHeader?

    init(_ table: TableFileBody) {
        self.table = table
    }

    func perform() -> Bool {
        guard let draggingHeader = draggingHeader else { return false }
        guard let dropCandidate = dropCandidate else { return false }

        let fromIndex = table.headers.firstIndex { $0.uid == draggingHeader.uid } ?? 0
        let toIndex = table.headers.firstIndex { $0.uid == dropCandidate.uid } ?? 0

        self.draggingHeader = nil
        self.dropCandidate = nil

        if fromIndex != toIndex {
            withAnimation {
                Async.after(milliseconds: 100) { [weak self] in
                    self?.table.moveColumn(fromIndex: fromIndex, toIndex: toIndex)
                }
            }
            return true
        } else {
            return false
        }
    }
}

struct TableHeaderDropViewDelegate: DropDelegate {
    let destHeader: TableHeader
    let dragProcessor: TableHeaderDragProcessor
    init(destHeader: TableHeader, dragProcessor: TableHeaderDragProcessor) {
        self.destHeader = destHeader
        self.dragProcessor = dragProcessor
    }

    func validateDrop(info: DropInfo) -> Bool {
        guard let srcHeader = dragProcessor.draggingHeader else { return false }
        return srcHeader.uid != destHeader.uid
    }

    func dropEntered(info: DropInfo) {
        dragProcessor.dropCandidate = destHeader
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
