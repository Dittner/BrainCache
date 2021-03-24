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

    var headers: [TableHeader]
    var rows: [TableRow]
    var sortType: SortType
    var sortByHeaderIndex: Int

    private var disposeBag: Set<AnyCancellable> = []
    init(headers: [TableHeader], rows: [TableRow], sortType: SortType = .ascending, sortByHeaderIndex: Int = 0) {
        self.headers = headers
        self.rows = rows
        self.sortType = sortType
        self.sortByHeaderIndex = sortByHeaderIndex
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
        stateDidChange.send(true)
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
