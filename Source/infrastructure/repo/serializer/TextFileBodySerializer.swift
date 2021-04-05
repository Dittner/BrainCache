//
//  TextFileBodySerializer_v1.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

class TextFileBodySerializer: ISerializer {
    typealias Entity = TextFileBody
    typealias TextFileBodyDTO = TextFileBodyDTO_v3
    
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func serialize(_ e: TextFileBody) throws -> Data {
        return try encoder.encode(TextFileBodyDTO(text: e.text))
    }

    func deserialize(data: Data) throws -> TextFileBody {
        let dto = try decoder.decode(TextFileBodyDTO.self, from: data)
        return TextFileBody(text: dto.text)
    }
}
