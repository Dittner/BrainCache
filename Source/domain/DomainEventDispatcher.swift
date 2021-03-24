//
//  PlaylistDomainEventDispatcher.swift
//  BrainCache
//
//  Created by Alexander Dittner on 11.02.2021.
//

import Combine
import SwiftUI

protocol EventDispatcher {
    associatedtype Event
    func notify(_ event: Event)
    var subject: PassthroughSubject<Event, Never> { get }
}

class DomainEventDispatcher: EventDispatcher {
    typealias DomainEvent = BrainCacheDomainEvent

    let subject = PassthroughSubject<DomainEvent, Never>()

    func notify(_ event: DomainEvent) {
        subject.send(event)
    }
}

enum BrainCacheDomainEvent {
    case entityStateChanged(entity: DomainEntity)
    case repoIsReady(repoID: RepoID)
    case repoStoreComplete(repoID: RepoID)
}
