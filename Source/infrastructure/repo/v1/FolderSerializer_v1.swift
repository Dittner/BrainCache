//
//  FolderSerializer_v1.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

struct FolderDTO_v1: Codable {
    var uid: UID
    var title: String
    var selectedFileUID: UID?
}

class FolderSerializer_v1: ISerializer {
    typealias Entity = Folder
    let dispatcher: DomainEventDispatcher
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init(dispatcher: DomainEventDispatcher) {
        self.dispatcher = dispatcher
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func serialize(_ e: Folder) throws -> Data {
        let dto = FolderDTO_v1(uid: e.uid, title: e.title, selectedFileUID: e.selectedFileUID)
        return try encoder.encode(dto)
    }

    func deserialize(data: Data) throws -> Folder {
        let dto = try decoder.decode(FolderDTO_v1.self, from: data)
        return Folder(uid: dto.uid, title: dto.title, dispatcher: dispatcher, selectedFileUID: dto.selectedFileUID)
    }
}
