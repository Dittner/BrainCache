//
//  File.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Combine
import SwiftUI

protocol FileBody {}

class TextFileBody: FileBody, ObservableObject {
    @Published var text: String

    private var disposeBag: Set<AnyCancellable> = []
    init(text: String) {
        self.text = text
    }
}

class File: DomainEntity, ObservableObject {
    let folderUID: UID

    @Published var title: String
    @Published var useMonoFont: Bool
    let body: FileBody

    init(uid: UID, folderUID: UID, title: String, body: TextFileBody, useMonoFont: Bool, dispatcher: DomainEventDispatcher) {
        self.folderUID = folderUID
        self.title = title
        self.body = body
        self.useMonoFont = useMonoFont
        super.init(uid: uid, dispatcher: dispatcher)

        body.$text
            .removeDuplicates()
            .dropFirst()
            .sink { _ in
                self.dispatcher.notify(.entityStateChanged(entity: self))
            }
            .store(in: &disposeBag)

        notifyStateChanged()
    }

    init(uid: UID, folderUID: UID, title: String, body: TableFileBody, useMonoFont: Bool, dispatcher: DomainEventDispatcher) {
        self.folderUID = folderUID
        self.title = title
        self.body = body
        self.useMonoFont = useMonoFont
        super.init(uid: uid, dispatcher: dispatcher)

        body.stateDidChange
            .dropFirst()
            .sink { _ in
                self.dispatcher.notify(.entityStateChanged(entity: self))
            }
            .store(in: &disposeBag)

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

        $useMonoFont
            .removeDuplicates()
            .dropFirst()
            .sink { _ in
                self.dispatcher.notify(.entityStateChanged(entity: self))
            }
            .store(in: &disposeBag)
    }
}
