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
    @Published private(set) var folderUID: UID
    let body: FileBody

    private var disposeBag: Set<AnyCancellable> = []
    init(uid: UID, folderUID: UID, title: String, body: FileBody, useMonoFont: Bool, dispatcher: DomainEventDispatcher) {
        self.folderUID = folderUID
        self.title = title
        self.body = body
        self.useMonoFont = useMonoFont
        super.init(uid: uid, dispatcher: dispatcher)

        body.stateDidChange
            .sink { _ in
                self.dispatcher.notify(.entityStateChanged(entity: self))
            }
            .store(in: &disposeBag)
    }

    func updateFolderUID(uid: UID) {
        if folderUID != uid {
            folderUID = uid
            dispatcher.notify(.entityStateChanged(entity: self))
            dispatcher.notify(.filesFolderChanged(file: self))
        }
    }

    func updateFont(useMonoFont: Bool) {
        if self.useMonoFont != useMonoFont {
            self.useMonoFont = useMonoFont
            dispatcher.notify(.entityStateChanged(entity: self))
        }
    }

    func updateTitle(title: String) {
        if self.title != title {
            self.title = title
            dispatcher.notify(.entityStateChanged(entity: self))
        }
    }
}
