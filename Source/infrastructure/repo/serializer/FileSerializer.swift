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

class FileSerializer: ISerializer {
    typealias Entity = File
    typealias FileDTO = FileDTO_v3

    let dispatcher: DomainEventDispatcher
    let encoder: JSONEncoder
    let decoder: JSONDecoder
    let textBodySerializer: TextFileBodySerializer
    let tableBodySerializer: TableFileBodySerializer
    let listBodySerializer: ListFileBodySerializer

    init(dispatcher: DomainEventDispatcher) {
        self.dispatcher = dispatcher
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        textBodySerializer = TextFileBodySerializer()
        tableBodySerializer = TableFileBodySerializer()
        listBodySerializer = ListFileBodySerializer()
    }

    func serialize(_ e: File) throws -> Data {
        var dto = FileDTO(uid: e.uid, title: e.title, useMonoFont: e.useMonoFont)

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
        let dto = try decoder.decode(FileDTO.self, from: data)
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
            return File(uid: dto.uid, title: dto.title, body: fileBody, useMonoFont: dto.useMonoFont, dispatcher: dispatcher)
        } else {
            throw FileSerializerError.fileBodyNotFoundAfterDeserialization(details: "File uid = \(dto.uid), title: = \(dto.title)")
        }
    }
}
