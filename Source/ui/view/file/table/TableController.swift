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

class TableHeaderDragProcessor {
    let table:TableFileBody
    var draggingHeader:TableHeader?
    
    init(_ table:TableFileBody) {
        self.table = table
    }
    
    func perform(destHeader: TableHeader) -> Bool {
        guard let srcHeader = draggingHeader else { return false }

        let fromIndex = table.headers.firstIndex { $0.uid == srcHeader.uid } ?? 0
        let toIndex = table.headers.firstIndex { $0.uid == destHeader.uid } ?? 0

        if fromIndex != toIndex {
            withAnimation {
                table.moveColumn(fromIndex: fromIndex, toIndex: toIndex)
                draggingHeader = nil
            }
            draggingHeader = nil
            return true
        } else {
            draggingHeader = nil
            return false
        }
    }
}

struct DropViewDelegate: DropDelegate {
    let action: () -> Bool
    init(action: @escaping () -> Bool) {
        self.action = action
    }

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: ["public.plain-text"])
    }

    func performDrop(info: DropInfo) -> Bool {
        return action()
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
