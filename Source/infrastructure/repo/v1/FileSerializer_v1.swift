//
//  TextFileSerializer_v1.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

enum FileSerializerError: DetailedError {
    case fileBodyNotFoundAfterDeserialization(details: String)
    case fileBodyNotFoundBySerialization(details: String)
}

struct FileDTO_v1: Codable {
    var uid: UID
    var folderUID: UID
    var title: String
    var textBody: Data?
    var tableBody: Data?
    var listFileBody: Data?
    var useMonoFont: Bool
}

class FileSerializer_v1: ISerializer {
    typealias Entity = File
    let dispatcher: DomainEventDispatcher
    let encoder: JSONEncoder
    let decoder: JSONDecoder
    let textBodySerializer: TextFileBodySerializer_v1
    let tableBodySerializer: TableFileBodySerializer_v1
    let listBodySerializer: ListFileBodySerializer_v1

    init(dispatcher: DomainEventDispatcher) {
        self.dispatcher = dispatcher
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        textBodySerializer = TextFileBodySerializer_v1()
        tableBodySerializer = TableFileBodySerializer_v1()
        listBodySerializer = ListFileBodySerializer_v1()
    }

    func serialize(_ e: File) throws -> Data {
        var dto = FileDTO_v1(uid: e.uid, folderUID: e.folderUID, title: e.title, useMonoFont: e.useMonoFont)

        if let textFileBody = e.body as? TextFileBody {
            dto.textBody = try textBodySerializer.serialize(textFileBody)
            return try encoder.encode(dto)
        }

        if let tableFileBody = e.body as? TableFileBody {
            dto.tableBody = try tableBodySerializer.serialize(tableFileBody)
            return try encoder.encode(dto)
        }

        if let listFileBody = e.body as? ListFileBody {
            dto.listFileBody = try listBodySerializer.serialize(listFileBody)
            return try encoder.encode(dto)
        }

        throw FileSerializerError.fileBodyNotFoundBySerialization(details: "File uid = \(e.uid), title: = \(e.title)")
    }

    func deserialize(data: Data) throws -> File {
        let dto = try decoder.decode(FileDTO_v1.self, from: data)
        var fileBody: FileBody?

        if let textBodyData = dto.textBody {
            fileBody = try textBodySerializer.deserialize(data: textBodyData)
        }

        if let tableBodyData = dto.tableBody {
            fileBody = try tableBodySerializer.deserialize(data: tableBodyData)
        }

        if let listFileBody = dto.listFileBody {
            fileBody = try listBodySerializer.deserialize(data: listFileBody)
        }

        if let fileBody = fileBody {
            return File(uid: dto.uid, folderUID: dto.folderUID, title: dto.title, body: fileBody, useMonoFont: dto.useMonoFont, dispatcher: dispatcher)
        } else {
            throw FileSerializerError.fileBodyNotFoundAfterDeserialization(details: "File uid = \(dto.uid), title: = \(dto.title)")
        }
    }
}
