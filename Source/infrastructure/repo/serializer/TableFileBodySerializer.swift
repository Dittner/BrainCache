//
//  TextFileSerializer_v1.swift
//  BrainCache
//
//  Created by Alexander Dittner on 12.02.2021.
//

import Foundation

class TableFileBodySerializer: ISerializer {
    typealias Entity = TableFileBody
    typealias TableHeaderDTO = TableHeaderDTO_v3
    typealias TableFileBodyDTO = TableFileBodyDTO_v3

    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    func serialize(_ e: TableFileBody) throws -> Data {
        let headers = e.headers.map { TableHeaderDTO(title: $0.title,
                                                ratio: $0.ratio) }

        return try encoder.encode(TableFileBodyDTO(headers: headers,
                                              rows: e.rows.filter { $0.cells.reduce(0, { $0 + $1.text.count }) > 0 }.map { $0.cells.map { $0.text } },
                                              sortType: e.sortType,
                                              sortByHeaderIndex: e.sortByHeaderIndex))
    }

    func deserialize(data: Data) throws -> TableFileBody {
        let dto = try decoder.decode(TableFileBodyDTO.self, from: data)

        let headers = dto.headers.map { TableHeader(title: $0.title, ratio: $0.ratio) }
        let tableRows = dto.rows.map { TableRow(cells: $0.map { TableCell(text: $0) }) }

        return TableFileBody(headers: headers,
                             rows: tableRows,
                             sortType: dto.sortType,
                             sortByHeaderIndex: dto.sortByHeaderIndex)
    }
}
