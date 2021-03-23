//
//  FileSerializer_v1.swift
//  MP3Book
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

struct FileDTO_v1: Codable {
    var uid: UID
    var folderUID: UID
    var title: String
    var content: String
    var useMonoFont: Bool
}

class FileSerializer_v1: ISerializer {
    typealias Entity = File
    let dispatcher: DomainEventDispatcher
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init(dispatcher: DomainEventDispatcher) {
        self.dispatcher = dispatcher
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func serialize(_ e: File) throws -> Data {
        let dto = FileDTO_v1(uid: e.uid, folderUID: e.folderUID, title: e.title, content: e.content, useMonoFont: e.useMonoFont)
        return try encoder.encode(dto)
    }

    func deserialize(data: Data) throws -> File {
        let dto = try decoder.decode(FileDTO_v1.self, from: data)
        return File(uid: dto.uid, folderUID: dto.folderUID, title: dto.title, content: dto.content, useMonoFont: dto.useMonoFont, dispatcher: dispatcher)
    }
}
