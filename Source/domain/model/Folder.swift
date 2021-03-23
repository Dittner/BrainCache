//
//  Folder.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Combine

class Folder: DomainEntity, ObservableObject {
    @Published var title: String
    @Published var selectedFileUID: UID?
    @Published var search: String = ""

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
            .sink { value in
                self.dispatcher.notify(.entityStateChanged(entity: self))
            }
            .store(in: &disposeBag)
        
        $selectedFileUID
            .removeDuplicates()
            .dropFirst()
            .sink { value in
                self.dispatcher.notify(.entityStateChanged(entity: self))
            }
            .store(in: &disposeBag)
    }
}
