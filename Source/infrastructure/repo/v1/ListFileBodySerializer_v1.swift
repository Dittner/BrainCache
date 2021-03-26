//
//  TextFileSerializer_v1.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

struct ListFileBodyDTO_v1: Codable {
    var columns: [ListFileColumnDTO_v1]
}

struct ListFileColumnDTO_v1: Codable {
    var text: String
    var ratio: CGFloat
}

class ListFileBodySerializer_v1: ISerializer {
    typealias Entity = ListFileBody
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func serialize(_ e: ListFileBody) throws -> Data {
        let columns = e.columns.map { ListFileColumnDTO_v1(text: $0.text, ratio: $0.ratio) }
        return try encoder.encode(ListFileBodyDTO_v1(columns: columns))
    }

    func deserialize(data: Data) throws -> ListFileBody {
        let dto = try decoder.decode(ListFileBodyDTO_v1.self, from: data)
        let columns = dto.columns.map { ListColumn(text: $0.text, ratio: $0.ratio) }
        return ListFileBody(columns: columns)
    }
}
