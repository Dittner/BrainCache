//
//  Folder.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Combine

class File: DomainEntity, ObservableObject {
    let folderUID: UID
    @Published var title: String
    @Published var content: String
    @Published var useMonoFont: Bool

    init(uid: UID, folderUID: UID, title: String, content: String, useMonoFont: Bool, dispatcher: DomainEventDispatcher) {
        self.folderUID = folderUID
        self.title = title
        self.content = content
        self.useMonoFont = useMonoFont
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

        $content
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
