//
//  TextFileSerializer_v1.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

class ListFileBodySerializer: ISerializer {
    typealias Entity = ListFileBody
    typealias ListFileColumnDTO = ListFileColumnDTO_v3
    typealias ListFileBodyDTO = ListFileBodyDTO_v3

    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func serialize(_ e: ListFileBody) throws -> Data {
        let columns = e.columns.map { ListFileColumnDTO(title: $0.title, text: $0.text, ratio: $0.ratio) }
        return try encoder.encode(ListFileBodyDTO(columns: columns))
    }

    func deserialize(data: Data) throws -> ListFileBody {
        let dto = try decoder.decode(ListFileBodyDTO.self, from: data)
        let columns = dto.columns.map { ListColumn(title: $0.title, text: $0.text, ratio: $0.ratio) }
        return ListFileBody(columns: columns)
    }
}
