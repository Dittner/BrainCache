//
//  Table.swift
//  BrainCache
//
//  Created by Alexander Dittner on 24.03.2021.
//

import Combine
import SwiftUI

class TableFileBody: FileBody, ObservableObject {
    var stateDidChange = PendingPassthroughSubject<DomainEntityStateDidChangeEvent, Never>()

    private(set) var headers: [TableHeader]
    private(set) var rows: [TableRow]
    private(set) var sortType: SortType
    private(set) var sortByHeaderIndex: Int

    init(headers: [TableHeader], rows: [TableRow], sortType: SortType = .ascending, sortByHeaderIndex: Int = 0) {
        self.headers = headers
        self.rows = rows
        self.sortType = sortType
        self.sortByHeaderIndex = sortByHeaderIndex

        sortRows()
    }

    func updateCell(_ cell: TableCell, with text: String) {
        cell.text = text
        stateDidChange.send(.tableText)
    }

    func updateHeaderTitle(_ header: TableHeader, title: String) {
        header.title = title
        stateDidChange.send(.tableTitle)
    }

    func updateHeaderRation(_ header: TableHeader, ration: CGFloat) {
        header.ratio = ration
        stateDidChange.send(.tableRatio)
    }

    func updateSorting(headerIndex: Int, type: SortType) {
        sortByHeaderIndex = headerIndex
        sortType = type
        sortRows()
        stateDidChange.send(.tableSorting)
    }

    private func sortRows() {
        if sortType == .ascending {
            rows = rows.sorted(by: { $0.cells[sortByHeaderIndex].text < $1.cells[sortByHeaderIndex].text })
        } else {
            rows = rows.sorted(by: { $0.cells[sortByHeaderIndex].text > $1.cells[sortByHeaderIndex].text })
        }
    }

    func addNewRow() {
        let row = TableRow(cells: [])
        for _ in 0 ... headers.count - 1 {
            row.cells.append(TableCell(text: ""))
        }
        rows.append(row)
        stateDidChange.send(.tableRows)
    }

    func addNewColumn() {
        let ratioFactor = CGFloat(headers.count) / CGFloat(headers.count + 1)
        headers.forEach { $0.ratio *= ratioFactor }
        headers.append(TableHeader(title: "Header \(headers.count + 1)", ratio: 1 - ratioFactor))
        rows.forEach { $0.cells.append(TableCell(text: "")) }
        stateDidChange.send(.tableColumns)
    }

    func moveColumn(fromIndex: Int, toIndex: Int) {
        guard fromIndex < headers.count && toIndex < headers.count && fromIndex != toIndex else { return }
        let srcHeader = headers.remove(at: fromIndex)
        headers.insert(srcHeader, at: toIndex)

        for row in rows {
            let srcCell = row.cells.remove(at: fromIndex)
            row.cells.insert(srcCell, at: toIndex)
        }
        
        if sortByHeaderIndex == toIndex {
            sortByHeaderIndex = fromIndex
        } else if sortByHeaderIndex == fromIndex {
            sortByHeaderIndex = toIndex
        }
        stateDidChange.send(.tableColumns)
    }

    func deleteColumn(at index: Int) {
        guard headers.count > 1 else { return }
        guard index < headers.count else { return }

        if sortByHeaderIndex == index {
            sortByHeaderIndex -= 1
        }

        let deletingColumnRatio = headers[index].ratio
        headers.remove(at: index)
        headers.forEach { $0.ratio *= 1.0 / (1.0 - deletingColumnRatio) }
        rows.forEach { $0.cells.remove(at: index) }
        stateDidChange.send(.tableColumns)
    }
}

enum SortType: String, Codable {
    case ascending
    case descending
}

class TableHeader {
    let uid: UID = UID()
    fileprivate(set) var title: String
    fileprivate(set) var ratio: CGFloat // 0..1

    init(title: String, ratio: CGFloat) {
        self.title = title
        self.ratio = ratio
    }
}

class TableCell {
    let uid: UID = UID()
    fileprivate(set) var text: String
    init(text: String) {
        self.text = text
    }
}

class TableRow {
    let uid: UID = UID()
    var cells: [TableCell]

    init(cells: [TableCell]) {
        self.cells = cells
    }
}
