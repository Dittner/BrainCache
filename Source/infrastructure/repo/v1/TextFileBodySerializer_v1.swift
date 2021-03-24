//
//  TextFileBodySerializer_v1.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

struct TextFileBodyDTO_v1: Codable {
    var text: String
}

class TextFileBodySerializer_v1: ISerializer {
    typealias Entity = TextFileBody
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func serialize(_ e: TextFileBody) throws -> Data {
        return try encoder.encode(TextFileBodyDTO_v1(text: e.text))
    }

    func deserialize(data: Data) throws -> TextFileBody {
        let dto = try decoder.decode(TextFileBodyDTO_v1.self, from: data)
        return TextFileBody(text: dto.text)
    }
}
