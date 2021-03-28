//
//  Table.swift
//  BrainCache
//
//  Created by Alexander Dittner on 24.03.2021.
//

import Combine
import SwiftUI

class ListFileBody: FileBody {
    var stateDidChange = PassthroughSubject<DomainEntityStateDidChangeEvent, Never>()

    private(set) var columns: [ListColumn]

    private var disposeBag: Set<AnyCancellable> = []
    init(columns: [ListColumn]) {
        self.columns = columns

        for c in columns {
            c.$title
                .removeDuplicates()
                .dropFirst()
                .sink { _ in
                    self.stateDidChange.send(.listTitle)
                }
                .store(in: &disposeBag)

            c.$text
                .removeDuplicates()
                .dropFirst()
                .sink { _ in
                    self.stateDidChange.send(.listText)
                }
                .store(in: &disposeBag)

            c.$ratio
                .removeDuplicates()
                .dropFirst()
                .sink { _ in
                    self.stateDidChange.send(.listRatio)
                }
                .store(in: &disposeBag)
        }
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

    func deleteColumn(at index: Int) {
        guard columns.count > 1 else { return }
        guard index < columns.count else { return }

        let deletingColumnRatio = columns[index].ratio
        columns.remove(at: index)
        columns.forEach { $0.ratio *= 1.0 / (1.0 - deletingColumnRatio) }
        stateDidChange.send(.listColumns)
    }
}

class ListColumn: ObservableObject {
    let uid: UID = UID()
    @Published var title: String
    @Published var text: String
    @Published var ratio: CGFloat // 0..1

    init(title: String, text: String, ratio: CGFloat) {
        self.title = title
        self.text = text
        self.ratio = ratio
    }
}
