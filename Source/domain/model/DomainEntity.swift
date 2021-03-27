//
//  DomainEntity.swift
//  BrainCache
//
//  Created by Alexander Dittner on 20.03.2021.
//

import Foundation
class DomainEntity {
    let uid: UID
    let dispatcher: DomainEventDispatcher
    init(uid: UID, dispatcher: DomainEventDispatcher) {
        self.uid = uid
        self.dispatcher = dispatcher
    }
}

extension DomainEntity: Identifiable {
    
}

extension DomainEntity: Equatable {
    static func == (lhs: DomainEntity, rhs: DomainEntity) -> Bool {
        lhs.uid == rhs.uid
    }
}

enum DomainEntityStateDidChangeEvent {
    case tableTitle
    case tableText
    case tableRatio
    case tableSorting
    case tableRows
    case tableColumns
    
    case textFileContent
    
    case listTitle
    case listText
    case listRatio
    case listColumns
}
