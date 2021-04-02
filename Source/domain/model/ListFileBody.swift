//
//  Table.swift
//  BrainCache
//
//  Created by Alexander Dittner on 24.03.2021.
//

import Combine
import SwiftUI

class ListFileBody: FileBody {
    var stateDidChange = PendingPassthroughSubject<DomainEntityStateDidChangeEvent, Never>()

    private(set) var columns: [ListColumn]

    init(columns: [ListColumn]) {
        self.columns = columns
    }

    func addNewColumn() {
        let ratioFactor = CGFloat(columns.count) / CGFloat(columns.count + 1)
        columns.forEach { $0.ratio *= ratioFactor }
        columns.append(ListColumn(title: "Column \(columns.count + 1)", text: "", ratio: 1 - ratioFactor))
        stateDidChange.send(.listColumns)
    }

    func moveColumn(fromIndex: Int, toIndex: Int) {
        guard fromIndex < columns.count && toIndex < columns.count && fromIndex != toIndex else { return }
        let srcColumn = columns.remove(at: fromIndex)
        columns.insert(srcColumn, at: toIndex)
        stateDidChange.send(.listColumns)
    }

    func updateColumn(_ c: ListColumn, ratio: CGFloat) {
        c.ratio = ratio
        stateDidChange.send(.listRatio)
    }

    func updateColumn(_ c: ListColumn, title: String) {
        c.title = title
        stateDidChange.send(.listTitle)
    }

    func updateColumn(_ c: ListColumn, text: String) {
        c.text = text
        stateDidChange.send(.listText)
    }

    func deleteColumn(at index: Int) {
        guard columns.count > 1 else { return }
        guard index < columns.count else { return }

        let deletingColumnRatio = columns[index].ratio
        columns.remove(at: index)
        columns.forEach { $0.ratio *= 1.0 / (1.0 - deletingColumnRatio) }
        stateDidChange.send(.listColumns)
    }
}

class ListColumn {
    let uid: UID = UID()
    fileprivate(set) var title: String
    fileprivate(set) var text: String
    fileprivate(set) var ratio: CGFloat // 0..1

    init(title: String, text: String, ratio: CGFloat) {
        self.title = title
        self.text = text
        self.ratio = ratio
    }
}
