//
//  IBookRepository.swift
//  BrainCache
//
//  Created by Alexander Dittner on 11.02.2021.
//

import Combine
import Foundation

protocol IRepository {
    associatedtype Entity
    var subject: CurrentValueSubject<[Entity], Never> { get }
    func has(_ uid: UID) -> Bool
    func read(_ uid: UID) -> Entity?
    func write(_ e: Entity) throws
    func remove(_ uid: UID)
}

protocol ISerializer {
    associatedtype Entity
    func serialize(_ e: Entity) throws -> Data
    func deserialize(data: Data) throws -> Entity
}
