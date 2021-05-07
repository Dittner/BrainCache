//
//  File.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Combine
import SwiftUI

class PendingPassthroughSubject<Output, Failure: Error>: Subject {
    init() {
        wrapped = .init()
    }

    func send(_ value: Output) {
        Async.after(milliseconds: 10) { [weak self] in
            self?.wrapped.send(value)
        }
    }

    func send(completion: Subscribers.Completion<Failure>) {
        Async.after(milliseconds: 10) { [weak self] in
            self?.wrapped.send(completion: completion)
        }
    }

    func send(subscription: Subscription) {
        Async.after(milliseconds: 10) { [weak self] in
            self?.wrapped.send(subscription: subscription)
        }
    }

    func receive<Downstream: Subscriber>(subscriber: Downstream) where Failure == Downstream.Failure, Output == Downstream.Input {
        wrapped.subscribe(subscriber)
    }

    private let wrapped: PassthroughSubject<Output, Failure>
}

protocol FileBody {
    var stateDidChange: PendingPassthroughSubject<DomainEntityStateDidChangeEvent, Never> { get }
}

class File: DomainEntity, ObservableObject {
    @Published private(set) var title: String
    @Published private(set) var useMonoFont: Bool
    let body: FileBody
    private(set) weak var parent: Folder?

    private var disposeBag: Set<AnyCancellable> = []
    init(uid: UID, title: String, body: FileBody, useMonoFont: Bool, dispatcher: DomainEventDispatcher) {
        self.title = title
        self.body = body
        self.useMonoFont = useMonoFont
        super.init(uid: uid, dispatcher: dispatcher)

        body.stateDidChange
            .sink { _ in
                self.notifyStateDidChange()
            }
            .store(in: &disposeBag)
    }

    func update(useMonoFont: Bool) {
        if self.useMonoFont != useMonoFont {
            self.useMonoFont = useMonoFont
            notifyStateDidChange()
        }
    }

    func update(title: String) {
        if self.title != title {
            self.title = title
            notifyStateDidChange()
        }
    }
    
    func update(parent: Folder?) {
        self.parent = parent
        notifyStateDidChange()
    }

    //
    // factory methods
    //

    static func createTextFile() -> File {
        return File(uid: UID(), title: "New File", body: TextFileBody(text: ""), useMonoFont: false, dispatcher: BrainCacheContext.shared.dispatcher)
    }

    static func createTableFile(columnCount: Int) -> File {
        var headers: [TableHeader] = []
        let row1: TableRow = TableRow(cells: [])
        let row2: TableRow = TableRow(cells: [])

        for i in 0 ... columnCount - 1 {
            headers.append(TableHeader(title: "Header \(i + 1)", ratio: 1.0 / CGFloat(columnCount)))
            row1.cells.append(TableCell(text: "R1_C\(i + 1)"))
            row2.cells.append(TableCell(text: "R2_C\(i + 1)"))
        }

        return File(uid: UID(), title: "New Table", body: TableFileBody(headers: headers, rows: [row1, row2]), useMonoFont: false, dispatcher: BrainCacheContext.shared.dispatcher)
    }

    static func createListFile(columnCount: Int) -> File {
        var columns: [ListColumn] = []
        for i in 0 ... columnCount - 1 {
            columns.append(ListColumn(title: "Column \(i + 1)", text: "", ratio: 1.0 / CGFloat(columnCount)))
        }

        return File(uid: UID(), title: "New List", body: ListFileBody(columns: columns), useMonoFont: false, dispatcher: BrainCacheContext.shared.dispatcher)
    }
}
