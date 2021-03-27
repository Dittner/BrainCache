//
//  Folder.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Combine
import SwiftUI

class Folder: DomainEntity, ObservableObject {
    @Published var title: String
    @Published var selectedFileUID: UID?
    @Published var search: String = ""
    let searchUID: UID = UID()

    init(uid: UID, title: String, dispatcher: DomainEventDispatcher, selectedFileUID: UID? = nil) {
        self.title = title
        self.selectedFileUID = selectedFileUID
        super.init(uid: uid, dispatcher: dispatcher)

        notifyStateChanged()
    }

    private var disposeBag: Set<AnyCancellable> = []
    private func notifyStateChanged() {
        $title
            .removeDuplicates()
            .dropFirst()
            .sink { _ in
                self.dispatcher.notify(.entityStateChanged(entity: self))
            }
            .store(in: &disposeBag)

        $selectedFileUID
            .removeDuplicates()
            .dropFirst()
            .sink { _ in
                self.dispatcher.notify(.entityStateChanged(entity: self))
            }
            .store(in: &disposeBag)
    }

    func createTextFile() -> File {
        File(uid: UID(), folderUID: uid, title: "New File", body: TextFileBody(text: ""), useMonoFont: false, dispatcher: dispatcher)
    }

    func createTableFile(columnCount: Int) -> File {
        var headers: [TableHeader] = []
        let row1: TableRow = TableRow(cells: [])
        let row2: TableRow = TableRow(cells: [])

        for i in 0 ... columnCount - 1 {
            headers.append(TableHeader(title: "Header \(i + 1)", ratio: 1.0 / CGFloat(columnCount)))
            row1.cells.append(TableCell(text: "R1_C\(i + 1)"))
            row2.cells.append(TableCell(text: "R2_C\(i + 1)"))
        }

        return File(uid: UID(), folderUID: uid, title: "New Table", body: TableFileBody(headers: headers, rows: [row1, row2]), useMonoFont: false, dispatcher: dispatcher)
    }

    func createListFile(columnCount: Int) -> File {
        var columns: [ListColumn] = []
        for i in 0 ... columnCount - 1 {
            columns.append(ListColumn(title: "Column \(i + 1)", text: "", ratio: 1.0 / CGFloat(columnCount)))
        }

        return File(uid: UID(), folderUID: uid, title: "New List", body: ListFileBody(columns: columns), useMonoFont: false, dispatcher: dispatcher)
    }
}
