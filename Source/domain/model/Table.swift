//
//  Table.swift
//  BrainCache
//
//  Created by Alexander Dittner on 24.03.2021.
//

import Combine
import SwiftUI

class TableFileBody: FileBody {
    var stateDidChange = CurrentValueSubject<Bool, Never>(false)

    private(set) var headers: [TableHeader]
    private(set) var rows: [TableRow]
    private(set) var sortType: SortType
    private(set) var sortByHeaderIndex: Int

    private var disposeBag: Set<AnyCancellable> = []
    init(headers: [TableHeader], rows: [TableRow], sortType: SortType = .ascending, sortByHeaderIndex: Int = 0) {
        self.headers = headers
        self.rows = rows
        self.sortType = sortType
        self.sortByHeaderIndex = sortByHeaderIndex
        
        sortRows()
    }

    func updateCell(_ cell: TableCell, with text: String) {
        cell.text = text
        stateDidChange.send(true)
    }

    func updateHeaderTitle(_ header: TableHeader, title: String) {
        header.title = title
        stateDidChange.send(true)
    }

    func updateHeaderRation(_ header: TableHeader, ration: CGFloat) {
        header.ratio = ration
        stateDidChange.send(true)
    }

    func updateSorting(headerIndex: Int, type: SortType) {
        sortByHeaderIndex = headerIndex
        sortType = type
        sortRows()
        stateDidChange.send(true)
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
